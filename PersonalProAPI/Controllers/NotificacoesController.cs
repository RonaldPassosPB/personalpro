using Dapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PersonalProAPI.Data;
using PersonalProAPI.Helpers;

namespace PersonalProAPI.Controllers
{
    [ApiController]
    [Route("api/notificacoes")]
    [Authorize]
    public class NotificacoesController : ControllerBase
    {
        private readonly DbConnection _db;

        public NotificacoesController(DbConnection db)
        {
            _db = db;
        }

        [HttpGet]
        public async Task<IActionResult> Listar()
        {
            var usuarioId = UsuarioContexto.GetUsuarioId(User);
            using var con = _db.CriarConexao();

            var lista = (await con.QueryAsync<dynamic>(@"
                SELECT TOP 40
                    ID AS Id,
                    TITULO AS Titulo,
                    MENSAGEM AS Mensagem,
                    TIPO AS Tipo,
                    LIDA AS Lida,
                    DATA_CRIACAO AS DataCriacao
                FROM NOTIFICACOES
                WHERE USUARIO_ID = @UsuarioId
                ORDER BY DATA_CRIACAO DESC",
                new { UsuarioId = usuarioId }
            )).ToList();

            var naoLidas = lista.Count(n => !(bool)n.Lida);

            return Ok(new
            {
                naoLidas,
                notificacoes = lista
            });
        }

        [HttpPost("ler-todas")]
        public async Task<IActionResult> MarcarTodasComoLidas()
        {
            var usuarioId = UsuarioContexto.GetUsuarioId(User);
            using var con = _db.CriarConexao();
            await con.ExecuteAsync(
                "UPDATE NOTIFICACOES SET LIDA = 1 WHERE USUARIO_ID = @UsuarioId",
                new { UsuarioId = usuarioId }
            );
            return Ok(new { mensagem = "Notificações marcadas como lidas." });
        }
    }
}
