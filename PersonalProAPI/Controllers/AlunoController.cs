using Dapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PersonalProAPI.Data;
using PersonalProAPI.Helpers;
using PersonalProAPI.Services;

namespace PersonalProAPI.Controllers
{
    [ApiController]
    [Route("api/aluno")]
    [Authorize]
    public class AlunoController : ControllerBase
    {
        private readonly DbConnection _db;
        private readonly NotificacaoService _notificacao;

        public AlunoController(DbConnection db, NotificacaoService notificacao)
        {
            _db = db;
            _notificacao = notificacao;
        }

        [HttpGet("home")]
        public async Task<IActionResult> GetHome()
        {
            var usuarioId = UsuarioContexto.GetUsuarioId(User);

            using var con = _db.CriarConexao();

            var aluno = await con.QueryFirstOrDefaultAsync<dynamic>(@"
                SELECT
                    A.ID AS Id,
                    A.USUARIO_ID AS UsuarioId,
                    A.PERSONAL_ID AS PersonalId,
                    U.NOME AS Nome,
                    U.EMAIL AS Email,
                    A.TELEFONE AS Telefone,
                    A.OBJETIVO AS Objetivo,
                    A.FOTO_URL AS FotoUrl,
                    A.VALOR_MENSALIDADE AS ValorMensalidade,
                    A.DIA_VENCIMENTO AS DiaVencimento,
                    P.NOME_PROFISSIONAL AS NomePersonal,
                    P.CREF AS CrefPersonal,
                    P.TELEFONE AS TelefonePersonal,
                    P.CHAVE_PIX AS ChavePixPersonal,
                    P.LOGO_URL AS LogoPersonal
                FROM ALUNOS A
                INNER JOIN USUARIOS U ON U.ID = A.USUARIO_ID
                INNER JOIN PERSONAIS P ON P.ID = A.PERSONAL_ID
                WHERE A.USUARIO_ID = @UsuarioId",
                new { UsuarioId = usuarioId }
            );

            if (aluno == null)
                return NotFound(new { mensagem = "Cadastro de aluno não encontrado." });

            int alunoId = (int)aluno.Id;

            var fichas = (await con.QueryAsync<dynamic>(@"
                SELECT
                    ID AS Id,
                    NOME_DIVISAO AS NomeDivisao,
                    DESCRICAO AS Descricao,
                    ATIVA AS Ativa,
                    DATA_CRIACAO AS DataCriacao,
                    DATA_VALIDADE AS DataValidade
                FROM FICHAS_TREINO
                WHERE ALUNO_ID = @AlunoId AND ATIVA = 1
                ORDER BY NOME_DIVISAO ASC",
                new { AlunoId = alunoId }
            )).ToList();

            var fichasDetalhadas = new List<object>();
            foreach (var f in fichas)
            {
                int fichaId = (int)f.Id;
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

                fichasDetalhadas.Add(new
                {
                    id = fichaId,
                    nomeDivisao = (string)f.NomeDivisao,
                    descricao = (string?)(f.Descricao ?? ""),
                    dataValidade = f.DataValidade,
                    exercicios
                });
            }

            var treinosMes = await con.ExecuteScalarAsync<int>(@"
                SELECT COUNT(1)
                FROM HISTORICO_TREINOS
                WHERE ALUNO_ID = @AlunoId
                  AND MONTH(DATA_HORA) = MONTH(GETDATE())
                  AND YEAR(DATA_HORA) = YEAR(GETDATE())",
                new { AlunoId = alunoId }
            );

            var treinosTotal = await con.ExecuteScalarAsync<int>(
                "SELECT COUNT(1) FROM HISTORICO_TREINOS WHERE ALUNO_ID = @AlunoId",
                new { AlunoId = alunoId }
            );

            return Ok(new
            {
                aluno,
                treinosMes,
                treinosTotal,
                fichas = fichasDetalhadas
            });
        }

        [HttpPut("foto-perfil")]
        public async Task<IActionResult> AtualizarFotoPerfil([FromBody] FotoPerfilDto dto)
        {
            var usuarioId = UsuarioContexto.GetUsuarioId(User);
            using var con = _db.CriarConexao();
            await con.ExecuteAsync(
                "UPDATE ALUNOS SET FOTO_URL = @FotoUrl WHERE USUARIO_ID = @UsuarioId",
                new { dto.FotoUrl, UsuarioId = usuarioId }
            );
            return Ok(new { mensagem = "📸 Foto de perfil atualizada com sucesso!" });
        }

