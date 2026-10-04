using Dapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PersonalProAPI.Data;
using PersonalProAPI.Helpers;
using PersonalProAPI.Services;

namespace PersonalProAPI.Controllers
{
    [ApiController]
    [Route("api/personal")]
    [Authorize(Roles = "Personal,SuperAdmin")]
    public class PersonalController : ControllerBase
    {
        private readonly DbConnection _db;
        private readonly NotificacaoService _notificacao;

        public PersonalController(DbConnection db, NotificacaoService notificacao)
        {
            _db = db;
            _notificacao = notificacao;
        }

        [HttpGet("dashboard")]
        public async Task<IActionResult> GetDashboard()
        {
            var personalId = UsuarioContexto.GetPersonalId(User);
            if (personalId <= 0) return Forbid();

            using var con = _db.CriarConexao();
            var mesAtual = DateTime.Now.ToString("yyyy-MM");

            var personal = await con.QueryFirstOrDefaultAsync<dynamic>(@"
                SELECT 
                    ID AS Id, 
                    NOME_PROFISSIONAL AS NomeProfissional, 
                    CREF AS Cref, 
                    TELEFONE AS Telefone, 
                    CHAVE_PIX AS ChavePix, 
                    PLANO AS Plano, 
                    STATUS AS Status,
                    VALOR_ASSINATURA AS ValorAssinatura,
                    DIA_VENCIMENTO AS DiaVencimento,
                    ULTIMO_PAGAMENTO_MES AS UltimoPagamentoMes,
                    LOGO_URL AS LogoUrl 
                FROM PERSONAIS 
                WHERE ID = @PersonalId",
                new { PersonalId = personalId }
            );

            var totalAlunosAtivos = await con.ExecuteScalarAsync<int>(@"
                SELECT COUNT(1)
                FROM ALUNOS A
                INNER JOIN USUARIOS U ON U.ID = A.USUARIO_ID
                WHERE A.PERSONAL_ID = @PersonalId AND U.STATUS = 1",
                new { PersonalId = personalId }
            );

            var treinosHoje = await con.ExecuteScalarAsync<int>(@"
                SELECT COUNT(1)
                FROM HISTORICO_TREINOS
                WHERE PERSONAL_ID = @PersonalId
                  AND CAST(DATA_HORA AS DATE) = CAST(GETDATE() AS DATE)",
                new { PersonalId = personalId }
            );

            var treinosSemana = await con.ExecuteScalarAsync<int>(@"
                SELECT COUNT(1)
                FROM HISTORICO_TREINOS
                WHERE PERSONAL_ID = @PersonalId
                  AND DATA_HORA >= DATEADD(DAY, -7, GETDATE())",
                new { PersonalId = personalId }
            );

            var receitaRecebidaMes = await con.ExecuteScalarAsync<decimal>(@"
                SELECT ISNULL(SUM(VALOR), 0)
                FROM PAGAMENTOS
                WHERE PERSONAL_ID = @PersonalId
                  AND MES_REFERENCIA = @MesAtual
                  AND STATUS = 'PAGO'",
                new { PersonalId = personalId, MesAtual = mesAtual }
            );

            var receitaPendenteMes = await con.ExecuteScalarAsync<decimal>(@"
                SELECT ISNULL(SUM(VALOR), 0)
                FROM PAGAMENTOS
                WHERE PERSONAL_ID = @PersonalId
                  AND MES_REFERENCIA = @MesAtual
                  AND STATUS <> 'PAGO'",
                new { PersonalId = personalId, MesAtual = mesAtual }
            );

            var alunosSumidos = (await con.QueryAsync<dynamic>(@"
                SELECT
                    A.ID AS AlunoId,
                    U.NOME AS Nome,
                    A.TELEFONE AS Telefone,
                    A.OBJETIVO AS Objetivo,
                    A.FOTO_URL AS FotoUrl,
                    MAX(H.DATA_HORA) AS UltimoTreino,
                    ISNULL(DATEDIFF(DAY, MAX(H.DATA_HORA), GETDATE()), DATEDIFF(DAY, A.DATA_CADASTRO, GETDATE())) AS DiasSemTreinar
                FROM ALUNOS A
                INNER JOIN USUARIOS U ON U.ID = A.USUARIO_ID
                LEFT JOIN HISTORICO_TREINOS H ON H.ALUNO_ID = A.ID
                WHERE A.PERSONAL_ID = @PersonalId
                  AND U.STATUS = 1
                GROUP BY A.ID, U.NOME, A.TELEFONE, A.OBJETIVO, A.FOTO_URL, A.DATA_CADASTRO
                HAVING ISNULL(DATEDIFF(DAY, MAX(H.DATA_HORA), GETDATE()), DATEDIFF(DAY, A.DATA_CADASTRO, GETDATE())) >= 7
                ORDER BY DiasSemTreinar DESC",
                new { PersonalId = personalId }
            )).ToList();

            var ultimosTreinos = (await con.QueryAsync<dynamic>(@"
                SELECT TOP 15
                    H.ID AS Id,
                    H.ALUNO_ID AS AlunoId,
                    U.NOME AS NomeAluno,
                    A.TELEFONE AS TelefoneAluno,
                    H.NOME_TREINO AS NomeTreino,
                    H.DATA_HORA AS DataHora,
                    H.DURACAO_MINUTOS AS DuracaoMinutos,
                    H.OBSERVACAO_ALUNO AS ObservacaoAluno
                FROM HISTORICO_TREINOS H
                INNER JOIN ALUNOS A ON A.ID = H.ALUNO_ID
                INNER JOIN USUARIOS U ON U.ID = A.USUARIO_ID
                WHERE H.PERSONAL_ID = @PersonalId
                ORDER BY H.DATA_HORA DESC",
                new { PersonalId = personalId }
            )).ToList();

            // Cálculo de Vencimento e Tolerância de 5 dias do SaaS
            dynamic? avisoVencimento = null;
            if (personal != null)
            {
                int diaVenc = personal.DiaVencimento != null ? Convert.ToInt32(personal.DiaVencimento) : 10;
                string? ultimoPagto = (string?)personal.UltimoPagamentoMes;
                bool pagoNoMes = (ultimoPagto == mesAtual);
                int hojeDia = DateTime.Now.Day;
                bool emAtraso = !pagoNoMes && hojeDia >= diaVenc;
                int diasAtraso = emAtraso ? (hojeDia - diaVenc) : 0;
                bool emTolerancia = emAtraso && diasAtraso <= 5;
                bool bloqueadoPorAtraso = emAtraso && diasAtraso > 5;
                int diasRestantes = emTolerancia ? (5 - diasAtraso) : 0;

                if (bloqueadoPorAtraso && (bool)personal.Status)
                {
                    await con.ExecuteAsync("UPDATE PERSONAIS SET STATUS = 0 WHERE ID = @Id", new { Id = personalId });
                }

                if (emAtraso)
                {
                    avisoVencimento = new
                    {
                        emAtraso = true,
                        emTolerancia = emTolerancia,
                        diasAtraso = diasAtraso,
                        diasRestantes = diasRestantes,
                        diaVencimento = diaVenc,
                        bloqueadoPorAtraso = bloqueadoPorAtraso,
                        valorAssinatura = (decimal)personal.ValorAssinatura,
                        mensagem = emTolerancia
                            ? $"⚠️ ATENÇÃO: Sua mensalidade da consultoria venceu dia {diaVenc:D2}. Você possui {diasRestantes} dia(s) de tolerância antes do bloqueio da sua conta. Efetue o pagamento para evitar o bloqueio do seu painel e dos seus alunos."
                            : "🚫 Assinatura vencida há mais de 5 dias. O acesso da sua consultoria foi temporariamente bloqueado."
                    };
                }
            }

            return Ok(new
            {
                personal,
                avisoVencimento,
                metricas = new
                {
                    totalAlunosAtivos,
                    treinosHoje,
                    treinosSemana,
                    receitaRecebidaMes,
                    receitaPendenteMes,
                    totalAlunosSumidos = alunosSumidos.Count
                },
                alunosSumidos,
                ultimosTreinos
            });
        }

