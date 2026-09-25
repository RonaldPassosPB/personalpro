using Dapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using PersonalProAPI.Data;
using PersonalProAPI.Helpers;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace PersonalProAPI.Controllers
{
    [ApiController]
    [Route("api/auth")]
    public class AuthController : ControllerBase
    {
        private readonly DbConnection _db;
        private readonly IConfiguration _config;

        public AuthController(DbConnection db, IConfiguration config)
        {
            _db = db;
            _config = config;
        }

        [HttpPost("login")]
        [AllowAnonymous]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Senha))
                return BadRequest(new { mensagem = "Informe seu e-mail e senha." });

            using var con = _db.CriarConexao();

            var usuario = await con.QueryFirstOrDefaultAsync<dynamic>(@"
                SELECT
                    U.ID AS Id,
                    U.NOME AS Nome,
                    U.EMAIL AS Email,
                    U.SENHA_HASH AS SenhaHash,
                    U.PERFIL AS Perfil,
                    U.STATUS AS Status,
                    ISNULL(U.PERSONAL_ID, 0) AS PersonalId,
                    P.NOME_PROFISSIONAL AS NomePersonal,
                    P.STATUS AS PersonalStatus,
                    P.PLANO AS PlanoPersonal,
                    A.ID AS AlunoId
                FROM USUARIOS U
                LEFT JOIN PERSONAIS P ON P.ID = U.PERSONAL_ID
                LEFT JOIN ALUNOS A ON A.USUARIO_ID = U.ID
                WHERE U.EMAIL = @Email",
                new { Email = request.Email.Trim() }
            );

            if (usuario == null)
                return Unauthorized(new { mensagem = "E-mail ou senha incorretos." });

            string senhaHash = usuario.SenhaHash ?? "";
            if (!BCrypt.Net.BCrypt.Verify(request.Senha, senhaHash))
                return Unauthorized(new { mensagem = "E-mail ou senha incorretos." });

            bool usuarioAtivo = usuario.Status != null && (bool)usuario.Status;
            if (!usuarioAtivo)
                return Unauthorized(new { mensagem = "Seu cadastro de usuário encontra-se inativo. Procure seu Personal Trainer." });

            int perfil = Convert.ToInt32(usuario.Perfil);
            int personalId = Convert.ToInt32(usuario.PersonalId);

            // KILL-SWITCH MULTI-TENANT: Se o Personal estiver bloqueado (STATUS = 0), bloqueia tanto o Personal quanto TODOS os alunos dele!
            if (perfil != 3 && personalId > 0)
            {
                bool personalAtivo = usuario.PersonalStatus != null && (bool)usuario.PersonalStatus;
                if (!personalAtivo)
                {
                    return StatusCode(403, new
                    {
                        bloqueadoSaaS = true,
                        mensagem = perfil == 1
                            ? "🚫 Acesso Suspenso: Sua assinatura no PersonalPro SaaS encontra-se bloqueada por pendência financeira. Regularize com o suporte para liberar seu painel e o app dos seus alunos."
                            : "🚫 Acesso Temporariamente Suspenso: O acesso da consultoria do seu Personal Trainer encontra-se suspenso no sistema. Entre em contato com seu professor."
                    });
                }
            }

            var token = GerarJwtToken(
                usuarioId: Convert.ToInt32(usuario.Id),
                nome: (string)usuario.Nome,
                email: (string)usuario.Email,
                perfil: perfil,
                personalId: personalId
            );

            return Ok(new
            {
                token,
                usuarioId = Convert.ToInt32(usuario.Id),
                alunoId = usuario.AlunoId != null ? (int?)Convert.ToInt32(usuario.AlunoId) : null,
                personalId = personalId > 0 ? (int?)personalId : null,
                nome = (string)usuario.Nome,
                email = (string)usuario.Email,
                perfil,
                nomePersonal = (string?)(usuario.NomePersonal ?? "PersonalPro SaaS"),
                plano = (string?)(usuario.PlanoPersonal ?? "MASTER")
            });
        }

        [HttpPost("fcm-token")]
        [Authorize]
        public async Task<IActionResult> SalvarFcmToken([FromBody] FcmTokenDto dto)
        {
            var usuarioId = UsuarioContexto.GetUsuarioId(User);
            using var con = _db.CriarConexao();
            await con.ExecuteAsync(
                "UPDATE USUARIOS SET FCM_TOKEN = @Token WHERE ID = @Id",
                new { Token = dto.Token, Id = usuarioId }
            );
            return Ok(new { mensagem = "FCM Token registrado com sucesso." });
        }

        [HttpPost("alterar-senha")]
        [Authorize]
        public async Task<IActionResult> AlterarSenha([FromBody] AlterarSenhaDto dto)
        {
            if (string.IsNullOrWhiteSpace(dto.NovaSenha) || dto.NovaSenha.Length < 6)
                return BadRequest(new { mensagem = "A nova senha deve ter pelo menos 6 caracteres." });

            var usuarioId = UsuarioContexto.GetUsuarioId(User);
            var hash = BCrypt.Net.BCrypt.HashPassword(dto.NovaSenha);

            using var con = _db.CriarConexao();
            await con.ExecuteAsync(
                "UPDATE USUARIOS SET SENHA_HASH = @Hash WHERE ID = @Id",
                new { Hash = hash, Id = usuarioId }
            );

            return Ok(new { mensagem = "Senha atualizada com sucesso!" });
        }

        private string GerarJwtToken(int usuarioId, string nome, string email, int perfil, int personalId)
        {
            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_config["Jwt:Key"]!));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var roleName = perfil switch
            {
                3 => "SuperAdmin",
                1 => "Personal",
                _ => "Aluno"
            };

            var claims = new[]
            {
                new Claim(ClaimTypes.NameIdentifier, usuarioId.ToString()),
                new Claim("usuarioId", usuarioId.ToString()),
                new Claim("perfil", perfil.ToString()),
                new Claim("personalId", personalId.ToString()),
                new Claim(ClaimTypes.Name, nome),
                new Claim(ClaimTypes.Email, email),
                new Claim(ClaimTypes.Role, roleName)
            };

            var token = new JwtSecurityToken(
                issuer: _config["Jwt:Issuer"],
                audience: _config["Jwt:Audience"],
                claims: claims,
                expires: DateTime.UtcNow.AddDays(30),
                signingCredentials: creds
            );

            return new JwtSecurityTokenHandler().WriteToken(token);
        }

        public class LoginRequest
        {
            public string Email { get; set; } = string.Empty;
            public string Senha { get; set; } = string.Empty;
        }

        public class FcmTokenDto
        {
            public string Token { get; set; } = string.Empty;
        }

        public class AlterarSenhaDto
        {
            public string NovaSenha { get; set; } = string.Empty;
        }
    }
}
