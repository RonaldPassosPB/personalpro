using Dapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PersonalProAPI.Data;
using PersonalProAPI.Helpers;
using PersonalProAPI.Services;

namespace PersonalProAPI.Controllers
{
    [ApiController]
    [Route("api/treinos")]
    [Authorize(Roles = "Personal,SuperAdmin")]
    public class TreinosController : ControllerBase
    {
        private readonly DbConnection _db;
        private readonly NotificacaoService _notificacao;

        public TreinosController(DbConnection db, NotificacaoService notificacao)
        {
            _db = db;
            _notificacao = notificacao;
        }

        // ─── BIBLIOTECA DE EXERCÍCIOS (40 GLOBAIS + CUSTOM DO PERSONAL) ──────────────
        [HttpGet("exercicios-base")]
        public async Task<IActionResult> ListarExerciciosBase([FromQuery] string? grupo = null)
        {
            var personalId = UsuarioContexto.GetPersonalId(User);
            using var con = _db.CriarConexao();

            var sql = @"
                SELECT
                    ID AS Id,
                    PERSONAL_ID AS PersonalId,
                    NOME AS Nome,
                    GRUPO_MUSCULAR AS GrupoMuscular,
                    VIDEO_URL AS VideoUrl
                FROM EXERCICIOS_BASE
                WHERE (PERSONAL_ID IS NULL OR PERSONAL_ID = @PersonalId)";

            if (!string.IsNullOrWhiteSpace(grupo) && grupo != "Todos")
            {
                sql += " AND GRUPO_MUSCULAR = @Grupo";
            }

            sql += " ORDER BY GRUPO_MUSCULAR ASC, NOME ASC";

            var lista = await con.QueryAsync<dynamic>(sql, new { PersonalId = personalId, Grupo = grupo });
            return Ok(lista);
        }

        [HttpPost("exercicios-base")]
        public async Task<IActionResult> CriarExercicioBase([FromBody] NovoExercicioBaseDto dto)
        {
            var personalId = UsuarioContexto.GetPersonalId(User);
            if (string.IsNullOrWhiteSpace(dto.Nome) || string.IsNullOrWhiteSpace(dto.GrupoMuscular))
                return BadRequest(new { mensagem = "Informe o nome do exercício e o grupo muscular." });

            using var con = _db.CriarConexao();
            var id = await con.ExecuteScalarAsync<int>(@"
                INSERT INTO EXERCICIOS_BASE (PERSONAL_ID, NOME, GRUPO_MUSCULAR, VIDEO_URL)
                VALUES (@PersonalId, @Nome, @GrupoMuscular, @VideoUrl);
                SELECT CAST(SCOPE_IDENTITY() AS INT);",
                new { PersonalId = personalId, dto.Nome, dto.GrupoMuscular, dto.VideoUrl }
            );

            return Ok(new { mensagem = "Exercício adicionado à sua biblioteca!", id });
        }