        [HttpGet("meu-perfil")]
        public async Task<IActionResult> GetMeuPerfil()
        {
            var personalId = UsuarioContexto.GetPersonalId(User);
            using var con = _db.CriarConexao();
            var p = await con.QueryFirstOrDefaultAsync<dynamic>(
                "SELECT ID AS Id, NOME_PROFISSIONAL AS NomeProfissional, CREF AS Cref, CPF_CNPJ AS CpfCnpj, EMAIL AS Email, TELEFONE AS Telefone, CHAVE_PIX AS ChavePix, PLANO AS Plano, VALOR_ASSINATURA AS ValorAssinatura, DIA_VENCIMENTO AS DiaVencimento, LOGO_URL AS LogoUrl FROM PERSONAIS WHERE ID = @Id",
                new { Id = personalId }
            );
            return Ok(p);
        }

        [HttpPut("meu-perfil")]
        public async Task<IActionResult> AtualizarMeuPerfil([FromBody] PerfilPersonalDto dto)
        {
            var personalId = UsuarioContexto.GetPersonalId(User);
            var usuarioId = UsuarioContexto.GetUsuarioId(User);
            var foto = !string.IsNullOrWhiteSpace(dto.FotoUrl) ? dto.FotoUrl : dto.LogoUrl;

            using var con = _db.CriarConexao();
            await con.ExecuteAsync(@"
                UPDATE PERSONAIS
                SET NOME_PROFISSIONAL = @NomeProfissional,
                    CREF = @Cref,
                    TELEFONE = @Telefone,
                    CHAVE_PIX = @ChavePix,
                    LOGO_URL = CASE WHEN @Foto IS NOT NULL AND @Foto <> '' THEN @Foto ELSE LOGO_URL END
                WHERE ID = @PersonalId;

                UPDATE USUARIOS
                SET NOME = @NomeProfissional
                WHERE ID = @UsuarioId;",
                new
                {
                    PersonalId = personalId,
                    UsuarioId = usuarioId,
                    dto.NomeProfissional,
                    dto.Cref,
                    dto.Telefone,
                    dto.ChavePix,
                    Foto = string.IsNullOrWhiteSpace(foto) ? null : foto
                }
            );

            return Ok(new { mensagem = "Perfil, Foto e Dados atualizados com sucesso!" });
        }

