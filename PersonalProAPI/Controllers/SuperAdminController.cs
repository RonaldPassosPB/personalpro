using Dapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PersonalProAPI.Data;
using PersonalProAPI.Helpers;
using PersonalProAPI.Services;

namespace PersonalProAPI.Controllers
{
    [ApiController]
    [Route("api/superadmin")]
    [Authorize]
    public class SuperAdminController : ControllerBase
    {
        private readonly DbConnection _db;
        private readonly LogService _logService;

        public SuperAdminController(DbConnection db, LogService logService)
        {
            _db = db;
            _logService = logService;
        }

        private bool IsSuperAdmin() => UsuarioContexto.GetPerfil(User) == 3;

        [HttpGet("dashboard")]
        public async Task<IActionResult> GetDashboard([FromQuery] string? filtro = null)
        {
            if (!IsSuperAdmin()) return Forbid();

            using var con = _db.CriarConexao();
            var mesAtual = DateTime.Now.ToString("yyyy-MM");

            var personais = (await con.QueryAsync<dynamic>(@"
                SELECT
                    P.ID AS Id,
                    P.NOME_PROFISSIONAL AS NomeProfissional,
                    P.CREF AS Cref,
                    P.CPF_CNPJ AS CpfCnpj,
                    P.EMAIL AS Email,
                    P.TELEFONE AS Telefone,
                    P.CHAVE_PIX AS ChavePix,
                    P.PLANO AS Plano,
                    P.STATUS AS Status,
                    P.VALOR_ASSINATURA AS ValorAssinatura,
                    P.DIA_VENCIMENTO AS DiaVencimento,
                    P.ULTIMO_PAGAMENTO_MES AS UltimoPagamentoMes,
                    P.DATA_CADASTRO AS DataCadastro,
                    CASE WHEN P.ULTIMO_PAGAMENTO_MES = @MesAtual THEN 1 ELSE 0 END AS PagoNoMes,
                    (SELECT COUNT(1) FROM ALUNOS A WHERE A.PERSONAL_ID = P.ID) AS TotalAlunos,
                    (SELECT COUNT(1) FROM FICHAS_TREINO F WHERE F.PERSONAL_ID = P.ID AND F.ATIVA = 1) AS TotalFichasAtivas
                FROM PERSONAIS P
                ORDER BY P.ID DESC",
                new { MesAtual = mesAtual }
            )).ToList();

            decimal receitaPrevista = personais.Where(p => (bool)p.Status).Sum(p => (decimal)p.ValorAssinatura);
            decimal receitaRecebida = personais.Where(p => (int)p.PagoNoMes == 1).Sum(p => (decimal)p.ValorAssinatura);
            int totalPersonais = personais.Count;
            int personaisAtivos = personais.Count(p => (bool)p.Status);
            int personaisBloqueados = personais.Count(p => !(bool)p.Status);
            int personaisEmDia = personais.Count(p => (int)p.PagoNoMes == 1);
            int personaisPendentes = personais.Count(p => (int)p.PagoNoMes == 0);
            int totalAlunosSaaS = personais.Sum(p => (int)p.TotalAlunos);

            var filtrados = filtro?.ToUpperInvariant() switch
            {
                "EM_DIA" => personais.Where(p => (int)p.PagoNoMes == 1).ToList(),
                "PENDENTE" => personais.Where(p => (int)p.PagoNoMes == 0).ToList(),
                "BLOQUEADOS" => personais.Where(p => !(bool)p.Status).ToList(),
                _ => personais
            };

            return Ok(new
            {
                mesReferencia = mesAtual,
                resumoFinanceiro = new
                {
                    receitaPrevista,
                    receitaRecebida,
                    receitaPendente = Math.Max(0, receitaPrevista - receitaRecebida),
                    totalPersonais,
                    personaisAtivos,
                    personaisBloqueados,
                    personaisEmDia,
                    personaisPendentes,
                    totalAlunosSaaS
                },
                personais = filtrados
            });
        }

