using Dapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PersonalProAPI.Data;
using PersonalProAPI.Helpers;
using PersonalProAPI.Services;

namespace PersonalProAPI.Controllers
{
    [ApiController]
    [Route("api")]
    [Authorize]
    public class DietaAgendaController : ControllerBase
    {
        private readonly DbConnection _db;
        private readonly NotificacaoService _notificacao;

        public DietaAgendaController(DbConnection db, NotificacaoService notificacao)
        {
            _db = db;
            _notificacao = notificacao;
        }

        // =========================================================================
        // 1. DIETA / PLANO ALIMENTAR & CALCULADORA DE MACROS (PERSONAL & ALUNO)
        // =========================================================================

        [HttpGet("dieta/aluno/{alunoId}")]
        public async Task<IActionResult> ObterDietaDoAluno(int alunoId)
        {
            var personalId = UsuarioContexto.GetPersonalId(User);
            using var con = _db.CriarConexao();

            var plano = await con.QueryFirstOrDefaultAsync<dynamic>(@"
                SELECT TOP 1
                    ID AS Id,
                    ALUNO_ID AS AlunoId,
                    PERSONAL_ID AS PersonalId,
                    TITULO AS Titulo,
                    OBJETIVO AS Objetivo,
                    PESO_BASE_KG AS PesoBaseKg,
                    ALTURA_CM AS AlturaCm,
                    IDADE AS Idade,
                    SEXO AS Sexo,
                    FATOR_ATIVIDADE AS FatorAtividade,
                    TMB_KCAL AS TmbKcal,
                    GET_KCAL AS GetKcal,
                    META_KCAL AS MetaKcal,
                    PROTEINA_G AS ProteinaG,
                    CARBOIDRATO_G AS CarboidratoG,
                    GORDURA_G AS GorduraG,
                    AGUA_LITROS AS AguaLitros,
                    OBSERVACOES AS Observacoes,
                    DATA_CRIACAO AS DataCriacao
                FROM PLANOS_ALIMENTARES
                WHERE ALUNO_ID = @AlunoId AND PERSONAL_ID = @PersonalId AND ATIVO = 1
                ORDER BY ID DESC",
                new { AlunoId = alunoId, PersonalId = personalId }
            );

            if (plano == null)
            {
                return Ok(new { plano = (object?)null, refeicoes = Array.Empty<object>() });
            }

            int planoId = (int)plano.Id;
            var refeicoes = (await con.QueryAsync<dynamic>(@"
                SELECT
                    ID AS Id,
                    PLANO_ID AS PlanoId,
                    HORARIO AS Horario,
                    NOME_REFEICAO AS NomeRefeicao,
                    ALIMENTOS_DESCRICAO AS AlimentosDescricao,
                    SUBSTITUICOES AS Substituicoes,
                    KCAL_ESTIMADA AS KcalEstimada,
                    PROTEINA_G AS ProteinaG,
                    CARBO_G AS CarboG,
                    GORDURA_G AS GorduraG,
                    ORDEM AS Ordem
                FROM REFEICOES_PLANO
                WHERE PLANO_ID = @PlanoId
                ORDER BY ORDEM ASC, ID ASC",
                new { PlanoId = planoId }
            )).ToList();

            return Ok(new { plano, refeicoes });
        }