        [HttpGet("alunos")]
        public async Task<IActionResult> ListarAlunos()
        {
            var personalId = UsuarioContexto.GetPersonalId(User);
            using var con = _db.CriarConexao();
            var mesAtual = DateTime.Now.ToString("yyyy-MM");

            var alunos = await con.QueryAsync<dynamic>(@"
                SELECT
                    A.ID AS Id,
                    A.USUARIO_ID AS UsuarioId,
                    U.NOME AS Nome,
                    U.EMAIL AS Email,
                    U.STATUS AS Status,
                    A.CPF AS Cpf,
                    A.TELEFONE AS Telefone,
                    A.DATA_NASCIMENTO AS DataNascimento,
                    A.OBJETIVO AS Objetivo,
                    A.FOTO_URL AS FotoUrl,
                    A.VALOR_MENSALIDADE AS ValorMensalidade,
                    A.DIA_VENCIMENTO AS DiaVencimento,
                    A.DATA_CADASTRO AS DataCadastro,
                    (SELECT COUNT(1) FROM FICHAS_TREINO F WHERE F.ALUNO_ID = A.ID AND F.ATIVA = 1) AS TotalFichas,
                    (SELECT MAX(H.DATA_HORA) FROM HISTORICO_TREINOS H WHERE H.ALUNO_ID = A.ID) AS UltimoTreino,
                    ISNULL((
                        SELECT TOP 1 P.STATUS
                        FROM PAGAMENTOS P
                        WHERE P.ALUNO_ID = A.ID AND P.MES_REFERENCIA = @MesAtual
                        ORDER BY P.ID DESC
                    ), 'SEM_COBRANCA') AS StatusFinanceiroMes
                FROM ALUNOS A
                INNER JOIN USUARIOS U ON U.ID = A.USUARIO_ID
                WHERE A.PERSONAL_ID = @PersonalId
                ORDER BY U.STATUS DESC, U.NOME ASC",
                new { PersonalId = personalId, MesAtual = mesAtual }
            );

            return Ok(alunos);
        }