        // ─── ATUALIZAR CARGA (KG) NA EXECUÇÃO DO TREINO + GRAVAR HISTÓRICO DE PROGRESSÃO ───
        [HttpPatch("exercicios/{exercicioId}/carga")]
        public async Task<IActionResult> AtualizarCargaExercicio(int exercicioId, [FromBody] AtualizarCargaDto dto)
        {
            var personalId = UsuarioContexto.GetPersonalId(User);
            using var con = _db.CriarConexao();

            var info = await con.QueryFirstOrDefaultAsync<dynamic>(@"
                SELECT
                    FE.NOME_EXERCICIO AS NomeExercicio,
                    FE.GRUPO_MUSCULAR AS GrupoMuscular,
                    FT.ALUNO_ID AS AlunoId
                FROM FICHA_EXERCICIOS FE
                INNER JOIN FICHAS_TREINO FT ON FT.ID = FE.FICHA_ID
                WHERE FE.ID = @Id AND FT.PERSONAL_ID = @PersonalId",
                new { Id = exercicioId, PersonalId = personalId }
            );

            await con.ExecuteAsync(@"
                UPDATE FE
                SET FE.CARGA_KG = @CargaKg
                FROM FICHA_EXERCICIOS FE
                INNER JOIN FICHAS_TREINO FT ON FT.ID = FE.FICHA_ID
                WHERE FE.ID = @Id AND FT.PERSONAL_ID = @PersonalId",
                new { Id = exercicioId, CargaKg = dto.CargaKg, PersonalId = personalId }
            );

            if (info != null)
            {
                await con.ExecuteAsync(@"
                    INSERT INTO PROGRESSAO_CARGAS (ALUNO_ID, PERSONAL_ID, EXERCICIO_ID, NOME_EXERCICIO, GRUPO_MUSCULAR, CARGA_KG, DATA_REGISTRO)
                    VALUES (@AlunoId, @PersonalId, @ExercicioId, @NomeExercicio, @GrupoMuscular, @CargaKg, GETDATE())",
                    new
                    {
                        AlunoId = (int)info.AlunoId,
                        PersonalId = personalId,
                        ExercicioId = exercicioId,
                        NomeExercicio = (string)info.NomeExercicio,
                        GrupoMuscular = (string?)(info.GrupoMuscular ?? "Geral"),
                        CargaKg = dto.CargaKg
                    }
                );
            }

            return Ok(new { mensagem = $"Carga atualizada para {dto.CargaKg} kg e registrada no gráfico de progressão!" });
        }

        // ─── FINALIZAR TREINO DE HOJE + NOTIFICAR PERSONAL TRAINER ───────────────────
        [HttpPost("finalizar-treino")]
        public async Task<IActionResult> FinalizarTreino([FromBody] FinalizarTreinoDto dto)
        {
            var usuarioId = UsuarioContexto.GetUsuarioId(User);
            var personalId = UsuarioContexto.GetPersonalId(User);

            using var con = _db.CriarConexao();
            var aluno = await con.QueryFirstOrDefaultAsync<dynamic>(@"
                SELECT A.ID AS AlunoId, U.NOME AS NomeAluno
                FROM ALUNOS A
                INNER JOIN USUARIOS U ON U.ID = A.USUARIO_ID
                WHERE A.USUARIO_ID = @UsuarioId",
                new { UsuarioId = usuarioId }
            );

            if (aluno == null)
                return NotFound(new { mensagem = "Aluno não localizado." });

            int alunoId = (int)aluno.AlunoId;
            string nomeAluno = (string)aluno.NomeAluno;
            int duracao = dto.DuracaoMinutos > 0 ? dto.DuracaoMinutos : 45;

            var historicoId = await con.ExecuteScalarAsync<int>(@"
                INSERT INTO HISTORICO_TREINOS (
                    ALUNO_ID, PERSONAL_ID, FICHA_ID, NOME_TREINO,
                    DATA_HORA, DURACAO_MINUTOS, OBSERVACAO_ALUNO
                )
                VALUES (
                    @AlunoId, @PersonalId, @FichaId, @NomeTreino,
                    GETDATE(), @DuracaoMinutos, @ObservacaoAluno
                );
                SELECT CAST(SCOPE_IDENTITY() AS INT);",
                new
                {
                    AlunoId = alunoId,
                    PersonalId = personalId,
                    dto.FichaId,
                    NomeTreino = string.IsNullOrWhiteSpace(dto.NomeTreino) ? "Treino do Dia" : dto.NomeTreino,
                    DuracaoMinutos = duracao,
                    dto.ObservacaoAluno
                }
            );

            var usuarioPersonalId = await con.ExecuteScalarAsync<int?>(
                "SELECT TOP 1 ID FROM USUARIOS WHERE PERSONAL_ID = @PersonalId AND PERFIL = 1",
                new { PersonalId = personalId }
            );

            if (usuarioPersonalId.HasValue)
            {
                await _notificacao.EnviarNotificacaoAsync(
                    personalId,
                    usuarioPersonalId.Value,
                    "💪 Treino Concluído!",
                    $"💪 O aluno {nomeAluno} acabou de concluir o {dto.NomeTreino}! ({duracao} min)",
                    "TREINO_CONCLUIDO"
                );
            }

            return Ok(new
            {
                mensagem = $"Parabéns, {nomeAluno}! Treino registrado no histórico e enviado para seu Personal!",
                historicoId
            });
        }