        [HttpGet("dieta/minha-dieta")]
        public async Task<IActionResult> ObterMinhaDietaAluno()
        {
            var usuarioId = UsuarioContexto.GetUsuarioId(User);
            using var con = _db.CriarConexao();

            var alunoId = await con.ExecuteScalarAsync<int?>(
                "SELECT ID FROM ALUNOS WHERE USUARIO_ID = @UsuarioId",
                new { UsuarioId = usuarioId }
            );

            if (alunoId == null) return NotFound(new { erro = "Aluno não localizado." });

            var plano = await con.QueryFirstOrDefaultAsync<dynamic>(@"
                SELECT TOP 1
                    ID AS Id,
                    ALUNO_ID AS AlunoId,
                    PERSONAL_ID AS PersonalId,
                    TITULO AS Titulo,
                    OBJETIVO AS Objetivo,
                    PESO_BASE_KG AS PesoBaseKg,
                    ALTURA_CM AS AlturaCm,
                    IDADE AS Idade,
                    SEXO AS Sexo,
                    FATOR_ATIVIDADE AS FatorAtividade,
                    TMB_KCAL AS TmbKcal,
                    GET_KCAL AS GetKcal,
                    META_KCAL AS MetaKcal,
                    PROTEINA_G AS ProteinaG,
                    CARBOIDRATO_G AS CarboidratoG,
                    GORDURA_G AS GorduraG,
                    AGUA_LITROS AS AguaLitros,
                    OBSERVACOES AS Observacoes,
                    DATA_CRIACAO AS DataCriacao
                FROM PLANOS_ALIMENTARES
                WHERE ALUNO_ID = @AlunoId AND ATIVO = 1
                ORDER BY ID DESC",
                new { AlunoId = alunoId.Value }
            );

            if (plano == null)
            {
                return Ok(new { plano = (object?)null, refeicoes = Array.Empty<object>() });
            }

            int planoId = (int)plano.Id;
            var refeicoes = (await con.QueryAsync<dynamic>(@"
                SELECT
                    ID AS Id,
                    PLANO_ID AS PlanoId,
                    HORARIO AS Horario,
                    NOME_REFEICAO AS NomeRefeicao,
                    ALIMENTOS_DESCRICAO AS AlimentosDescricao,
                    SUBSTITUICOES AS Substituicoes,
                    KCAL_ESTIMADA AS KcalEstimada,
                    PROTEINA_G AS ProteinaG,
                    CARBO_G AS CarboG,
                    GORDURA_G AS GorduraG,
                    ORDEM AS Ordem
                FROM REFEICOES_PLANO
                WHERE PLANO_ID = @PlanoId
                ORDER BY ORDEM ASC, ID ASC",
                new { PlanoId = planoId }
            )).ToList();

            return Ok(new { plano, refeicoes });
        }

