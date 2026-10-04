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
                    var personal = await con.QueryFirstOrDefaultAsync<dynamic>(
                        "SELECT STATUS, DIA_VENCIMENTO, ULTIMO_PAGAMENTO_MES FROM PERSONAIS WHERE ID = @Id",
                        new { Id = personalId }
                    );

                    if (personal != null)
                    {
                        bool ativo = personal.STATUS != null && (bool)personal.STATUS;
                        int diaVenc = personal.DIA_VENCIMENTO != null ? Convert.ToInt32(personal.DIA_VENCIMENTO) : 10;
                        string? ultimoPagto = (string?)personal.ULTIMO_PAGAMENTO_MES;
                        var mesAtual = DateTime.Now.ToString("yyyy-MM");
                        bool pagoNoMes = (ultimoPagto == mesAtual);
                        int hojeDia = DateTime.Now.Day;
                        bool emAtraso = !pagoNoMes && hojeDia >= diaVenc;
                        int diasAtraso = emAtraso ? (hojeDia - diaVenc) : 0;

                        if (emAtraso && diasAtraso > 5 && ativo)
                        {
                            await con.ExecuteAsync("UPDATE PERSONAIS SET STATUS = 0 WHERE ID = @Id", new { Id = personalId });
                            ativo = false;
                        }

                        if (!ativo)
                        {
                            context.Response.StatusCode = StatusCodes.Status403Forbidden;
                            context.Response.ContentType = "application/json";
                            var json = JsonSerializer.Serialize(new
                            {
                                bloqueadoSaaS = true,
                                mensagem = "🚫 Acesso Suspenso: A assinatura desta consultoria/personal está bloqueada no Coach Center SaaS por inadimplência ou decisão administrativa. Entre em contato com o suporte."
                            });
                            await context.Response.WriteAsync(json);
                            return;
                        }
                    }
                }
            }

            await _next(context);
        }
    }
}