        // ─── FICHAS DE TREINO DO ALUNO (DIVISÕES A, B, C, D, E) ──────────────────────
        [HttpGet("aluno/{alunoId}")]
        public async Task<IActionResult> ObterFichasAluno(int alunoId)
        {
            var personalId = UsuarioContexto.GetPersonalId(User);
            using var con = _db.CriarConexao();

            var fichas = (await con.QueryAsync<dynamic>(@"
                SELECT
                    ID AS Id,
                    ALUNO_ID AS AlunoId,
                    PERSONAL_ID AS PersonalId,
                    NOME_DIVISAO AS NomeDivisao,
                    DESCRICAO AS Descricao,
                    ATIVA AS Ativa,
                    DATA_CRIACAO AS DataCriacao,
                    DATA_VALIDADE AS DataValidade
                FROM FICHAS_TREINO
                WHERE ALUNO_ID = @AlunoId AND PERSONAL_ID = @PersonalId
                ORDER BY NOME_DIVISAO ASC",
                new { AlunoId = alunoId, PersonalId = personalId }
            )).ToList();

            var resultado = new List<object>();
            foreach (var f in fichas)
            {
                int fichaId = Convert.ToInt32(f.Id);
                var exercicios = (await con.QueryAsync<dynamic>(@"
                    SELECT
                        ID AS Id,
                        FICHA_ID AS FichaId,
                        NOME_EXERCICIO AS NomeExercicio,
                        GRUPO_MUSCULAR AS GrupoMuscular,
                        SERIES AS Series,
                        REPETICOES AS Repeticoes,
                        CARGA_KG AS CargaKg,
                        DESCANSO_SEGUNDOS AS DescansoSegundos,
                        OBSERVACAO_TECNICA AS ObservacaoTecnica,
                        VIDEO_URL AS VideoUrl,
                        ORDEM AS Ordem
                    FROM FICHA_EXERCICIOS
                    WHERE FICHA_ID = @FichaId
                    ORDER BY ORDEM ASC, ID ASC",
                    new { FichaId = fichaId }
                )).ToList();

                resultado.Add(new
                {
                    id = fichaId,
                    alunoId = Convert.ToInt32(f.AlunoId),
                    nomeDivisao = (string)f.NomeDivisao,
                    descricao = (string?)(f.Descricao ?? ""),
                    ativa = (bool)f.Ativa,
                    dataCriacao = f.DataCriacao,
                    dataValidade = f.DataValidade,
                    exercicios
                });
            }

            return Ok(resultado);
        }

        [HttpPost("fichas")]
        public async Task<IActionResult> CriarFicha([FromBody] CriarFichaDto dto)
        {
            var personalId = UsuarioContexto.GetPersonalId(User);
            if (dto.AlunoId <= 0 || string.IsNullOrWhiteSpace(dto.NomeDivisao))
                return BadRequest(new { mensagem = "Selecione o aluno e informe o nome da divisão (Ex: Treino A - Peito e Tríceps)." });

            using var con = _db.CriarConexao();
            con.Open();
            using var trans = con.BeginTransaction();
            try
            {
                var fichaId = await con.ExecuteScalarAsync<int>(@"
                    INSERT INTO FICHAS_TREINO (ALUNO_ID, PERSONAL_ID, NOME_DIVISAO, DESCRICAO, ATIVA, DATA_CRIACAO, DATA_VALIDADE)
                    VALUES (@AlunoId, @PersonalId, @NomeDivisao, @Descricao, 1, GETDATE(), DATEADD(MONTH, 2, CAST(GETDATE() AS DATE)));
                    SELECT CAST(SCOPE_IDENTITY() AS INT);",
                    new
                    {
                        dto.AlunoId,
                        PersonalId = personalId,
                        dto.NomeDivisao,
                        dto.Descricao
                    },
                    trans
                );

                if (dto.Exercicios != null && dto.Exercicios.Any())
                {
                    int ordem = 1;
                    foreach (var ex in dto.Exercicios)
                    {
                        await con.ExecuteAsync(@"
                            INSERT INTO FICHA_EXERCICIOS (
                                FICHA_ID, NOME_EXERCICIO, GRUPO_MUSCULAR, SERIES, REPETICOES,
                                CARGA_KG, DESCANSO_SEGUNDOS, OBSERVACAO_TECNICA, VIDEO_URL, ORDEM
                            )
                            VALUES (
                                @FichaId, @NomeExercicio, @GrupoMuscular, @Series, @Repeticoes,
                                @CargaKg, @DescansoSegundos, @ObservacaoTecnica, @VideoUrl, @Ordem
                            );",
                            new
                            {
                                FichaId = fichaId,
                                ex.NomeExercicio,
                                GrupoMuscular = string.IsNullOrWhiteSpace(ex.GrupoMuscular) ? "Geral" : ex.GrupoMuscular,
                                Series = ex.Series > 0 ? ex.Series : 4,
                                Repeticoes = string.IsNullOrWhiteSpace(ex.Repeticoes) ? "10 a 12" : ex.Repeticoes,
                                ex.CargaKg,
                                DescansoSegundos = ex.DescansoSegundos > 0 ? ex.DescansoSegundos : 60,
                                ex.ObservacaoTecnica,
                                ex.VideoUrl,
                                Ordem = ex.Ordem > 0 ? ex.Ordem : ordem++
                            },
                            trans
                        );
                    }
                }

                trans.Commit();

                // Notifica o aluno
                var usuarioAlunoId = await con.ExecuteScalarAsync<int?>(
                    "SELECT USUARIO_ID FROM ALUNOS WHERE ID = @Id",
                    new { Id = dto.AlunoId }
                );
                if (usuarioAlunoId.HasValue)
                {
                    await _notificacao.EnviarNotificacaoAsync(
                        personalId,
                        usuarioAlunoId.Value,
                        "🔥 Nova Ficha de Treino Liberada!",
                        $"Seu Personal prescreveu a ficha '{dto.NomeDivisao}'. Abra o app e confira seus exercícios!",
                        "GERAL"
                    );
                }

                return Ok(new { mensagem = "Ficha de treino criada com sucesso!", fichaId });
            }
            catch
            {
                trans.Rollback();
                throw;
            }
        }

