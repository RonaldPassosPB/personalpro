using Dapper;
using PersonalProAPI.Data;
using PersonalProAPI.Helpers;
using System.Text.Json;

namespace PersonalProAPI.Middlewares
{
    public class TenantKillSwitchMiddleware
    {
        private readonly RequestDelegate _next;

        public TenantKillSwitchMiddleware(RequestDelegate next)
        {
            _next = next;
        }

        public async Task InvokeAsync(HttpContext context, DbConnection db)
        {
            if (context.User.Identity?.IsAuthenticated == true)
            {
                var perfil = UsuarioContexto.GetPerfil(context.User);
                var personalId = UsuarioContexto.GetPersonalId(context.User);

                // Se for Personal (1) ou Aluno (2), valida se o Tenant (PERSONAIS) está ativo (STATUS = 1)
                if (perfil != 3 && personalId > 0)
                {
                    using var con = db.CriarConexao();
                    var ativo = await con.ExecuteScalarAsync<bool?>(
                        "SELECT STATUS FROM PERSONAIS WHERE ID = @Id",
                        new { Id = personalId }
                    );

                    if (ativo == false)
                    {
                        context.Response.StatusCode = StatusCodes.Status403Forbidden;
                        context.Response.ContentType = "application/json";
                        var json = JsonSerializer.Serialize(new
                        {
                            bloqueadoSaaS = true,
                            mensagem = "🚫 Acesso Suspenso: A assinatura desta consultoria/personal está temporariamente bloqueada no PersonalPro SaaS. Entre em contato com o administrador."
                        });
                        await context.Response.WriteAsync(json);
                        return;
                    }
                }
            }

            await _next(context);
        }
    }
}