        [HttpPost("personais")]
        public async Task<IActionResult> CriarPersonal([FromBody] NovoPersonalDto dto)
        {
            if (!IsSuperAdmin()) return Forbid();

            if (string.IsNullOrWhiteSpace(dto.NomeProfissional) ||
                string.IsNullOrWhiteSpace(dto.Email) ||
                string.IsNullOrWhiteSpace(dto.Senha))
            {
                return BadRequest(new { mensagem = "Nome, E-mail e Senha são obrigatórios." });
            }

            using var con = _db.CriarConexao();
            con.Open();

            var emailExiste = await con.ExecuteScalarAsync<int>(
                "SELECT COUNT(1) FROM USUARIOS WHERE EMAIL = @Email",
                new { Email = dto.Email.Trim() }
            );

            if (emailExiste > 0)
                return BadRequest(new { mensagem = "Já existe um usuário cadastrado com este e-mail." });

            using var trans = con.BeginTransaction();
            try
            {
                var mesAtual = DateTime.Now.ToString("yyyy-MM");
                var personalId = await con.ExecuteScalarAsync<int>(@"
                    INSERT INTO PERSONAIS (
                        NOME_PROFISSIONAL, CREF, CPF_CNPJ, EMAIL, TELEFONE, CHAVE_PIX,
                        PLANO, STATUS, VALOR_ASSINATURA, DIA_VENCIMENTO, ULTIMO_PAGAMENTO_MES, DATA_CADASTRO
                    )
                    VALUES (
                        @NomeProfissional, @Cref, @CpfCnpj, @Email, @Telefone, @ChavePix,
                        @Plano, 1, @ValorAssinatura, @DiaVencimento, @UltimoPagamentoMes, GETDATE()
                    );
                    SELECT CAST(SCOPE_IDENTITY() AS INT);",
                    new
                    {
                        dto.NomeProfissional,
                        dto.Cref,
                        dto.CpfCnpj,
                        Email = dto.Email.Trim(),
                        dto.Telefone,
                        ChavePix = string.IsNullOrWhiteSpace(dto.ChavePix) ? dto.Email.Trim() : dto.ChavePix,
                        Plano = string.IsNullOrWhiteSpace(dto.Plano) ? "PRO" : dto.Plano.ToUpperInvariant(),
                        ValorAssinatura = dto.ValorAssinatura > 0 ? dto.ValorAssinatura : 99.90m,
                        DiaVencimento = dto.DiaVencimento > 0 ? dto.DiaVencimento : 10,
                        UltimoPagamentoMes = dto.MarcarPagoNoMes ? mesAtual : null
                    },
                    trans
                );

                var senhaHash = BCrypt.Net.BCrypt.HashPassword(dto.Senha);

                await con.ExecuteAsync(@"
                    INSERT INTO USUARIOS (PERSONAL_ID, NOME, EMAIL, SENHA_HASH, PERFIL, STATUS, DATA_CADASTRO)
                    VALUES (@PersonalId, @Nome, @Email, @SenhaHash, 1, 1, GETDATE());",
                    new
                    {
                        PersonalId = personalId,
                        Nome = dto.NomeProfissional,
                        Email = dto.Email.Trim(),
                        SenhaHash = senhaHash
                    },
                    trans
                );

                trans.Commit();
                return Ok(new { mensagem = "Personal Trainer cadastrado com sucesso no SaaS!", personalId });
            }
            catch
            {
                trans.Rollback();
                throw;
            }
        }

        [HttpPut("personais/{id}")]
        public async Task<IActionResult> EditarPersonal(int id, [FromBody] EditarPersonalDto dto)
        {
            if (!IsSuperAdmin()) return Forbid();

            using var con = _db.CriarConexao();
            await con.ExecuteAsync(@"
                UPDATE PERSONAIS
                SET NOME_PROFISSIONAL = @NomeProfissional,
                    CREF = @Cref,
                    CPF_CNPJ = @CpfCnpj,
                    EMAIL = @Email,
                    TELEFONE = @Telefone,
                    CHAVE_PIX = @ChavePix,
                    PLANO = @Plano,
                    VALOR_ASSINATURA = @ValorAssinatura,
                    DIA_VENCIMENTO = @DiaVencimento
                WHERE ID = @Id;

                UPDATE USUARIOS
                SET NOME = @NomeProfissional,
                    EMAIL = @Email
                WHERE PERSONAL_ID = @Id AND PERFIL = 1;",
                new
                {
                    Id = id,
                    dto.NomeProfissional,
                    dto.Cref,
                    dto.CpfCnpj,
                    Email = dto.Email.Trim(),
                    dto.Telefone,
                    dto.ChavePix,
                    Plano = (dto.Plano ?? "PRO").ToUpperInvariant(),
                    dto.ValorAssinatura,
                    dto.DiaVencimento
                }
            );

            return Ok(new { mensagem = "Dados do Personal Trainer atualizados com sucesso!" });
        }

