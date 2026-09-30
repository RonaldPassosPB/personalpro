using Dapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PersonalProAPI.Data;
using PersonalProAPI.Helpers;

namespace PersonalProAPI.Controllers
{
    [ApiController]
    [Authorize]
    public class DietaAgendaController : ControllerBase
    {
        private readonly DbConnection _db;

        public DietaAgendaController(DbConnection db)
        {
            _db = db;
        }

        // ==========================================
        // ROTAS DE DIETA & NUTRIÇÃO
        // ==========================================

        [HttpGet("api/dieta/aluno/{alunoId}")]
        public async Task<IActionResult> ObterDietaAluno(int alunoId)
        {
            var tenantId = UsuarioContexto.GetTenantId(User);
            using var con = _db.CriarConexao();

            var plano = await con.QueryFirstOrDefaultAsync<dynamic>(@"
                SELECT TOP 1
                    ID AS id,
                    TITULO AS titulo,
                    OBJETIVO AS objetivo,
                    PESO_BASE_KG AS pesoBaseKg,
                    ALTURA_CM AS alturaCm,
                    IDADE AS idade,
                    SEXO AS sexo,
                    FATOR_ATIVIDADE AS fatorAtividade,
                    TMB_KCAL AS tmbKcal,
                    GET_KCAL AS getKcal,
                    META_KCAL AS metaKcal,
                    PROTEINA_G AS proteinaG,
                    CARBOIDRATO_G AS carboidratoG,
                    GORDURA_G AS gorduraG,
                    AGUA_LITROS AS aguaLitros,
                    OBSERVACOES AS observacoes,
                    DATA_CRIACAO AS dataCriacao
                FROM PLANOS_ALIMENTARES
                WHERE ALUNO_ID = @AlunoId AND TENANT_ID = @TenantId AND ATIVO = 1
                ORDER BY ID DESC",
                new { AlunoId = alunoId, TenantId = tenantId }
            );

            if (plano == null)
            {
                return Ok(new { plano = (object?)null, refeicoes = new List<object>() });
            }

            int planoId = (int)plano.id;
            var refeicoes = (await con.QueryAsync<dynamic>(@"
                SELECT
                    ID AS id,
                    HORARIO AS horario,
                    NOME_REFEICAO AS nomeRefeicao,
                    ALIMENTOS_DESCRICAO AS alimentosDescricao,
                    SUBSTITUICOES AS substituicoes,
                    KCAL_ESTIMADA AS kcalEstimada,
                    PROTEINA_G AS proteinaG,
                    CARBO_G AS carboG,
                    GORDURA_G AS gorduraG,
                    ORDEM AS ordem
                FROM REFEICOES_PLANO
                WHERE PLANO_ID = @PlanoId
                ORDER BY ORDEM ASC, ID ASC",
                new { PlanoId = planoId }
            )).ToList();

            return Ok(new { plano, refeicoes });
        }

        [HttpGet("api/dieta/minha-dieta")]
        public async Task<IActionResult> ObterMinhaDieta()
        {
            var usuarioId = UsuarioContexto.GetUsuarioId(User);
            var tenantId = UsuarioContexto.GetTenantId(User);
            using var con = _db.CriarConexao();

            var alunoId = await con.ExecuteScalarAsync<int?>(
                "SELECT ID FROM ALUNOS WHERE USUARIO_ID = @UsuarioId",
                new { UsuarioId = usuarioId }
            );

            if (alunoId == null)
                return Ok(new { plano = (object?)null, refeicoes = new List<object>() });

            return await ObterDietaAluno(alunoId.Value);
        }