        [HttpPost("dieta/salvar")]
        public async Task<IActionResult> SalvarPlanoAlimentar([FromBody] SalvarPlanoAlimentarDto dto)
        {
            if (UsuarioContexto.GetPerfil(User) != 1) return Forbid();
            var personalId = UsuarioContexto.GetPersonalId(User);

            using var con = _db.CriarConexao();

            // Desativa planos anteriores do aluno
            await con.ExecuteAsync(
                "UPDATE PLANOS_ALIMENTARES SET ATIVO = 0 WHERE ALUNO_ID = @AlunoId AND PERSONAL_ID = @PersonalId",
                new { dto.AlunoId, PersonalId = personalId }
            );

            var novoPlanoId = await con.ExecuteScalarAsync<int>(@"
                INSERT INTO PLANOS_ALIMENTARES (
                    ALUNO_ID, PERSONAL_ID, TITULO, OBJETIVO, PESO_BASE_KG, ALTURA_CM, IDADE, SEXO,
                    FATOR_ATIVIDADE, TMB_KCAL, GET_KCAL, META_KCAL, PROTEINA_G, CARBOIDRATO_G, GORDURA_G,
                    AGUA_LITROS, OBSERVACOES, ATIVO, DATA_CRIACAO
                )
                VALUES (
                    @AlunoId, @PersonalId, @Titulo, @Objetivo, @PesoBaseKg, @AlturaCm, @Idade, @Sexo,
                    @FatorAtividade, @TmbKcal, @GetKcal, @MetaKcal, @ProteinaG, @CarboidratoG, @GorduraG,
                    @AguaLitros, @Observacoes, 1, GETDATE()
                );
                SELECT CAST(SCOPE_IDENTITY() AS INT);",
                new
                {
                    dto.AlunoId,
                    PersonalId = personalId,
                    Titulo = string.IsNullOrWhiteSpace(dto.Titulo) ? "Plano Alimentar & Macros PersonalPro" : dto.Titulo,
                    Objetivo = dto.Objetivo ?? "Hipertrofia",
                    dto.PesoBaseKg,
                    dto.AlturaCm,
                    dto.Idade,
                    Sexo = string.IsNullOrWhiteSpace(dto.Sexo) ? "M" : dto.Sexo.Substring(0, 1).ToUpper(),
                    dto.FatorAtividade,
                    dto.TmbKcal,
                    dto.GetKcal,
                    dto.MetaKcal,
                    dto.ProteinaG,
                    dto.CarboidratoG,
                    dto.GorduraG,
                    dto.AguaLitros,
                    dto.Observacoes
                }
            );

            int ordem = 1;
            foreach (var r in dto.Refeicoes)
            {
                await con.ExecuteAsync(@"
                    INSERT INTO REFEICOES_PLANO (
                        PLANO_ID, HORARIO, NOME_REFEICAO, ALIMENTOS_DESCRICAO, SUBSTITUICOES,
                        KCAL_ESTIMADA, PROTEINA_G, CARBO_G, GORDURA_G, ORDEM
                    )
                    VALUES (
                        @PlanoId, @Horario, @NomeRefeicao, @AlimentosDescricao, @Substituicoes,
                        @KcalEstimada, @ProteinaG, @CarboG, @GorduraG, @Ordem
                    );",
                    new
                    {
                        PlanoId = novoPlanoId,
                        Horario = r.Horario ?? "08:00",
                        NomeRefeicao = r.NomeRefeicao ?? $"Refeição {ordem}",
                        AlimentosDescricao = r.AlimentosDescricao ?? "",
                        r.Substituicoes,
                        r.KcalEstimada,
                        r.ProteinaG,
                        r.CarboG,
                        r.GorduraG,
                        Ordem = ordem++
                    }
                );
            }

            var usuarioAlunoId = await con.ExecuteScalarAsync<int?>(
                "SELECT USUARIO_ID FROM ALUNOS WHERE ID = @AlunoId",
                new { dto.AlunoId }
            );
            if (usuarioAlunoId != null)
            {
                await _notificacao.EnviarNotificacaoAsync(
                    personalId,
                    usuarioAlunoId.Value,
                    "🥗 Novo Plano Alimentar & Macros Disponível!",
                    $"Seu Personal prescreveu sua nova dieta ({dto.MetaKcal} kcal • {dto.ProteinaG}g Proteína). Confira na aba Minha Dieta!",
                    "DIETA"
                );
            }

            return Ok(new { mensagem = "Plano Alimentar & Macros salvo com sucesso!", id = novoPlanoId });
        }

        // =========================================================================
        // 2. AGENDA DE HORÁRIOS & AULAS PRESENCIAIS DO PERSONAL
        // =========================================================================

        [HttpGet("agenda/personal")]
        public async Task<IActionResult> ListarAgendaPersonal()
        {
            var personalId = UsuarioContexto.GetPersonalId(User);
            using var con = _db.CriarConexao();

            var aulas = (await con.QueryAsync<dynamic>(@"
                SELECT
                    AG.ID AS Id,
                    AG.PERSONAL_ID AS PersonalId,
                    AG.ALUNO_ID AS AlunoId,
                    U.NOME AS NomeAluno,
                    A.TELEFONE AS TelefoneAluno,
                    A.FOTO_URL AS FotoAluno,
                    A.OBJETIVO AS ObjetivoAluno,
                    AG.DATA_HORA_INICIO AS DataHoraInicio,
                    AG.DURACAO_MINUTOS AS DuracaoMinutos,
                    AG.TIPO_AULA AS TipoAula,
                    AG.TITULO_TREINO AS TituloTreino,
                    AG.LOCAL_ACADEMIA AS LocalAcademia,
                    AG.STATUS AS Status,
                    AG.OBSERVACOES AS Observacoes
                FROM AGENDA_AULAS AG
                INNER JOIN ALUNOS A ON A.ID = AG.ALUNO_ID
                INNER JOIN USUARIOS U ON U.ID = A.USUARIO_ID
                WHERE AG.PERSONAL_ID = @PersonalId
                ORDER BY AG.DATA_HORA_INICIO ASC",
                new { PersonalId = personalId }
            )).ToList();

            var hoje = DateTime.Today;
            int aulasHoje = aulas.Count(x => ((DateTime)x.DataHoraInicio).Date == hoje);
            int concluidasTotal = aulas.Count(x => (string)x.Status == "CONCLUIDA");
            int agendadasPendentes = aulas.Count(x => (string)x.Status == "AGENDADA");

            return Ok(new
            {
                resumo = new
                {
                    aulasHoje,
                    concluidasTotal,
                    agendadasPendentes
                },
                aulas
            });
        }