        [HttpPatch("personais/{id}/status")]
        public async Task<IActionResult> AlterarStatusKillSwitch(int id, [FromBody] StatusDto dto)
        {
            if (!IsSuperAdmin()) return Forbid();

            using var con = _db.CriarConexao();
            await con.ExecuteAsync(
                "UPDATE PERSONAIS SET STATUS = @Status WHERE ID = @Id",
                new { Status = dto.Ativo, Id = id }
            );

            return Ok(new
            {
                mensagem = dto.Ativo
                    ? "✅ Acesso liberado! O Personal Trainer e todos os alunos dele já podem acessar o sistema."
                    : "🚫 KILL-SWITCH ATIVADO! O acesso deste Personal Trainer e de todos os alunos vinculados foi bloqueado imediatamente."
            });
        }

        [HttpPost("personais/{id}/confirmar-pagamento")]
        public async Task<IActionResult> ConfirmarPagamentoAssinatura(int id)
        {
            if (!IsSuperAdmin()) return Forbid();

            var mesAtual = DateTime.Now.ToString("yyyy-MM");
            using var con = _db.CriarConexao();
            await con.ExecuteAsync(@"
                UPDATE PERSONAIS
                SET ULTIMO_PAGAMENTO_MES = @MesAtual,
                    STATUS = 1
                WHERE ID = @Id",
                new { MesAtual = mesAtual, Id = id }
            );

            return Ok(new { mensagem = $"💰 Pagamento da assinatura ({mesAtual}) confirmado e acesso liberado!" });
        }

        [HttpPost("personais/{id}/redefinir-senha")]
        public async Task<IActionResult> RedefinirSenhaPersonal(int id, [FromBody] RedefinirSenhaPersonalDto dto)
        {
            if (!IsSuperAdmin()) return Forbid();

            if (string.IsNullOrWhiteSpace(dto.NovaSenha) || dto.NovaSenha.Length < 6)
                return BadRequest(new { mensagem = "A nova senha deve ter no mínimo 6 caracteres." });

            var hash = BCrypt.Net.BCrypt.HashPassword(dto.NovaSenha);
            using var con = _db.CriarConexao();
            await con.ExecuteAsync(
                "UPDATE USUARIOS SET SENHA_HASH = @Hash WHERE PERSONAL_ID = @Id AND PERFIL = 1",
                new { Hash = hash, Id = id }
            );

            return Ok(new { mensagem = "🔑 Senha do Personal Trainer redefinida com sucesso!" });
        }

        [HttpGet("logs")]
        public async Task<IActionResult> ObterLogs()
        {
            if (!IsSuperAdmin()) return Forbid();
            var conteudo = await _logService.ObterConteudoUltimoLogAsync();
            return Ok(new { log = conteudo });
        }

        public class NovoPersonalDto
        {
            public string NomeProfissional { get; set; } = string.Empty;
            public string? Cref { get; set; }
            public string? CpfCnpj { get; set; }
            public string Email { get; set; } = string.Empty;
            public string Senha { get; set; } = string.Empty;
            public string? Telefone { get; set; }
            public string? ChavePix { get; set; }
            public string Plano { get; set; } = "PRO";
            public decimal ValorAssinatura { get; set; } = 99.90m;
            public int DiaVencimento { get; set; } = 10;
            public bool MarcarPagoNoMes { get; set; } = true;
        }

        public class EditarPersonalDto
        {
            public string NomeProfissional { get; set; } = string.Empty;
            public string? Cref { get; set; }
            public string? CpfCnpj { get; set; }
            public string Email { get; set; } = string.Empty;
            public string? Telefone { get; set; }
            public string? ChavePix { get; set; }
            public string Plano { get; set; } = "PRO";
            public decimal ValorAssinatura { get; set; } = 99.90m;
            public int DiaVencimento { get; set; } = 10;
        }

        public class StatusDto
        {
            public bool Ativo { get; set; }
        }

        public class RedefinirSenhaPersonalDto
        {
            public string NovaSenha { get; set; } = string.Empty;
        }
    }
}
