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
    [Authorize]
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

            var personal = await con.QueryFirstOrDefaultAsync<dynamic>(
                "SELECT ID AS Id, NOME_PROFISSIONAL AS NomeProfissional, CREF AS Cref, TELEFONE AS Telefone, CHAVE_PIX AS ChavePix, PLANO AS Plano FROM PERSONAIS WHERE ID = @PersonalId",
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

            // Alerta de "Alunos Sumidos" (+7 dias sem registrar treino concluído)
            var alunosSumidos = (await con.QueryAsync<dynamic>(@"
                SELECT
                    A.ID AS AlunoId,
                    U.NOME AS Nome,
                    A.TELEFONE AS Telefone,
                    A.OBJETIVO AS Objetivo,
                    MAX(H.DATA_HORA) AS UltimoTreino,
                    ISNULL(DATEDIFF(DAY, MAX(H.DATA_HORA), GETDATE()), DATEDIFF(DAY, A.DATA_CADASTRO, GETDATE())) AS DiasSemTreinar
                FROM ALUNOS A
                INNER JOIN USUARIOS U ON U.ID = A.USUARIO_ID
                LEFT JOIN HISTORICO_TREINOS H ON H.ALUNO_ID = A.ID
                WHERE A.PERSONAL_ID = @PersonalId
                  AND U.STATUS = 1
                GROUP BY A.ID, U.NOME, A.TELEFONE, A.OBJETIVO, A.DATA_CADASTRO
                HAVING ISNULL(DATEDIFF(DAY, MAX(H.DATA_HORA), GETDATE()), DATEDIFF(DAY, A.DATA_CADASTRO, GETDATE())) >= 7
                ORDER BY DiasSemTreinar DESC",
                new { PersonalId = personalId }
            )).ToList();

            // Últimos treinos concluídos pelos alunos
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

            return Ok(new
            {
                personal,
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
                "SELECT ID AS Id, NOME_PROFISSIONAL AS NomeProfissional, CREF AS Cref, CPF_CNPJ AS CpfCnpj, EMAIL AS Email, TELEFONE AS Telefone, CHAVE_PIX AS ChavePix, PLANO AS Plano, VALOR_ASSINATURA AS ValorAssinatura, DIA_VENCIMENTO AS DiaVencimento FROM PERSONAIS WHERE ID = @Id",
                new { Id = personalId }
            );
            return Ok(p);
        }

        [HttpPut("meu-perfil")]
        public async Task<IActionResult> AtualizarMeuPerfil([FromBody] PerfilPersonalDto dto)
        {
            var personalId = UsuarioContexto.GetPersonalId(User);
            var usuarioId = UsuarioContexto.GetUsuarioId(User);

            using var con = _db.CriarConexao();
            await con.ExecuteAsync(@"
                UPDATE PERSONAIS
                SET NOME_PROFISSIONAL = @NomeProfissional,
                    CREF = @Cref,
                    TELEFONE = @Telefone,
                    CHAVE_PIX = @ChavePix
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
                    dto.ChavePix
                }
            );

            return Ok(new { mensagem = "Configurações e Chave PIX salvas com sucesso!" });
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
                        OBJETIVO, VALOR_MENSALIDADE, DIA_VENCIMENTO, DATA_CADASTRO
                    )
                    VALUES (
                        @UsuarioId, @PersonalId, @Cpf, @Telefone, @DataNascimento,
                        @Objetivo, @ValorMensalidade, @DiaVencimento, GETDATE()
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
                        ValorMensalidade = dto.ValorMensalidade > 0 ? dto.ValorMensalidade : 150.00m,
                        DiaVencimento = dto.DiaVencimento > 0 ? dto.DiaVencimento : 10
                    },
                    trans
                );

                // Já gera a cobrança do mês atual com PIX Copia e Cola
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
                    VALOR_MENSALIDADE = @ValorMensalidade,
                    DIA_VENCIMENTO = @DiaVencimento
                WHERE ID = @Id AND PERSONAL_ID = @PersonalId;

                UPDATE USUARIOS
                SET NOME = @Nome,
                    EMAIL = @Email,
                    STATUS = @Status
                WHERE ID = @UsuarioId AND PERSONAL_ID = @PersonalId;",
                new
                {
                    Id = id,
                    PersonalId = personalId,
                    UsuarioId = (int)aluno.UsuarioId,
                    dto.Nome,
                    Email = dto.Email.Trim(),
                    dto.Cpf,
                    dto.Telefone,
                    DataNascimento = string.IsNullOrWhiteSpace(dto.DataNascimento) ? (DateTime?)null : DateTime.Parse(dto.DataNascimento),
                    dto.Objetivo,
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

            return Ok(new { mensagem = "Dados do aluno atualizados com sucesso!" });
        }

        // ─── AVALIAÇÕES FÍSICAS & MEDIDAS (ANAMNESE) ──────────────────────────────────
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
                    OBSERVACOES AS Observacoes
                FROM AVALIACOES_FISICAS
                WHERE ALUNO_ID = @AlunoId AND PERSONAL_ID = @PersonalId
                ORDER BY DATA_AVALIACAO DESC, ID DESC",
                new { AlunoId = alunoId, PersonalId = personalId }
            );

            return Ok(avaliacoes);
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
                    PERCENTUAL_GORDURA, MEDIDAS_JSON, RESTRICOES_LESOES, OBSERVACOES
                )
                VALUES (
                    @AlunoId, @PersonalId, GETDATE(), @Peso, @Altura,
                    @PercentualGordura, @MedidasJson, @RestricoesLesoes, @Observacoes
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
                    dto.Observacoes
                }
            );

            await _notificacao.EnviarNotificacaoAsync(
                personalId,
                (int)aluno.UsuarioId,
                "📏 Nova Avaliação Física Registrada!",
                $"Seu Personal registrou sua nova avaliação física (Peso: {dto.Peso}kg | % Gordura: {dto.PercentualGordura ?? 0}%). Confira na aba Evolução!",
                "AVALIACAO"
            );

            return Ok(new { mensagem = "Avaliação física salva com sucesso!", id });
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

        public class PerfilPersonalDto
        {
            public string NomeProfissional { get; set; } = string.Empty;
            public string? Cref { get; set; }
            public string? Telefone { get; set; }
            public string? ChavePix { get; set; }
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
            public decimal ValorMensalidade { get; set; } = 200.00m;
            public int DiaVencimento { get; set; } = 10;
            public bool Status { get; set; } = true;
            public string? NovaSenha { get; set; }
        }

        public class NovaAvaliacaoDto
        {
            public decimal Peso { get; set; }
            public decimal Altura { get; set; } = 1.75m;
            public decimal? PercentualGordura { get; set; }
            public string? MedidasJson { get; set; }
            public string? RestricoesLesoes { get; set; }
            public string? Observacoes { get; set; }
        }
    }
}