        [HttpGet("evolucao")]
        public async Task<IActionResult> GetEvolucao()
        {
            var usuarioId = UsuarioContexto.GetUsuarioId(User);
            using var con = _db.CriarConexao();

            var alunoId = await con.ExecuteScalarAsync<int?>(
                "SELECT ID FROM ALUNOS WHERE USUARIO_ID = @UsuarioId",
                new { UsuarioId = usuarioId }
            );
            if (!alunoId.HasValue) return NotFound();

            var avaliacoes = await con.QueryAsync<dynamic>(@"
                SELECT
                    ID AS Id,
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
                WHERE ALUNO_ID = @AlunoId
                ORDER BY DATA_AVALIACAO DESC, ID DESC",
                new { AlunoId = alunoId.Value }
            );

            var historicoTreinos = await con.QueryAsync<dynamic>(@"
                SELECT TOP 30
                    ID AS Id,
                    NOME_TREINO AS NomeTreino,
                    DATA_HORA AS DataHora,
                    DURACAO_MINUTOS AS DuracaoMinutos,
                    OBSERVACAO_ALUNO AS ObservacaoAluno
                FROM HISTORICO_TREINOS
                WHERE ALUNO_ID = @AlunoId
                ORDER BY DATA_HORA DESC",
                new { AlunoId = alunoId.Value }
            );

            var progressaoCargas = await con.QueryAsync<dynamic>(@"
                SELECT
                    ID AS Id,
                    NOME_EXERCICIO AS NomeExercicio,
                    GRUPO_MUSCULAR AS GrupoMuscular,
                    CARGA_KG AS CargaKg,
                    DATA_REGISTRO AS DataRegistro
                FROM PROGRESSAO_CARGAS
                WHERE ALUNO_ID = @AlunoId
                ORDER BY DATA_REGISTRO ASC",
                new { AlunoId = alunoId.Value }
            );

            return Ok(new
            {
                avaliacoes,
                historicoTreinos,
                progressaoCargas
            });
        }

        [HttpGet("financeiro")]
        public async Task<IActionResult> GetFinanceiro()
        {
            var usuarioId = UsuarioContexto.GetUsuarioId(User);
            using var con = _db.CriarConexao();

            var aluno = await con.QueryFirstOrDefaultAsync<dynamic>(@"
                SELECT
                    A.ID AS AlunoId,
                    A.PERSONAL_ID AS PersonalId,
                    P.NOME_PROFISSIONAL AS NomePersonal,
                    P.CHAVE_PIX AS ChavePixPersonal,
                    P.TELEFONE AS TelefonePersonal
                FROM ALUNOS A
                INNER JOIN PERSONAIS P ON P.ID = A.PERSONAL_ID
                WHERE A.USUARIO_ID = @UsuarioId",
                new { UsuarioId = usuarioId }
            );

            if (aluno == null) return NotFound();

            int alunoId = (int)aluno.AlunoId;
            string chavePix = (string?)(aluno.ChavePixPersonal ?? "personal@personalpro.com")!;
            string nomePersonal = (string?)(aluno.NomePersonal ?? "PERSONALPRO")!;

            var pagamentos = (await con.QueryAsync<dynamic>(@"
                SELECT
                    ID AS Id,
                    MES_REFERENCIA AS MesReferencia,
                    VALOR AS Valor,
                    DATA_VENCIMENTO AS DataVencimento,
                    DATA_PAGAMENTO AS DataPagamento,
                    FORMA_PAGAMENTO AS FormaPagamento,
                    STATUS AS Status,
                    OBSERVACAO AS Observacao,
                    PIX_COPIA_E_COLA AS PixCopiaECola
                FROM PAGAMENTOS
                WHERE ALUNO_ID = @AlunoId
                ORDER BY MES_REFERENCIA DESC, ID DESC",
                new { AlunoId = alunoId }
            )).ToList();

            var listaFormatada = pagamentos.Select(p =>
            {
                string pix = p.PixCopiaECola ?? "";
                if (string.IsNullOrWhiteSpace(pix) || pix.Length < 30)
                {
                    pix = PixPayloadService.GerarPayload(
                        chavePix,
                        nomePersonal,
                        "SAO PAULO",
                        (decimal)p.Valor,
                        $"PAG{p.Id}"
                    );
                }

                return new
                {
                    id = (int)p.Id,
                    mesReferencia = (string)p.MesReferencia,
                    valor = (decimal)p.Valor,
                    dataVencimento = p.DataVencimento,
                    dataPagamento = p.DataPagamento,
                    formaPagamento = (string?)(p.FormaPagamento ?? ""),
                    status = (string)p.Status,
                    observacao = (string?)(p.Observacao ?? ""),
                    pixCopiaECola = pix
                };
            });

            return Ok(new
            {
                nomePersonal,
                chavePixPersonal = chavePix,
                telefonePersonal = (string?)(aluno.TelefonePersonal ?? ""),
                pagamentos = listaFormatada
            });
        }

        public class FotoPerfilDto
        {
            public string FotoUrl { get; set; } = string.Empty;
        }

        public class AtualizarCargaDto
        {
            public decimal CargaKg { get; set; }
        }

        public class FinalizarTreinoDto
        {
            public int? FichaId { get; set; }
            public string NomeTreino { get; set; } = string.Empty;
            public int DuracaoMinutos { get; set; } = 45;
            public string? ObservacaoAluno { get; set; }
        }
    }
}
