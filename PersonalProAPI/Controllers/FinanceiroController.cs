using Dapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PersonalProAPI.Data;
using PersonalProAPI.Helpers;
using PersonalProAPI.Services;

namespace PersonalProAPI.Controllers
{
    [ApiController]
    [Route("api/financeiro")]
    [Authorize(Roles = "Personal,SuperAdmin")]
    public class FinanceiroController : ControllerBase
    {
        private readonly DbConnection _db;
        private readonly NotificacaoService _notificacao;

        public FinanceiroController(DbConnection db, NotificacaoService notificacao)
        {
            _db = db;
            _notificacao = notificacao;
        }

        [HttpGet("pagamentos")]
        public async Task<IActionResult> ListarPagamentos([FromQuery] string? mes = null, [FromQuery] string? status = null)
        {
            var personalId = UsuarioContexto.GetPersonalId(User);
            var mesRef = string.IsNullOrWhiteSpace(mes) ? DateTime.Now.ToString("yyyy-MM") : mes;

            using var con = _db.CriarConexao();
            var personal = await con.QueryFirstOrDefaultAsync<dynamic>(
                "SELECT NOME_PROFISSIONAL AS Nome, CHAVE_PIX AS ChavePix FROM PERSONAIS WHERE ID = @Id",
                new { Id = personalId }
            );

            var sql = @"
                SELECT
                    P.ID AS Id,
                    P.ALUNO_ID AS AlunoId,
                    U.NOME AS NomeAluno,
                    A.TELEFONE AS TelefoneAluno,
                    P.MES_REFERENCIA AS MesReferencia,
                    P.VALOR AS Valor,
                    P.DATA_VENCIMENTO AS DataVencimento,
                    P.DATA_PAGAMENTO AS DataPagamento,
                    P.FORMA_PAGAMENTO AS FormaPagamento,
                    P.STATUS AS Status,
                    P.OBSERVACAO AS Observacao,
                    P.PIX_COPIA_E_COLA AS PixCopiaECola
                FROM PAGAMENTOS P
                INNER JOIN ALUNOS A ON A.ID = P.ALUNO_ID
                INNER JOIN USUARIOS U ON U.ID = A.USUARIO_ID
                WHERE P.PERSONAL_ID = @PersonalId
                  AND P.MES_REFERENCIA = @MesRef";

            if (!string.IsNullOrWhiteSpace(status) && status != "TODOS")
            {
                sql += " AND P.STATUS = @Status";
            }

            sql += " ORDER BY CASE WHEN P.STATUS = 'PENDENTE' THEN 0 ELSE 1 END, P.DATA_VENCIMENTO ASC";

            var pagamentos = (await con.QueryAsync<dynamic>(sql, new
            {
                PersonalId = personalId,
                MesRef = mesRef,
                Status = status
            })).ToList();

            var totalRecebido = pagamentos.Where(x => (string)x.Status == "PAGO").Sum(x => (decimal)x.Valor);
            var totalPendente = pagamentos.Where(x => (string)x.Status != "PAGO").Sum(x => (decimal)x.Valor);

            return Ok(new
            {
                mesReferencia = mesRef,
                chavePixPersonal = (string?)(personal?.ChavePix ?? ""),
                nomePersonal = (string?)(personal?.Nome ?? "PersonalPro"),
                resumo = new
                {
                    totalRecebido,
                    totalPendente,
                    totalPrevisto = totalRecebido + totalPendente,
                    quantidadePagos = pagamentos.Count(x => (string)x.Status == "PAGO"),
                    quantidadePendentes = pagamentos.Count(x => (string)x.Status != "PAGO")
                },
                pagamentos
            });
        }

        [HttpPost("pagamentos")]
        public async Task<IActionResult> CriarCobranca([FromBody] NovaCobrancaDto dto)
        {
            var personalId = UsuarioContexto.GetPersonalId(User);
            using var con = _db.CriarConexao();

            var personal = await con.QueryFirstOrDefaultAsync<dynamic>(
                "SELECT NOME_PROFISSIONAL AS Nome, CHAVE_PIX AS ChavePix FROM PERSONAIS WHERE ID = @Id",
                new { Id = personalId }
            );

            string chavePix = personal?.ChavePix ?? "personal@personalpro.com";
            string nomeBeneficiario = personal?.Nome ?? "PERSONALPRO";
            var mesRef = string.IsNullOrWhiteSpace(dto.MesReferencia) ? DateTime.Now.ToString("yyyy-MM") : dto.MesReferencia;

            var pixPayload = PixPayloadService.GerarPayload(
                chavePix,
                nomeBeneficiario,
                "SAO PAULO",
                dto.Valor,
                $"PPRO{dto.AlunoId}{DateTime.Now:MMdd}"
            );

            var dataVenc = string.IsNullOrWhiteSpace(dto.DataVencimento)
                ? DateTime.Today.AddDays(5)
                : DateTime.Parse(dto.DataVencimento);

            var id = await con.ExecuteScalarAsync<int>(@"
                INSERT INTO PAGAMENTOS (
                    ALUNO_ID, PERSONAL_ID, MES_REFERENCIA, VALOR, DATA_VENCIMENTO,
                    STATUS, OBSERVACAO, PIX_COPIA_E_COLA
                )
                VALUES (
                    @AlunoId, @PersonalId, @MesReferencia, @Valor, @DataVencimento,
                    'PENDENTE', @Observacao, @PixCopiaECola
                );
                SELECT CAST(SCOPE_IDENTITY() AS INT);",
                new
                {
                    dto.AlunoId,
                    PersonalId = personalId,
                    MesReferencia = mesRef,
                    dto.Valor,
                    DataVencimento = dataVenc,
                    Observacao = string.IsNullOrWhiteSpace(dto.Observacao) ? $"Mensalidade Consultoria — {mesRef}" : dto.Observacao,
                    PixCopiaECola = pixPayload
                }
            );

            return Ok(new { mensagem = "Cobrança PIX gerada com sucesso!", id, pixCopiaECola = pixPayload });
        }