        [HttpGet("agenda/minhas-aulas")]
        public async Task<IActionResult> ListarMinhasAulasAluno()
        {
            var usuarioId = UsuarioContexto.GetUsuarioId(User);
            using var con = _db.CriarConexao();

            var alunoId = await con.ExecuteScalarAsync<int?>(
                "SELECT ID FROM ALUNOS WHERE USUARIO_ID = @UsuarioId",
                new { UsuarioId = usuarioId }
            );
            if (alunoId == null) return Ok(Array.Empty<object>());

            var aulas = await con.QueryAsync<dynamic>(@"
                SELECT
                    AG.ID AS Id,
                    AG.DATA_HORA_INICIO AS DataHoraInicio,
                    AG.DURACAO_MINUTOS AS DuracaoMinutos,
                    AG.TIPO_AULA AS TipoAula,
                    AG.TITULO_TREINO AS TituloTreino,
                    AG.LOCAL_ACADEMIA AS LocalAcademia,
                    AG.STATUS AS Status,
                    AG.OBSERVACOES AS Observacoes,
                    P.NOME_PROFISSIONAL AS NomePersonal,
                    P.TELEFONE AS TelefonePersonal
                FROM AGENDA_AULAS AG
                INNER JOIN PERSONAIS P ON P.ID = AG.PERSONAL_ID
                WHERE AG.ALUNO_ID = @AlunoId
                ORDER BY AG.DATA_HORA_INICIO ASC",
                new { AlunoId = alunoId.Value }
            );

            return Ok(aulas);
        }

        [HttpPost("agenda")]
        public async Task<IActionResult> CriarAgendamento([FromBody] CriarAgendamentoDto dto)
        {
            if (UsuarioContexto.GetPerfil(User) != 1) return Forbid();
            var personalId = UsuarioContexto.GetPersonalId(User);

            using var con = _db.CriarConexao();
            var id = await con.ExecuteScalarAsync<int>(@"
                INSERT INTO AGENDA_AULAS (
                    PERSONAL_ID, ALUNO_ID, DATA_HORA_INICIO, DURACAO_MINUTOS,
                    TIPO_AULA, TITULO_TREINO, LOCAL_ACADEMIA, STATUS, OBSERVACOES, DATA_CRIACAO
                )
                VALUES (
                    @PersonalId, @AlunoId, @DataHoraInicio, @DuracaoMinutos,
                    @TipoAula, @TituloTreino, @LocalAcademia, 'AGENDADA', @Observacoes, GETDATE()
                );
                SELECT CAST(SCOPE_IDENTITY() AS INT);",
                new
                {
                    PersonalId = personalId,
                    dto.AlunoId,
                    dto.DataHoraInicio,
                    DuracaoMinutos = dto.DuracaoMinutos <= 0 ? 60 : dto.DuracaoMinutos,
                    TipoAula = dto.TipoAula ?? "PRESENCIAL",
                    TituloTreino = dto.TituloTreino ?? "Aula Presencial Personalizada",
                    LocalAcademia = dto.LocalAcademia ?? "Unidade Principal — Sala de Musculação",
                    dto.Observacoes
                }
            );

            var usuarioAlunoId = await con.ExecuteScalarAsync<int?>(
                "SELECT USUARIO_ID FROM ALUNOS WHERE ID = @AlunoId",
                new { dto.AlunoId }
            );
            if (usuarioAlunoId != null)
            {
                await _notificacao.EnviarNotificacaoAsync(
                    personalId,
                    usuarioAlunoId.Value,
                    "📅 Nova Aula Agendada com seu Personal!",
                    $"Horário reservado: {dto.DataHoraInicio:dd/MM às HH:mm} — {dto.TituloTreino}.",
                    "AGENDA"
                );
            }

            return Ok(new { mensagem = "Aula agendada com sucesso!", id });
        }