        [HttpPost("alunos")]
        public async Task<IActionResult> CadastrarAluno([FromBody] NovoAlunoDto dto)
        {
            var personalId = UsuarioContexto.GetPersonalId(User);
            if (string.IsNullOrWhiteSpace(dto.Nome) || string.IsNullOrWhiteSpace(dto.Email))
                return BadRequest(new { mensagem = "Nome e E-mail do aluno são obrigatórios." });

            var senhaInicial = string.IsNullOrWhiteSpace(dto.Senha) ? "admin123" : dto.Senha;

            using var con = _db.CriarConexao();
            con.Open();

            var existe = await con.ExecuteScalarAsync<int>(
                "SELECT COUNT(1) FROM USUARIOS WHERE EMAIL = @Email",
                new { Email = dto.Email.Trim() }
            );
            if (existe > 0)
                return BadRequest(new { mensagem = "Já existe um usuário com este e-mail cadastrado." });

            var personal = await con.QueryFirstOrDefaultAsync<dynamic>(
                "SELECT NOME_PROFISSIONAL AS Nome, CHAVE_PIX AS ChavePix FROM PERSONAIS WHERE ID = @Id",
                new { Id = personalId }
            );

            using var trans = con.BeginTransaction();
            try
            {
                var senhaHash = BCrypt.Net.BCrypt.HashPassword(senhaInicial);

                var usuarioId = await con.ExecuteScalarAsync<int>(@"
                    INSERT INTO USUARIOS (PERSONAL_ID, NOME, EMAIL, SENHA_HASH, PERFIL, STATUS, DATA_CADASTRO)
                    VALUES (@PersonalId, @Nome, @Email, @SenhaHash, 2, 1, GETDATE());
                    SELECT CAST(SCOPE_IDENTITY() AS INT);",
                    new
                    {
                        PersonalId = personalId,
                        Nome = dto.Nome.Trim(),
                        Email = dto.Email.Trim(),
                        SenhaHash = senhaHash
                    },
                    trans
                );

                var alunoId = await con.ExecuteScalarAsync<int>(@"
                    INSERT INTO ALUNOS (
                        USUARIO_ID, PERSONAL_ID, CPF, TELEFONE, DATA_NASCIMENTO,
                        OBJETIVO, FOTO_URL, VALOR_MENSALIDADE, DIA_VENCIMENTO, DATA_CADASTRO
                    )
                    VALUES (
                        @UsuarioId, @PersonalId, @Cpf, @Telefone, @DataNascimento,
                        @Objetivo, @FotoUrl, @ValorMensalidade, @DiaVencimento, GETDATE()
                    );
                    SELECT CAST(SCOPE_IDENTITY() AS INT);",
                    new
                    {
                        UsuarioId = usuarioId,
                        PersonalId = personalId,
                        dto.Cpf,
                        dto.Telefone,
                        DataNascimento = string.IsNullOrWhiteSpace(dto.DataNascimento) ? (DateTime?)null : DateTime.Parse(dto.DataNascimento),
                        Objetivo = string.IsNullOrWhiteSpace(dto.Objetivo) ? "Hipertrofia" : dto.Objetivo,
                        dto.FotoUrl,
                        ValorMensalidade = dto.ValorMensalidade > 0 ? dto.ValorMensalidade : 150.00m,
                        DiaVencimento = dto.DiaVencimento > 0 ? dto.DiaVencimento : 10
                    },
                    trans
                );

                var mesAtual = DateTime.Now.ToString("yyyy-MM");
                var valor = dto.ValorMensalidade > 0 ? dto.ValorMensalidade : 150.00m;
                var diaVenc = Math.Clamp(dto.DiaVencimento > 0 ? dto.DiaVencimento : 10, 1, 28);
                var dataVenc = new DateTime(DateTime.Now.Year, DateTime.Now.Month, diaVenc);
                if (dataVenc < DateTime.Today) dataVenc = DateTime.Today.AddDays(5);

                string chavePix = personal?.ChavePix ?? "personal@personalpro.com";
                string nomePersonal = personal?.Nome ?? "PERSONALPRO";
                var pixPayload = PixPayloadService.GerarPayload(chavePix, nomePersonal, "SAO PAULO", valor, $"ALUNO{alunoId}");

                await con.ExecuteAsync(@"
                    INSERT INTO PAGAMENTOS (ALUNO_ID, PERSONAL_ID, MES_REFERENCIA, VALOR, DATA_VENCIMENTO, STATUS, OBSERVACAO, PIX_COPIA_E_COLA)
                    VALUES (@AlunoId, @PersonalId, @MesReferencia, @Valor, @DataVencimento, 'PENDENTE', @Observacao, @Pix);",
                    new
                    {
                        AlunoId = alunoId,
                        PersonalId = personalId,
                        MesReferencia = mesAtual,
                        Valor = valor,
                        DataVencimento = dataVenc,
                        Observacao = $"Mensalidade Consultoria — {mesAtual}",
                        Pix = pixPayload
                    },
                    trans
                );

                trans.Commit();
                return Ok(new { mensagem = "Aluno cadastrado com sucesso!", alunoId, usuarioId });
            }
            catch
            {
                trans.Rollback();
                throw;
            }
        }