        [HttpPost("api/dieta/salvar")]
        public async Task<IActionResult> SalvarPlano([FromBody] SalvarDietaRequest req)
        {
            var tenantId = UsuarioContexto.GetTenantId(User);
            var personalId = UsuarioContexto.GetPersonalId(User);
            using var con = _db.CriarConexao();

            // Desativar planos anteriores do aluno
            await con.ExecuteAsync(
                "UPDATE PLANOS_ALIMENTARES SET ATIVO = 0 WHERE ALUNO_ID = @AlunoId AND TENANT_ID = @TenantId",
                new { AlunoId = req.AlunoId, TenantId = tenantId }
            );

            var sqlInsertPlano = @"
                INSERT INTO PLANOS_ALIMENTARES (
                    TENANT_ID, PERSONAL_ID, ALUNO_ID, TITULO, OBJETIVO,
                    PESO_BASE_KG, ALTURA_CM, IDADE, SEXO, FATOR_ATIVIDADE,
                    TMB_KCAL, GET_KCAL, META_KCAL, PROTEINA_G, CARBOIDRATO_G,
                    GORDURA_G, AGUA_LITROS, OBSERVACOES
                )
                VALUES (
                    @TenantId, @PersonalId, @AlunoId, @Titulo, @Objetivo,
                    @PesoBaseKg, @AlturaCm, @Idade, @Sexo, @FatorAtividade,
                    @TmbKcal, @GetKcal, @MetaKcal, @ProteinaG, @CarboidratoG,
                    @GorduraG, @AguaLitros, @Observacoes
                );
                SELECT CAST(SCOPE_IDENTITY() as int);";

            var planoId = await con.ExecuteScalarAsync<int>(sqlInsertPlano, new
            {
                TenantId = tenantId,
                PersonalId = personalId > 0 ? personalId : 1,
                AlunoId = req.AlunoId,
                Titulo = string.IsNullOrWhiteSpace(req.Titulo) ? "Plano Alimentar Prescrito" : req.Titulo,
                Objetivo = req.Objetivo ?? "Hipertrofia",
                PesoBaseKg = req.PesoBaseKg,
                AlturaCm = req.AlturaCm,
                Idade = req.Idade,
                Sexo = req.Sexo ?? "M",
                FatorAtividade = req.FatorAtividade,
                TmbKcal = req.TmbKcal,
                GetKcal = req.GetKcal,
                MetaKcal = req.MetaKcal,
                ProteinaG = req.ProteinaG,
                CarboidratoG = req.CarboidratoG,
                GorduraG = req.GorduraG,
                AguaLitros = req.AguaLitros,
                Observacoes = req.Observacoes ?? ""
            });

            if (req.Refeicoes != null && req.Refeicoes.Any())
            {
                int ordem = 1;
                foreach (var r in req.Refeicoes)
                {
                    await con.ExecuteAsync(@"
                        INSERT INTO REFEICOES_PLANO (
                            PLANO_ID, HORARIO, NOME_REFEICAO, ALIMENTOS_DESCRICAO,
                            SUBSTITUICOES, KCAL_ESTIMADA, PROTEINA_G, CARBO_G, GORDURA_G, ORDEM
                        )
                        VALUES (
                            @PlanoId, @Horario, @NomeRefeicao, @AlimentosDescricao,
                            @Substituicoes, @KcalEstimada, @ProteinaG, @CarboG, @GorduraG, @Ordem
                        )",
                        new
                        {
                            PlanoId = planoId,
                            Horario = r.Horario ?? "12:00",
                            NomeRefeicao = r.NomeRefeicao ?? "Refeição",
                            AlimentosDescricao = r.AlimentosDescricao ?? "",
                            Substituicoes = r.Substituicoes ?? "",
                            KcalEstimada = r.KcalEstimada,
                            ProteinaG = r.ProteinaG,
                            CarboG = r.CarboG,
                            GorduraG = r.GorduraG,
                            Ordem = ordem++
                        }
                    );
                }
            }

            return Ok(new { mensagem = "Plano alimentar e macronutrientes salvos com sucesso!", planoId });
        }

        // ==========================================
        // ROTAS DE AGENDA DE AULAS & CONSULTORIAS
        // ==========================================

        [HttpGet("api/agenda/personal")]
        public async Task<IActionResult> ObterAgendaPersonal()
        {
            var personalId = UsuarioContexto.GetPersonalId(User);
            var tenantId = UsuarioContexto.GetTenantId(User);
            using var con = _db.CriarConexao();

            var aulas = (await con.QueryAsync<dynamic>(@"
                SELECT
                    AG.ID AS id,
                    AG.ALUNO_ID AS alunoId,
                    U.NOME AS nomeAluno,
                    AG.DATA_HORA_INICIO AS dataHoraInicio,
                    AG.DURACAO_MINUTOS AS duracaoMinutos,
                    AG.TIPO_AULA AS tipoAula,
                    AG.TITULO_TREINO AS tituloTreino,
                    AG.LOCAL_ACADEMIA AS localAcademia,
                    AG.STATUS AS status
                FROM AGENDA_AULAS AG
                INNER JOIN ALUNOS A ON A.ID = AG.ALUNO_ID
                INNER JOIN USUARIOS U ON U.ID = A.USUARIO_ID
                WHERE AG.TENANT_ID = @TenantId AND (AG.PERSONAL_ID = @PersonalId OR @PersonalId <= 0)
                ORDER BY AG.DATA_HORA_INICIO DESC",
                new { PersonalId = personalId, TenantId = tenantId }
            )).ToList();

            var totalAgendadas = aulas.Count(a => (string)a.status == "AGENDADA" || (string)a.status == "CONFIRMADA");
            var concluidasMes = aulas.Count(a => (string)a.status == "CONCLUIDA");

            return Ok(new
            {
                resumo = new
                {
                    totalAgendadas,
                    concluidasMes,
                    totalGeral = aulas.Count
                },
                aulas
            });
        }

