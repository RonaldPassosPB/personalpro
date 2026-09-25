using System.Security.Claims;

namespace PersonalProAPI.Helpers
{
    public static class UsuarioContexto
    {
        public static int GetUsuarioId(ClaimsPrincipal user)
        {
            var val = user.FindFirst("usuarioId")?.Value
                   ?? user.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            return int.TryParse(val, out var id) ? id : 0;
        }

        public static int GetPerfil(ClaimsPrincipal user)
        {
            var val = user.FindFirst("perfil")?.Value;
            return int.TryParse(val, out var perfil) ? perfil : 2;
        }

        public static int GetPersonalId(ClaimsPrincipal user)
        {
            var val = user.FindFirst("personalId")?.Value;
            return int.TryParse(val, out var pid) ? pid : 0;
        }

        public static string GetNome(ClaimsPrincipal user)
        {
            return user.FindFirst(ClaimTypes.Name)?.Value ?? "Usuário";
        }
    }
}