        [HttpPost("gerar-mensalidades-mes")]
        public async Task<IActionResult> GerarMensalidadesDoMes()
        {
            var personalId = UsuarioContexto.GetPersonalId(User);
            var mesAtual = DateTime.Now.ToString("yyyy-MM");

            using var con = _db.CriarConexao();
            var personal = await con.QueryFirstOrDefaultAsync<dynamic>(
                "SELECT NOME_PROFISSIONAL AS Nome, CHAVE_PIX AS ChavePix FROM PERSONAIS WHERE ID = @Id",
                new { Id = personalId }
            );

            var alunosAtivos = (await con.QueryAsync<dynamic>(@"
                SELECT A.ID AS AlunoId, A.VALOR_MENSALIDADE AS Valor, A.DIA_VENCIMENTO AS DiaVencimento
                FROM ALUNOS A
                INNER JOIN USUARIOS U ON U.ID = A.USUARIO_ID
                WHERE A.PERSONAL_ID = @PersonalId AND U.STATUS = 1",
                new { PersonalId = personalId }
            )).ToList();

            int geradas = 0;
            foreach (var a in alunosAtivos)
            {
                int alunoId = (int)a.AlunoId;
                var jaExiste = await con.ExecuteScalarAsync<int>(
                    "SELECT COUNT(1) FROM PAGAMENTOS WHERE ALUNO_ID = @AlunoId AND MES_REFERENCIA = @MesAtual",
                    new { AlunoId = alunoId, MesAtual = mesAtual }
                );

                if (jaExiste == 0)
                {
                    decimal valor = (decimal)a.Valor;
                    int dia = Math.Clamp((int)a.DiaVencimento, 1, 28);
                    var venc = new DateTime(DateTime.Now.Year, DateTime.Now.Month, dia);
                    var pix = PixPayloadService.GerarPayload(
                        (string?)(personal?.ChavePix ?? "personal@personalpro.com")!,
                        (string?)(personal?.Nome ?? "PERSONALPRO")!,
                        "SAO PAULO",
                        valor,
                        $"PPRO{alunoId}{DateTime.Now:MM}"
                    );

                    await con.ExecuteAsync(@"
                        INSERT INTO PAGAMENTOS (ALUNO_ID, PERSONAL_ID, MES_REFERENCIA, VALOR, DATA_VENCIMENTO, STATUS, OBSERVACAO, PIX_COPIA_E_COLA)
                        VALUES (@AlunoId, @PersonalId, @Mes, @Valor, @Venc, 'PENDENTE', @Obs, @Pix)",
                        new
                        {
                            AlunoId = alunoId,
                            PersonalId = personalId,
                            Mes = mesAtual,
                            Valor = valor,
                            Venc = venc,
                            Obs = $"Mensalidade Consultoria — {mesAtual}",
                            Pix = pix
                        }
                    );
                    geradas++;
                }
            }

            return Ok(new { mensagem = $"{geradas} cobrança(s) gerada(s) para o mês {mesAtual} com código PIX!" });
        }

        [HttpPost("pagamentos/{id}/confirmar")]
        public async Task<IActionResult> ConfirmarPagamento(int id, [FromBody] ConfirmarPagamentoDto dto)
        {
            var personalId = UsuarioContexto.GetPersonalId(User);
            using var con = _db.CriarConexao();

            var pag = await con.QueryFirstOrDefaultAsync<dynamic>(@"
                SELECT P.ID, P.ALUNO_ID AS AlunoId, P.VALOR AS Valor, P.MES_REFERENCIA AS MesReferencia, A.USUARIO_ID AS UsuarioAlunoId
                FROM PAGAMENTOS P
                INNER JOIN ALUNOS A ON A.ID = P.ALUNO_ID
                WHERE P.ID = @Id AND P.PERSONAL_ID = @PersonalId",
                new { Id = id, PersonalId = personalId }
            );

            if (pag == null) return NotFound(new { mensagem = "Pagamento não encontrado." });

            var forma = string.IsNullOrWhiteSpace(dto.FormaPagamento) ? "PIX" : dto.FormaPagamento;

            await con.ExecuteAsync(@"
                UPDATE PAGAMENTOS
                SET STATUS = 'PAGO',
                    DATA_PAGAMENTO = CAST(GETDATE() AS DATE),
                    FORMA_PAGAMENTO = @Forma
                WHERE ID = @Id AND PERSONAL_ID = @PersonalId",
                new { Id = id, PersonalId = personalId, Forma = forma }
            );

            await _notificacao.EnviarNotificacaoAsync(
                personalId,
                (int)pag.UsuarioAlunoId,
                "✅ Pagamento Confirmado!",
                $"Seu Personal confirmou o recebimento da sua mensalidade ({pag.MesReferencia}) no valor de R$ {((decimal)pag.Valor):F2} via {forma}. Obrigado!",
                "FINANCEIRO"
            );

            return Ok(new { mensagem = "Pagamento confirmado e recibo liberado!" });
        }

        public class NovaCobrancaDto
        {
            public int AlunoId { get; set; }
            public decimal Valor { get; set; }
            public string? MesReferencia { get; set; }
            public string? DataVencimento { get; set; }
            public string? Observacao { get; set; }
        }

        public class ConfirmarPagamentoDto
        {
            public string FormaPagamento { get; set; } = "PIX";
        }
    }
}