        [HttpPut("alunos/{id}")]
        public async Task<IActionResult> EditarAluno(int id, [FromBody] EditarAlunoDto dto)
        {
            var personalId = UsuarioContexto.GetPersonalId(User);
            using var con = _db.CriarConexao();

            var aluno = await con.QueryFirstOrDefaultAsync<dynamic>(
                "SELECT ID, USUARIO_ID AS UsuarioId FROM ALUNOS WHERE ID = @Id AND PERSONAL_ID = @PersonalId",
                new { Id = id, PersonalId = personalId }
            );

            if (aluno == null) return NotFound(new { mensagem = "Aluno não encontrado." });

            await con.ExecuteAsync(@"
                UPDATE ALUNOS
                SET CPF = @Cpf,
                    TELEFONE = @Telefone,
                    DATA_NASCIMENTO = @DataNascimento,
                    OBJETIVO = @Objetivo,
                    FOTO_URL = CASE WHEN @FotoUrl IS NOT NULL THEN (CASE WHEN @FotoUrl = '' THEN NULL ELSE @FotoUrl END) ELSE FOTO_URL END,
                    VALOR_MENSALIDADE = @ValorMensalidade,
                    DIA_VENCIMENTO = @DiaVencimento
                WHERE ID = @Id AND PERSONAL_ID = @PersonalId;

                UPDATE USUARIOS
                SET NOME = ISNULL(NULLIF(@Nome, ''), NOME),
                    EMAIL = ISNULL(NULLIF(@Email, ''), EMAIL),
                    STATUS = @Status
                WHERE ID = @UsuarioId AND PERSONAL_ID = @PersonalId;",
                new
                {
                    Id = id,
                    PersonalId = personalId,
                    UsuarioId = (int)aluno.UsuarioId,
                    Nome = dto.Nome?.Trim() ?? string.Empty,
                    Email = dto.Email?.Trim() ?? string.Empty,
                    dto.Cpf,
                    dto.Telefone,
                    DataNascimento = string.IsNullOrWhiteSpace(dto.DataNascimento) ? (DateTime?)null : DateTime.Parse(dto.DataNascimento),
                    dto.Objetivo,
                    dto.FotoUrl,
                    dto.ValorMensalidade,
                    dto.DiaVencimento,
                    dto.Status
                }
            );

            if (!string.IsNullOrWhiteSpace(dto.NovaSenha) && dto.NovaSenha.Length >= 6)
            {
                var hash = BCrypt.Net.BCrypt.HashPassword(dto.NovaSenha);
                await con.ExecuteAsync(
                    "UPDATE USUARIOS SET SENHA_HASH = @Hash WHERE ID = @UsuarioId AND PERSONAL_ID = @PersonalId",
                    new { Hash = hash, UsuarioId = (int)aluno.UsuarioId, PersonalId = personalId }
                );
            }

            return Ok(new { mensagem = "Dados e foto do aluno atualizados com sucesso!" });
        }

