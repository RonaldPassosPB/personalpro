using Dapper;
using PersonalProAPI.Data;

namespace PersonalProAPI.Services
{
    public class PagamentoBackgroundService : BackgroundService
    {
        private readonly IServiceProvider _services;
        private readonly ILogger<PagamentoBackgroundService> _logger;

        public PagamentoBackgroundService(IServiceProvider services, ILogger<PagamentoBackgroundService> logger)
        {
            _services = services;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            // Aguarda 8 segundos após inicialização da API
            await Task.Delay(TimeSpan.FromSeconds(8), stoppingToken);

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    await ProcessarRotinaFinanceiraAsync();
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "[PagamentoBackgroundService] Erro ao processar rotina automática de mensalidades.");
                }

                // Executa a cada 6 horas
                await Task.Delay(TimeSpan.FromHours(6), stoppingToken);
            }
        }

        private async Task ProcessarRotinaFinanceiraAsync()
        {
            using var scope = _services.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<DbConnection>();
            var notificacao = scope.ServiceProvider.GetRequiredService<NotificacaoService>();

            using var con = db.CriarConexao();
            var mesAtual = DateTime.Now.ToString("yyyy-MM");

            // 1. Atualiza cobranças PENDENTES vencidas para ATRASADO
            var vencidas = (await con.QueryAsync<dynamic>(@"
                SELECT
                    P.ID AS Id,
                    P.ALUNO_ID AS AlunoId,
                    P.PERSONAL_ID AS PersonalId,
                    P.VALOR AS Valor,
                    P.MES_REFERENCIA AS MesReferencia,
                    A.USUARIO_ID AS UsuarioAlunoId,
                    U.NOME AS NomeAluno
                FROM PAGAMENTOS P
                INNER JOIN ALUNOS A ON A.ID = P.ALUNO_ID
                INNER JOIN USUARIOS U ON U.ID = A.USUARIO_ID
                WHERE P.STATUS = 'PENDENTE'
                  AND P.DATA_VENCIMENTO < CAST(GETDATE() AS DATE)")).ToList();

            foreach (var v in vencidas)
            {
                await con.ExecuteAsync(
                    "UPDATE PAGAMENTOS SET STATUS = 'ATRASADO' WHERE ID = @Id",
                    new { Id = (int)v.Id }
                );

                await notificacao.EnviarNotificacaoAsync(
                    (int)v.PersonalId,
                    (int)v.UsuarioAlunoId,
                    "⚠️ Mensalidade em Atraso",
                    $"Olá, {v.NomeAluno}! Sua mensalidade ({v.MesReferencia}) no valor de R$ {((decimal)v.Valor):F2} encontra-se vencida. Acesse a aba Financeiro para pagar com PIX.",
                    "FINANCEIRO"
                );
            }

            // 2. Gera automaticamente cobranças do mês atual para alunos ativos que ainda não possuem cobrança no mês
            var alunosSemCobranca = (await con.QueryAsync<dynamic>(@"
                SELECT
                    A.ID AS AlunoId,
                    A.PERSONAL_ID AS PersonalId,
                    A.VALOR_MENSALIDADE AS Valor,
                    A.DIA_VENCIMENTO AS DiaVencimento,
                    P.NOME_PROFISSIONAL AS NomePersonal,
                    P.CHAVE_PIX AS ChavePix
                FROM ALUNOS A
                INNER JOIN USUARIOS U ON U.ID = A.USUARIO_ID
                INNER JOIN PERSONAIS P ON P.ID = A.PERSONAL_ID
                WHERE U.STATUS = 1
                  AND P.STATUS = 1
                  AND NOT EXISTS (
                      SELECT 1 FROM PAGAMENTOS PG
                      WHERE PG.ALUNO_ID = A.ID AND PG.MES_REFERENCIA = @MesAtual
                  )",
                new { MesAtual = mesAtual }
            )).ToList();

            foreach (var a in alunosSemCobranca)
            {
                int alunoId = (int)a.AlunoId;
                int personalId = (int)a.PersonalId;
                decimal valor = (decimal)a.Valor;
                int dia = Math.Clamp((int)a.DiaVencimento, 1, 28);
                var dataVenc = new DateTime(DateTime.Now.Year, DateTime.Now.Month, dia);
                var statusInicial = dataVenc < DateTime.Today ? "ATRASADO" : "PENDENTE";

                var pix = PixPayloadService.GerarPayload(
                    (string?)(a.ChavePix ?? "personal@personalpro.com")!,
                    (string?)(a.NomePersonal ?? "PERSONALPRO")!,
                    "SAO PAULO",
                    valor,
                    $"PPRO{alunoId}{DateTime.Now:MM}"
                );

                await con.ExecuteAsync(@"
                    INSERT INTO PAGAMENTOS (
                        ALUNO_ID, PERSONAL_ID, MES_REFERENCIA, VALOR,
                        DATA_VENCIMENTO, STATUS, OBSERVACAO, PIX_COPIA_E_COLA
                    )
                    VALUES (
                        @AlunoId, @PersonalId, @MesAtual, @Valor,
                        @DataVenc, @Status, @Obs, @Pix
                    )",
                    new
                    {
                        AlunoId = alunoId,
                        PersonalId = personalId,
                        MesAtual = mesAtual,
                        Valor = valor,
                        DataVenc = dataVenc,
                        Status = statusInicial,
                        Obs = $"Mensalidade Consultoria — {mesAtual} (Gerada automaticamente)",
                        Pix = pix
                    }
                );
            }

            // 3. Verifica assinaturas dos Personais Trainers no Coach Center SaaS (Tolerância de 5 dias e Auto-Bloqueio)
            var personais = (await con.QueryAsync<dynamic>(@"
                SELECT 
                    P.ID AS Id,
                    P.NOME_PROFISSIONAL AS NomeProfissional,
                    P.DIA_VENCIMENTO AS DiaVencimento,
                    P.ULTIMO_PAGAMENTO_MES AS UltimoPagamentoMes,
                    P.STATUS AS Status,
                    U.ID AS UsuarioPersonalId
                FROM PERSONAIS P
                INNER JOIN USUARIOS U ON U.PERSONAL_ID = P.ID AND U.PERFIL = 1
                WHERE P.STATUS = 1")).ToList();

            int hojeDia = DateTime.Now.Day;
            foreach (var p in personais)
            {
                int personalId = (int)p.Id;
                int usuarioPersonalId = (int)p.UsuarioPersonalId;
                int diaVenc = p.DiaVencimento != null ? Convert.ToInt32(p.DiaVencimento) : 10;
                string? ultimoPagto = (string?)p.UltimoPagamentoMes;
                bool pagoNoMes = (ultimoPagto == mesAtual);

                if (!pagoNoMes && hojeDia >= diaVenc)
                {
                    int diasAtraso = hojeDia - diaVenc;
                    if (diasAtraso > 5)
                    {
                        // Mais de 5 dias de atraso: Bloqueia o Personal
                        await con.ExecuteAsync("UPDATE PERSONAIS SET STATUS = 0 WHERE ID = @Id", new { Id = personalId });
                        string nomeProf = (string)p.NomeProfissional;
                        _logger.LogWarning("[PagamentoBackgroundService] Personal {Id} ({Nome}) BLOQUEADO por atraso de {Dias} dias no SaaS.", personalId, nomeProf, diasAtraso);

                        await notificacao.EnviarNotificacaoAsync(
                            personalId,
                            usuarioPersonalId,
                            "🚫 Assinatura SaaS Bloqueada por Inadimplência",
                            $"Sua assinatura no Coach Center SaaS ultrapassou os 5 dias de tolerância ({diasAtraso} dias de atraso). Seu acesso e o app dos seus alunos foram suspensos. Entre em contato com o suporte para regularizar.",
                            "SAAS_BLOQUEIO"
                        );
                    }
                    else
                    {
                        // Dentro do prazo de 5 dias de tolerância: Alerta diário de tolerância
                        int diasRestantes = 5 - diasAtraso;
                        await notificacao.EnviarNotificacaoAsync(
                            personalId,
                            usuarioPersonalId,
                            "⚠️ Aviso de Vencimento da Assinatura SaaS",
                            $"Sua mensalidade do Coach Center SaaS venceu no dia {diaVenc:D2}. Você possui mais {diasRestantes} dia(s) de tolerância antes do bloqueio da sua conta. Efetue o pagamento com a administração.",
                            "SAAS_AVISO"
                        );
                    }
                }
            }

            if (vencidas.Count > 0 || alunosSemCobranca.Count > 0)
            {
                _logger.LogInformation(
                    "[PagamentoBackgroundService] Rotina concluída: {Vencidas} marcada(s) como ATRASADO | {Geradas} cobrança(s) gerada(s) para {Mes}.",
                    vencidas.Count,
                    alunosSemCobranca.Count,
                    mesAtual
                );
            }
        }
    }
}