        [HttpGet("api/agenda/minhas-aulas")]
        public async Task<IActionResult> ObterMinhasAulas()
        {
            var usuarioId = UsuarioContexto.GetUsuarioId(User);
            var tenantId = UsuarioContexto.GetTenantId(User);
            using var con = _db.CriarConexao();

            var alunoId = await con.ExecuteScalarAsync<int?>(
                "SELECT ID FROM ALUNOS WHERE USUARIO_ID = @UsuarioId",
                new { UsuarioId = usuarioId }
            );

            if (alunoId == null)
                return Ok(new List<object>());

            var aulas = (await con.QueryAsync<dynamic>(@"
                SELECT
                    AG.ID AS id,
                    AG.DATA_HORA_INICIO AS dataHoraInicio,
                    AG.DURACAO_MINUTOS AS duracaoMinutos,
                    AG.TIPO_AULA AS tipoAula,
                    AG.TITULO_TREINO AS tituloTreino,
                    AG.LOCAL_ACADEMIA AS localAcademia,
                    AG.STATUS AS status
                FROM AGENDA_AULAS AG
                WHERE AG.ALUNO_ID = @AlunoId AND AG.TENANT_ID = @TenantId
                ORDER BY AG.DATA_HORA_INICIO ASC",
                new { AlunoId = alunoId.Value, TenantId = tenantId }
            )).ToList();

            return Ok(aulas);
        }

        [HttpPost("api/agenda")]
        public async Task<IActionResult> CriarAgendamento([FromBody] CriarAgendamentoRequest req)
        {
            var personalId = UsuarioContexto.GetPersonalId(User);
            var tenantId = UsuarioContexto.GetTenantId(User);
            using var con = _db.CriarConexao();

            var sql = @"
                INSERT INTO AGENDA_AULAS (
                    TENANT_ID, PERSONAL_ID, ALUNO_ID, DATA_HORA_INICIO,
                    DURACAO_MINUTOS, TIPO_AULA, TITULO_TREINO, LOCAL_ACADEMIA, STATUS
                )
                VALUES (
                    @TenantId, @PersonalId, @AlunoId, @DataHoraInicio,
                    @DuracaoMinutos, @TipoAula, @TituloTreino, @LocalAcademia, 'CONFIRMADA'
                );
                SELECT CAST(SCOPE_IDENTITY() as int);";

            var id = await con.ExecuteScalarAsync<int>(sql, new
            {
                TenantId = tenantId,
                PersonalId = personalId > 0 ? personalId : 1,
                AlunoId = req.AlunoId,
                DataHoraInicio = req.DataHoraInicio,
                DuracaoMinutos = req.DuracaoMinutos > 0 ? req.DuracaoMinutos : 60,
                TipoAula = req.TipoAula ?? "PRESENCIAL",
                TituloTreino = req.TituloTreino ?? "Acompanhamento de Treino",
                LocalAcademia = req.LocalAcademia ?? "Academia"
            });

            return Ok(new { mensagem = "Aula agendada com sucesso!", id });
        }

        [HttpPatch("api/agenda/{id}/status")]
        public async Task<IActionResult> AtualizarStatusAula(int id, [FromBody] AtualizarStatusRequest req)
        {
            var tenantId = UsuarioContexto.GetTenantId(User);
            using var con = _db.CriarConexao();

            await con.ExecuteAsync(@"
                UPDATE AGENDA_AULAS
                SET STATUS = @Status
                WHERE ID = @Id AND TENANT_ID = @TenantId",
                new { Id = id, Status = req.Status ?? "CONCLUIDA", TenantId = tenantId }
            );

            return Ok(new { mensagem = "Status da aula atualizado com sucesso!" });
        }
    }

    public class SalvarDietaRequest
    {
        public int AlunoId { get; set; }
        public string? Titulo { get; set; }
        public string? Objetivo { get; set; }
        public decimal PesoBaseKg { get; set; }
        public decimal AlturaCm { get; set; }
        public int Idade { get; set; }
        public string? Sexo { get; set; }
        public decimal FatorAtividade { get; set; }
        public int TmbKcal { get; set; }
        public int GetKcal { get; set; }
        public int MetaKcal { get; set; }
        public int ProteinaG { get; set; }
        public int CarboidratoG { get; set; }
        public int GorduraG { get; set; }
        public decimal AguaLitros { get; set; }
        public string? Observacoes { get; set; }
        public List<RefeicaoDto>? Refeicoes { get; set; }
    }

    public class RefeicaoDto
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

    public class CriarAgendamentoRequest
    {
        public int AlunoId { get; set; }
        public DateTime DataHoraInicio { get; set; }
        public int DuracaoMinutos { get; set; }
        public string? TipoAula { get; set; }
        public string? TituloTreino { get; set; }
        public string? LocalAcademia { get; set; }
    }

    public class AtualizarStatusRequest
    {
        public string? Status { get; set; }
    }
}