        [HttpPut("alunos/{id}/foto")]
        public async Task<IActionResult> AtualizarFotoAluno(int id, [FromBody] AtualizarFotoAlunoDto dto)
        {
            var personalId = UsuarioContexto.GetPersonalId(User);
            using var con = _db.CriarConexao();

            var fotoUrlLimpa = string.IsNullOrWhiteSpace(dto.FotoUrl) ? null : dto.FotoUrl.Trim();
            var rows = await con.ExecuteAsync(
                "UPDATE ALUNOS SET FOTO_URL = @FotoUrl WHERE ID = @Id AND PERSONAL_ID = @PersonalId",
                new { Id = id, PersonalId = personalId, FotoUrl = fotoUrlLimpa }
            );

            if (rows == 0) return NotFound(new { mensagem = "Aluno não encontrado." });

            return Ok(new { mensagem = "Foto de perfil do aluno atualizada com sucesso!" });
        }

        // ─── AVALIAÇÕES FÍSICAS, MEDIDAS E FOTOS ANTES x DEPOIS ───────────────────────
        [HttpGet("alunos/{alunoId}/avaliacoes")]
        public async Task<IActionResult> ListarAvaliacoes(int alunoId)
        {
            var personalId = UsuarioContexto.GetPersonalId(User);
            using var con = _db.CriarConexao();

            var avaliacoes = await con.QueryAsync<dynamic>(@"
                SELECT
                    ID AS Id,
                    ALUNO_ID AS AlunoId,
                    DATA_AVALIACAO AS DataAvaliacao,
                    PESO AS Peso,
                    ALTURA AS Altura,
                    PERCENTUAL_GORDURA AS PercentualGordura,
                    MEDIDAS_JSON AS MedidasJson,
                    RESTRICOES_LESOES AS RestricoesLesoes,
                    OBSERVACOES AS Observacoes,
                    FOTO_FRENTE_URL AS FotoFrenteUrl,
                    FOTO_LADO_COSTAS_URL AS FotoLadoCostasUrl
                FROM AVALIACOES_FISICAS
                WHERE ALUNO_ID = @AlunoId AND PERSONAL_ID = @PersonalId
                ORDER BY DATA_AVALIACAO DESC, ID DESC",
                new { AlunoId = alunoId, PersonalId = personalId }
            );

            var progressaoCargas = await con.QueryAsync<dynamic>(@"
                SELECT
                    ID AS Id,
                    NOME_EXERCICIO AS NomeExercicio,
                    GRUPO_MUSCULAR AS GrupoMuscular,
                    CARGA_KG AS CargaKg,
                    DATA_REGISTRO AS DataRegistro
                FROM PROGRESSAO_CARGAS
                WHERE ALUNO_ID = @AlunoId AND PERSONAL_ID = @PersonalId
                ORDER BY DATA_REGISTRO ASC",
                new { AlunoId = alunoId, PersonalId = personalId }
            );

            return Ok(new
            {
                avaliacoes,
                progressaoCargas
            });
        }