        [HttpPost("fichas/{fichaId}/exercicios")]
        public async Task<IActionResult> AdicionarExercicioNaFicha(int fichaId, [FromBody] ItemExercicioDto ex)
        {
            var personalId = UsuarioContexto.GetPersonalId(User);
            using var con = _db.CriarConexao();

            var pertence = await con.ExecuteScalarAsync<int>(
                "SELECT COUNT(1) FROM FICHAS_TREINO WHERE ID = @FichaId AND PERSONAL_ID = @PersonalId",
                new { FichaId = fichaId, PersonalId = personalId }
            );
            if (pertence == 0) return Forbid();

            var maxOrdem = await con.ExecuteScalarAsync<int>(
                "SELECT ISNULL(MAX(ORDEM), 0) FROM FICHA_EXERCICIOS WHERE FICHA_ID = @FichaId",
                new { FichaId = fichaId }
            );

            var id = await con.ExecuteScalarAsync<int>(@"
                INSERT INTO FICHA_EXERCICIOS (
                    FICHA_ID, NOME_EXERCICIO, GRUPO_MUSCULAR, SERIES, REPETICOES,
                    CARGA_KG, DESCANSO_SEGUNDOS, OBSERVACAO_TECNICA, VIDEO_URL, ORDEM
                )
                VALUES (
                    @FichaId, @NomeExercicio, @GrupoMuscular, @Series, @Repeticoes,
                    @CargaKg, @DescansoSegundos, @ObservacaoTecnica, @VideoUrl, @Ordem
                );
                SELECT CAST(SCOPE_IDENTITY() AS INT);",
                new
                {
                    FichaId = fichaId,
                    ex.NomeExercicio,
                    GrupoMuscular = string.IsNullOrWhiteSpace(ex.GrupoMuscular) ? "Geral" : ex.GrupoMuscular,
                    Series = ex.Series > 0 ? ex.Series : 4,
                    Repeticoes = string.IsNullOrWhiteSpace(ex.Repeticoes) ? "10 a 12" : ex.Repeticoes,
                    ex.CargaKg,
                    DescansoSegundos = ex.DescansoSegundos > 0 ? ex.DescansoSegundos : 60,
                    ex.ObservacaoTecnica,
                    ex.VideoUrl,
                    Ordem = maxOrdem + 1
                }
            );

            return Ok(new { mensagem = "Exercício adicionado à ficha!", id });
        }

        [HttpPut("exercicios/{exercicioId}")]
        public async Task<IActionResult> EditarExercicioDaFicha(int exercicioId, [FromBody] ItemExercicioDto ex)
        {
            var personalId = UsuarioContexto.GetPersonalId(User);
            using var con = _db.CriarConexao();

            await con.ExecuteAsync(@"
                UPDATE FE
                SET FE.NOME_EXERCICIO = @NomeExercicio,
                    FE.GRUPO_MUSCULAR = @GrupoMuscular,
                    FE.SERIES = @Series,
                    FE.REPETICOES = @Repeticoes,
                    FE.CARGA_KG = @CargaKg,
                    FE.DESCANSO_SEGUNDOS = @DescansoSegundos,
                    FE.OBSERVACAO_TECNICA = @ObservacaoTecnica,
                    FE.VIDEO_URL = @VideoUrl
                FROM FICHA_EXERCICIOS FE
                INNER JOIN FICHAS_TREINO FT ON FT.ID = FE.FICHA_ID
                WHERE FE.ID = @Id AND FT.PERSONAL_ID = @PersonalId",
                new
                {
                    Id = exercicioId,
                    PersonalId = personalId,
                    ex.NomeExercicio,
                    ex.GrupoMuscular,
                    ex.Series,
                    ex.Repeticoes,
                    ex.CargaKg,
                    ex.DescansoSegundos,
                    ex.ObservacaoTecnica,
                    ex.VideoUrl
                }
            );

            return Ok(new { mensagem = "Exercício atualizado!" });
        }