        [HttpPatch("agenda/{id}/status")]
        public async Task<IActionResult> AtualizarStatusAula(int id, [FromBody] StatusAulaDto dto)
        {
            if (UsuarioContexto.GetPerfil(User) != 1) return Forbid();
            var personalId = UsuarioContexto.GetPersonalId(User);

            using var con = _db.CriarConexao();
            var aula = await con.QueryFirstOrDefaultAsync<dynamic>(
                "SELECT * FROM AGENDA_AULAS WHERE ID = @Id AND PERSONAL_ID = @PersonalId",
                new { Id = id, PersonalId = personalId }
            );
            if (aula == null) return NotFound();

            await con.ExecuteAsync(
                "UPDATE AGENDA_AULAS SET STATUS = @Status WHERE ID = @Id AND PERSONAL_ID = @PersonalId",
                new { Status = dto.Status, Id = id, PersonalId = personalId }
            );

            // Se marcou como CONCLUIDA, grava presença automática no histórico de treinos do aluno
            if (dto.Status == "CONCLUIDA")
            {
                await con.ExecuteAsync(@"
                    INSERT INTO HISTORICO_TREINOS (ALUNO_ID, PERSONAL_ID, FICHA_ID, NOME_TREINO, DATA_HORA, DURACAO_MINUTOS, OBSERVACAO_ALUNO)
                    VALUES (@AlunoId, @PersonalId, NULL, @NomeTreino, GETDATE(), @Duracao, 'Check-in de Aula Presencial realizado pelo Personal Trainer')",
                    new
                    {
                        AlunoId = (int)aula.ALUNO_ID,
                        PersonalId = personalId,
                        NomeTreino = (string)aula.TITULO_TREINO,
                        Duracao = (int)aula.DURACAO_MINUTOS
                    }
                );
            }

            return Ok(new { mensagem = $"Status da aula atualizado para {dto.Status}!" });
        }

        [HttpDelete("agenda/{id}")]
        public async Task<IActionResult> ExcluirAula(int id)
        {
            if (UsuarioContexto.GetPerfil(User) != 1) return Forbid();
            var personalId = UsuarioContexto.GetPersonalId(User);
            using var con = _db.CriarConexao();
            await con.ExecuteAsync(
                "DELETE FROM AGENDA_AULAS WHERE ID = @Id AND PERSONAL_ID = @PersonalId",
                new { Id = id, PersonalId = personalId }
            );
            return Ok(new { mensagem = "Agendamento removido." });
        }
    }

    public class SalvarPlanoAlimentarDto
    {
        public int AlunoId { get; set; }
        public string? Titulo { get; set; }
        public string? Objetivo { get; set; }
        public decimal PesoBaseKg { get; set; } = 80;
        public decimal AlturaCm { get; set; } = 175;
        public int Idade { get; set; } = 25;
        public string? Sexo { get; set; } = "M";
        public decimal FatorAtividade { get; set; } = 1.55m;
        public int TmbKcal { get; set; }
        public int GetKcal { get; set; }
        public int MetaKcal { get; set; }
        public int ProteinaG { get; set; }
        public int CarboidratoG { get; set; }
        public int GorduraG { get; set; }
        public decimal AguaLitros { get; set; } = 3.5m;
        public string? Observacoes { get; set; }
        public List<RefeicaoItemDto> Refeicoes { get; set; } = new();
    }

    public class RefeicaoItemDto
    {
        public string? Horario { get; set; }
        public string? NomeRefeicao { get; set; }
        public string? AlimentosDescricao { get; set; }
        public string? Substituicoes { get; set; }
        public int KcalEstimada { get; set; }
        public int ProteinaG { get; set; }
        public int CarboG { get; set; }
        public int GorduraG { get; set; }
    }

    public class CriarAgendamentoDto
    {
        public int AlunoId { get; set; }
        public DateTime DataHoraInicio { get; set; }
        public int DuracaoMinutos { get; set; } = 60;
        public string? TipoAula { get; set; }
        public string? TituloTreino { get; set; }
        public string? LocalAcademia { get; set; }
        public string? Observacoes { get; set; }
    }

    public class StatusAulaDto
    {
        public string Status { get; set; } = "CONCLUIDA";
    }
}