        [HttpPost("alunos/{alunoId}/avaliacoes")]
        public async Task<IActionResult> CriarAvaliacao(int alunoId, [FromBody] NovaAvaliacaoDto dto)
        {
            var personalId = UsuarioContexto.GetPersonalId(User);
            using var con = _db.CriarConexao();

            var aluno = await con.QueryFirstOrDefaultAsync<dynamic>(
                "SELECT USUARIO_ID AS UsuarioId FROM ALUNOS WHERE ID = @Id AND PERSONAL_ID = @PersonalId",
                new { Id = alunoId, PersonalId = personalId }
            );
            if (aluno == null) return NotFound(new { mensagem = "Aluno não encontrado." });

            var id = await con.ExecuteScalarAsync<int>(@"
                INSERT INTO AVALIACOES_FISICAS (
                    ALUNO_ID, PERSONAL_ID, DATA_AVALIACAO, PESO, ALTURA,
                    PERCENTUAL_GORDURA, MEDIDAS_JSON, RESTRICOES_LESOES, OBSERVACOES,
                    FOTO_FRENTE_URL, FOTO_LADO_COSTAS_URL
                )
                VALUES (
                    @AlunoId, @PersonalId, GETDATE(), @Peso, @Altura,
                    @PercentualGordura, @MedidasJson, @RestricoesLesoes, @Observacoes,
                    @FotoFrenteUrl, @FotoLadoCostasUrl
                );
                SELECT CAST(SCOPE_IDENTITY() AS INT);",
                new
                {
                    AlunoId = alunoId,
                    PersonalId = personalId,
                    dto.Peso,
                    dto.Altura,
                    dto.PercentualGordura,
                    dto.MedidasJson,
                    dto.RestricoesLesoes,
                    dto.Observacoes,
                    dto.FotoFrenteUrl,
                    dto.FotoLadoCostasUrl
                }
            );

            await _notificacao.EnviarNotificacaoAsync(
                personalId,
                (int)aluno.UsuarioId,
                "📏 Nova Avaliação Física + Fotos Registradas!",
                $"Seu Personal registrou sua nova avaliação física (Peso: {dto.Peso}kg | % Gordura: {dto.PercentualGordura ?? 0}%). Confira seus gráficos e fotos na aba Evolução!",
                "AVALIACAO"
            );

            return Ok(new { mensagem = "Avaliação física e fotos salvas com sucesso!", id });
        }

        [HttpDelete("avaliacoes/{id}")]
        public async Task<IActionResult> ExcluirAvaliacao(int id)
        {
            var personalId = UsuarioContexto.GetPersonalId(User);
            using var con = _db.CriarConexao();
            await con.ExecuteAsync(
                "DELETE FROM AVALIACOES_FISICAS WHERE ID = @Id AND PERSONAL_ID = @PersonalId",
                new { Id = id, PersonalId = personalId }
            );
            return Ok(new { mensagem = "Avaliação removida." });
        }