        [HttpDelete("exercicios/{exercicioId}")]
        public async Task<IActionResult> RemoverExercicioDaFicha(int exercicioId)
        {
            var personalId = UsuarioContexto.GetPersonalId(User);
            using var con = _db.CriarConexao();
            await con.ExecuteAsync(@"
                DELETE FE
                FROM FICHA_EXERCICIOS FE
                INNER JOIN FICHAS_TREINO FT ON FT.ID = FE.FICHA_ID
                WHERE FE.ID = @Id AND FT.PERSONAL_ID = @PersonalId",
                new { Id = exercicioId, PersonalId = personalId }
            );
            return Ok(new { mensagem = "Exercício removido da ficha." });
        }

        [HttpDelete("fichas/{fichaId}")]
        public async Task<IActionResult> ExcluirFicha(int fichaId)
        {
            var personalId = UsuarioContexto.GetPersonalId(User);
            using var con = _db.CriarConexao();
            await con.ExecuteAsync(
                "DELETE FROM FICHAS_TREINO WHERE ID = @Id AND PERSONAL_ID = @PersonalId",
                new { Id = fichaId, PersonalId = personalId }
            );
            return Ok(new { mensagem = "Ficha de treino excluída com sucesso." });
        }

        // ─── DUPLICAR / COPIAR FICHA DE TREINO PARA OUTRO ALUNO ─────────────────────
        [HttpPost("fichas/{fichaId}/duplicar")]
        public async Task<IActionResult> DuplicarFichaParaOutroAluno(int fichaId, [FromBody] DuplicarFichaDto dto)
        {
            var personalId = UsuarioContexto.GetPersonalId(User);
            using var con = _db.CriarConexao();
            con.Open();

            var fichaOriginal = await con.QueryFirstOrDefaultAsync<dynamic>(
                "SELECT ID, NOME_DIVISAO AS NomeDivisao, DESCRICAO AS Descricao FROM FICHAS_TREINO WHERE ID = @Id AND PERSONAL_ID = @PersonalId",
                new { Id = fichaId, PersonalId = personalId }
            );

            if (fichaOriginal == null)
                return NotFound(new { mensagem = "Ficha original não encontrada." });

            var exerciciosOriginais = (await con.QueryAsync<dynamic>(
                "SELECT * FROM FICHA_EXERCICIOS WHERE FICHA_ID = @FichaId ORDER BY ORDEM ASC",
                new { FichaId = fichaId }
            )).ToList();

            using var trans = con.BeginTransaction();
            try
            {
                var novoNome = string.IsNullOrWhiteSpace(dto.NovoNomeDivisao)
                    ? (string)fichaOriginal.NomeDivisao
                    : dto.NovoNomeDivisao;

                var novaFichaId = await con.ExecuteScalarAsync<int>(@"
                    INSERT INTO FICHAS_TREINO (ALUNO_ID, PERSONAL_ID, NOME_DIVISAO, DESCRICAO, ATIVA, DATA_CRIACAO, DATA_VALIDADE)
                    VALUES (@AlunoDestinoId, @PersonalId, @NomeDivisao, @Descricao, 1, GETDATE(), DATEADD(MONTH, 2, CAST(GETDATE() AS DATE)));
                    SELECT CAST(SCOPE_IDENTITY() AS INT);",
                    new
                    {
                        dto.AlunoDestinoId,
                        PersonalId = personalId,
                        NomeDivisao = novoNome,
                        Descricao = (string?)fichaOriginal.Descricao
                    },
                    trans
                );

                foreach (var ex in exerciciosOriginais)
                {
                    await con.ExecuteAsync(@"
                        INSERT INTO FICHA_EXERCICIOS (
                            FICHA_ID, NOME_EXERCICIO, GRUPO_MUSCULAR, SERIES, REPETICOES,
                            CARGA_KG, DESCANSO_SEGUNDOS, OBSERVACAO_TECNICA, VIDEO_URL, ORDEM
                        )
                        VALUES (
                            @FichaId, @Nome, @Grupo, @Series, @Repeticoes,
                            @Carga, @Descanso, @Obs, @Video, @Ordem
                        );",
                        new
                        {
                            FichaId = novaFichaId,
                            Nome = (string)ex.NOME_EXERCICIO,
                            Grupo = (string)ex.GRUPO_MUSCULAR,
                            Series = (int)ex.SERIES,
                            Repeticoes = (string)ex.REPETICOES,
                            Carga = (decimal)ex.CARGA_KG,
                            Descanso = (int)ex.DESCANSO_SEGUNDOS,
                            Obs = (string?)ex.OBSERVACAO_TECNICA,
                            Video = (string?)ex.VIDEO_URL,
                            Ordem = (int)ex.ORDEM
                        },
                        trans
                    );
                }

                trans.Commit();
                return Ok(new { mensagem = $"📋 Ficha '{novoNome}' duplicada com sucesso para o aluno selecionado!", novaFichaId });
            }
            catch
            {
                trans.Rollback();
                throw;
            }
        }

