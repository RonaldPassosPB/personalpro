using PersonalProAPI.Services;
using System.Text.Json;

namespace PersonalProAPI.Middlewares
{
    public class ErrorHandlingMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<ErrorHandlingMiddleware> _logger;
        private readonly IHostEnvironment _env;

        public ErrorHandlingMiddleware(RequestDelegate next, ILogger<ErrorHandlingMiddleware> logger, IHostEnvironment env)
        {
            _next = next;
            _logger = logger;
            _env = env;
        }

        public async Task InvokeAsync(HttpContext context, LogService logService)
        {
            try
            {
                await _next(context);
            }
            catch (Exception ex)
            {
                var protocolo = await logService.GravarErroAsync(ex, context);
                _logger.LogError(ex, "Erro capturado no middleware [{Protocolo}]: {Mensagem}", protocolo, ex.Message);

                context.Response.ContentType = "application/json";
                context.Response.StatusCode = StatusCodes.Status500InternalServerError;

                var resposta = new
                {
                    erro = "Ocorreu um erro interno ao processar sua requisição.",
                    mensagem = _env.IsDevelopment() ? ex.Message : "Por favor, entre em contato com o suporte informando o protocolo.",
                    protocolo = protocolo,
                    dataHora = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss")
                };

                var json = JsonSerializer.Serialize(resposta, new JsonSerializerOptions
                {
                    PropertyNamingPolicy = JsonNamingPolicy.CamelCase
                });

                await context.Response.WriteAsync(json);
            }
        }
    }
}

