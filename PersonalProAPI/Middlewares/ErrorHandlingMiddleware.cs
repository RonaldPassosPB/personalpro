using PersonalProAPI.Services;
using System.Text.Json;

namespace PersonalProAPI.Middlewares
{
    public class ErrorHandlingMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<ErrorHandlingMiddleware> _logger;

        public ErrorHandlingMiddleware(RequestDelegate next, ILogger<ErrorHandlingMiddleware> logger)
        {
            _next = next;
            _logger = logger;
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
                    mensagem = ex.Message,
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