        [HttpPatch("exercicios/{id}/video")]
        public async Task<IActionResult> AtualizarVideoExercicio(int id, [FromBody] AtualizarVideoDto dto)
        {
            var personalId = UsuarioContexto.GetPersonalId(User);
            using var con = _db.CriarConexao();

            var ex = await con.QueryFirstOrDefaultAsync<dynamic>(@"
                SELECT FE.ID, FE.NOME_EXERCICIO
                FROM FICHA_EXERCICIOS FE
                INNER JOIN FICHAS_TREINO FT ON FT.ID = FE.FICHA_ID
                WHERE FE.ID = @Id AND FT.PERSONAL_ID = @PersonalId",
                new { Id = id, PersonalId = personalId }
            );
            if (ex == null) return NotFound();

            await con.ExecuteAsync(
                "UPDATE FICHA_EXERCICIOS SET VIDEO_URL = @VideoUrl WHERE ID = @Id",
                new { dto.VideoUrl, Id = id }
            );

            await con.ExecuteAsync(
                "UPDATE EXERCICIOS_BASE SET VIDEO_URL = @VideoUrl WHERE NOME = @Nome",
                new { dto.VideoUrl, Nome = (string)ex.NOME_EXERCICIO }
            );

            return Ok(new { mensagem = "Vídeo do exercício atualizado com sucesso!" });
        }

        public class AtualizarVideoDto
        {
            public string? VideoUrl { get; set; }
        }

        public class NovoExercicioBaseDto
        {
            public string Nome { get; set; } = string.Empty;
            public string GrupoMuscular { get; set; } = string.Empty;
            public string? VideoUrl { get; set; }
        }

        public class CriarFichaDto
        {
            public int AlunoId { get; set; }
            public string NomeDivisao { get; set; } = string.Empty;
            public string? Descricao { get; set; }
            public List<ItemExercicioDto>? Exercicios { get; set; }
        }

        public class ItemExercicioDto
        {
            public string NomeExercicio { get; set; } = string.Empty;
            public string GrupoMuscular { get; set; } = "Peito";
            public int Series { get; set; } = 4;
            public string Repeticoes { get; set; } = "10 a 12";
            public decimal CargaKg { get; set; } = 0;
            public int DescansoSegundos { get; set; } = 60;
            public string? ObservacaoTecnica { get; set; }
            public string? VideoUrl { get; set; }
            public int Ordem { get; set; } = 1;
        }

        public class DuplicarFichaDto
        {
            public int AlunoDestinoId { get; set; }
            public string? NovoNomeDivisao { get; set; }
        }
    }
}
