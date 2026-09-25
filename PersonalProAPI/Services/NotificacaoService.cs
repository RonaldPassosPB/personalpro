using Dapper;
using PersonalProAPI.Data;

namespace PersonalProAPI.Services
{
    public class NotificacaoService
    {
        private readonly DbConnection _db;
        private readonly FcmService _fcm;

        public NotificacaoService(DbConnection db, FcmService fcm)
        {
            _db = db;
            _fcm = fcm;
        }

        public async Task EnviarNotificacaoAsync(
            int? personalId,
            int usuarioDestinoId,
            string titulo,
            string mensagem,
            string tipo = "GERAL")
        {
            using var con = _db.CriarConexao();
            await con.ExecuteAsync(@"
                INSERT INTO NOTIFICACOES (PERSONAL_ID, USUARIO_ID, TITULO, MENSAGEM, TIPO, LIDA, DATA_CRIACAO)
                VALUES (@PersonalId, @UsuarioId, @Titulo, @Mensagem, @Tipo, 0, GETDATE())",
                new
                {
                    PersonalId = personalId,
                    UsuarioId = usuarioDestinoId,
                    Titulo = titulo,
                    Mensagem = mensagem,
                    Tipo = tipo
                });

            await _fcm.EnviarPushUsuarioAsync(usuarioDestinoId, titulo, mensagem, new Dictionary<string, string>
            {
                { "tipo", tipo },
                { "personalId", (personalId ?? 0).ToString() }
            });
        }
    }
}
