using System.Security.Claims;
using System.Text;

namespace PersonalProAPI.Services
{
    public class LogService
    {
        private readonly string _diretorioLogs;
        private static readonly SemaphoreSlim _lock = new(1, 1);

        public LogService(IWebHostEnvironment env)
        {
            _diretorioLogs = Path.Combine(env.ContentRootPath, "Logs");
            if (!Directory.Exists(_diretorioLogs))
            {
                Directory.CreateDirectory(_diretorioLogs);
            }
        }

        public async Task<string> GravarErroAsync(Exception ex, HttpContext? context = null)
        {
            var protocolo = $"ERR-{DateTime.Now:yyyyMMdd}-{Guid.NewGuid().ToString("N")[..6].ToUpper()}";
            var dataHora = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");

            var sb = new StringBuilder();
            sb.AppendLine("================================================================================");
            sb.AppendLine($"[DATA/HORA]:   {dataHora}");
            sb.AppendLine($"[PROTOCOLO]:   {protocolo}");
            sb.AppendLine($"[NÍVEL]:       ERROR");

            if (context != null)
            {
                sb.AppendLine($"[ROTA]:        {context.Request.Method} {context.Request.Path}{context.Request.QueryString}");
                sb.AppendLine($"[IP]:          {context.Connection.RemoteIpAddress}");

                if (context.User.Identity?.IsAuthenticated == true)
                {
                    var id = context.User.FindFirst("usuarioId")?.Value ?? "N/A";
                    var personalId = context.User.FindFirst("personalId")?.Value ?? "NULL";
                    var perfil = context.User.FindFirst("perfil")?.Value ?? "N/A";
                    var nome = context.User.FindFirst(ClaimTypes.Name)?.Value ?? "N/A";
                    sb.AppendLine($"[USUÁRIO]:     ID={id} | PersonalId={personalId} | Perfil={perfil} | Nome={nome}");
                }
                else
                {
                    sb.AppendLine($"[USUÁRIO]:     Anônimo (Não autenticado)");
                }
            }

            sb.AppendLine($"[MENSAGEM]:    {ex.Message}");
            sb.AppendLine($"[TIPO ERRO]:   {ex.GetType().FullName}");
            sb.AppendLine("[STACK TRACE]:");
            sb.AppendLine(ex.StackTrace ?? "Sem stack trace disponível.");

            if (ex.InnerException != null)
            {
                sb.AppendLine($"[INNER EXCEPTION]: {ex.InnerException.Message}");
                sb.AppendLine(ex.InnerException.StackTrace ?? "");
            }

            sb.AppendLine("================================================================================");
            sb.AppendLine();

            await GravarEmArquivoAsync(sb.ToString());
            return protocolo;
        }

        public async Task GravarInfoAsync(string mensagem)
        {
            var dataHora = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
            var linha = $"[{dataHora}] [INFO] {mensagem}{Environment.NewLine}";
            await GravarEmArquivoAsync(linha);
        }

        private async Task GravarEmArquivoAsync(string conteudo)
        {
            var nomeArquivo = $"personalpro-{DateTime.Now:yyyy-MM-dd}.log";
            var caminhoArquivo = Path.Combine(_diretorioLogs, nomeArquivo);

            await _lock.WaitAsync();
            try
            {
                await File.AppendAllTextAsync(caminhoArquivo, conteudo, Encoding.UTF8);
            }
            finally
            {
                _lock.Release();
            }
        }

        public async Task<string> ObterConteudoUltimoLogAsync(int maxLinhas = 250)
        {
            if (!Directory.Exists(_diretorioLogs))
                return "Nenhum arquivo de log encontrado.";

            var arquivos = Directory.GetFiles(_diretorioLogs, "personalpro-*.log")
                                    .OrderByDescending(f => f)
                                    .ToList();

            if (!arquivos.Any())
                return "Nenhum log registrado até o momento.";

            await _lock.WaitAsync();
            try
            {
                var linhas = await File.ReadAllLinesAsync(arquivos.First(), Encoding.UTF8);
                return string.Join(Environment.NewLine, linhas.TakeLast(maxLinhas));
            }
            finally
            {
                _lock.Release();
            }
        }
    }
}
