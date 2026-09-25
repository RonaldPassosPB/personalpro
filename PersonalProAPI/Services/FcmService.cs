using Dapper;
using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;
using PersonalProAPI.Data;

namespace PersonalProAPI.Services
{
    public class FcmService
    {
        private readonly DbConnection _db;
        private readonly ILogger<FcmService> _logger;
        private readonly bool _inicializado = false;

        public FcmService(DbConnection db, ILogger<FcmService> logger, IWebHostEnvironment env)
        {
            _db = db;
            _logger = logger;

            try
            {
                if (FirebaseApp.DefaultInstance != null)
                {
                    _inicializado = true;
                    return;
                }

                var caminhosPossiveis = new[]
                {
                    Path.Combine(env.ContentRootPath, "firebase-adminsdk.json"),
                    Path.Combine(AppContext.BaseDirectory, "firebase-adminsdk.json"),
                    Path.Combine(Directory.GetCurrentDirectory(), "firebase-adminsdk.json")
                };

                string? caminhoChave = caminhosPossiveis.FirstOrDefault(File.Exists);

                if (caminhoChave != null)
                {
                    FirebaseApp.Create(new AppOptions
                    {
                        Credential = GoogleCredential.FromFile(caminhoChave)
                    });
                    _inicializado = true;
                    _logger.LogInformation("✅ Firebase Admin SDK inicializado no PersonalPro com sucesso.");
                }
                else
                {
                    _logger.LogInformation("ℹ️ 'firebase-adminsdk.json' opcional não encontrado. Notificações In-App ativas no banco SQL.");
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Aviso ao inicializar Firebase Admin SDK.");
            }
        }

        public async Task<bool> EnviarPushUsuarioAsync(
            int usuarioId,
            string titulo,
            string corpo,
            Dictionary<string, string>? dados = null)
        {
            if (!_inicializado) return false;

            try
            {
                using var con = _db.CriarConexao();
                var token = await con.QueryFirstOrDefaultAsync<string?>(
                    "SELECT FCM_TOKEN FROM USUARIOS WHERE ID = @Id AND STATUS = 1",
                    new { Id = usuarioId }
                );

                if (string.IsNullOrWhiteSpace(token))
                    return false;

                var message = new Message
                {
                    Token = token,
                    Notification = new Notification
                    {
                        Title = titulo,
                        Body = corpo
                    },
                    Android = new AndroidConfig
                    {
                        Priority = Priority.High,
                        Notification = new AndroidNotification
                        {
                            Sound = "default",
                            ChannelId = "personalpro_canal_alta_prioridade",
                            Priority = NotificationPriority.HIGH,
                            DefaultSound = true,
                            DefaultVibrateTimings = true
                        }
                    },
                    Data = dados ?? new Dictionary<string, string>()
                };

                await FirebaseMessaging.DefaultInstance.SendAsync(message);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Falha ao enviar push FCM para usuario {Id}", usuarioId);
                return false;
            }
        }
    }
}