        [HttpDelete("alunos/{id}")]
        public async Task<IActionResult> ExcluirAluno(int id)
        {
            var personalId = UsuarioContexto.GetPersonalId(User);
            var isSuperAdmin = User.IsInRole("SuperAdmin");

            using var con = _db.CriarConexao();
            con.Open();

            var aluno = await con.QueryFirstOrDefaultAsync<dynamic>(
                "SELECT A.ID, A.USUARIO_ID, U.NOME FROM ALUNOS A INNER JOIN USUARIOS U ON U.ID = A.USUARIO_ID WHERE A.ID = @Id " +
                (isSuperAdmin ? "" : "AND A.PERSONAL_ID = @PersonalId"),
                new { Id = id, PersonalId = personalId }
            );

            if (aluno == null)
                return NotFound(new { mensagem = "Aluno não encontrado ou não pertence a este Personal." });

            int usuarioId = (int)aluno.USUARIO_ID;
            string nomeAluno = (string)aluno.NOME;

            using var trans = con.BeginTransaction();
            try
            {
                // 1. REFEICOES_PLANO (vinculadas aos planos do aluno)
                await con.ExecuteAsync(@"
                    DELETE RP
                    FROM REFEICOES_PLANO RP
                    INNER JOIN PLANOS_ALIMENTARES PA ON PA.ID = RP.PLANO_ID
                    WHERE PA.ALUNO_ID = @Id",
                    new { Id = id }, trans);

                // 2. PLANOS_ALIMENTARES
                await con.ExecuteAsync("DELETE FROM PLANOS_ALIMENTARES WHERE ALUNO_ID = @Id", new { Id = id }, trans);

                // 3. AGENDA_AULAS
                await con.ExecuteAsync("DELETE FROM AGENDA_AULAS WHERE ALUNO_ID = @Id", new { Id = id }, trans);

                // 4. PROGRESSAO_CARGAS
                await con.ExecuteAsync("DELETE FROM PROGRESSAO_CARGAS WHERE ALUNO_ID = @Id", new { Id = id }, trans);

                // 5. HISTORICO_TREINOS
                await con.ExecuteAsync("DELETE FROM HISTORICO_TREINOS WHERE ALUNO_ID = @Id", new { Id = id }, trans);

                // 6. PAGAMENTOS
                await con.ExecuteAsync("DELETE FROM PAGAMENTOS WHERE ALUNO_ID = @Id", new { Id = id }, trans);

                // 7. AVALIACOES_FISICAS
                await con.ExecuteAsync("DELETE FROM AVALIACOES_FISICAS WHERE ALUNO_ID = @Id", new { Id = id }, trans);

                // 8. FICHA_EXERCICIOS
                await con.ExecuteAsync(@"
                    DELETE FE
                    FROM FICHA_EXERCICIOS FE
                    INNER JOIN FICHAS_TREINO FT ON FT.ID = FE.FICHA_ID
                    WHERE FT.ALUNO_ID = @Id",
                    new { Id = id }, trans);

                // 9. FICHAS_TREINO
                await con.ExecuteAsync("DELETE FROM FICHAS_TREINO WHERE ALUNO_ID = @Id", new { Id = id }, trans);

                // 10. NOTIFICACOES
                await con.ExecuteAsync("DELETE FROM NOTIFICACOES WHERE USUARIO_ID = @UsuarioId", new { UsuarioId = usuarioId }, trans);

                // 11. ALUNOS
                await con.ExecuteAsync("DELETE FROM ALUNOS WHERE ID = @Id", new { Id = id }, trans);

                // 12. USUARIOS
                await con.ExecuteAsync("DELETE FROM USUARIOS WHERE ID = @UsuarioId", new { UsuarioId = usuarioId }, trans);

                trans.Commit();
                return Ok(new { mensagem = $"Aluno '{nomeAluno}' e todos os seus registros foram excluídos com sucesso!" });
            }
            catch (Exception ex)
            {
                trans.Rollback();
                return StatusCode(500, new { mensagem = $"Erro ao excluir aluno: {ex.Message}" });
            }
        }

        public class PerfilPersonalDto
        {
            public string NomeProfissional { get; set; } = string.Empty;
            public string? Cref { get; set; }
            public string? Telefone { get; set; }
            public string? ChavePix { get; set; }
            public string? LogoUrl { get; set; }
            public string? FotoUrl { get; set; }
        }

        public class NovoAlunoDto
        {
            public string Nome { get; set; } = string.Empty;
            public string Email { get; set; } = string.Empty;
            public string? Senha { get; set; }
            public string? Cpf { get; set; }
            public string? Telefone { get; set; }
            public string? DataNascimento { get; set; }
            public string Objetivo { get; set; } = "Hipertrofia";
            public string? FotoUrl { get; set; }
            public decimal ValorMensalidade { get; set; } = 200.00m;
            public int DiaVencimento { get; set; } = 10;
        }

        public class EditarAlunoDto
        {
            public string Nome { get; set; } = string.Empty;
            public string Email { get; set; } = string.Empty;
            public string? Cpf { get; set; }
            public string? Telefone { get; set; }
            public string? DataNascimento { get; set; }
            public string Objetivo { get; set; } = "Hipertrofia";
            public string? FotoUrl { get; set; }
            public decimal ValorMensalidade { get; set; } = 200.00m;
            public int DiaVencimento { get; set; } = 10;
            public bool Status { get; set; } = true;
            public string? NovaSenha { get; set; }
        }

        public class AtualizarFotoAlunoDto
        {
            public string? FotoUrl { get; set; }
        }

        public class NovaAvaliacaoDto
        {
            public decimal Peso { get; set; }
            public decimal Altura { get; set; } = 1.75m;
            public decimal? PercentualGordura { get; set; }
            public string? MedidasJson { get; set; }
            public string? RestricoesLesoes { get; set; }
            public string? Observacoes { get; set; }
            public string? FotoFrenteUrl { get; set; }
            public string? FotoLadoCostasUrl { get; set; }
        }
    }
}
