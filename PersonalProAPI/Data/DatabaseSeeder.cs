using Dapper;

namespace PersonalProAPI.Data
{
    public static class DatabaseSeeder
    {
        public static async Task GarantirHashesDemoAsync(DbConnection db)
        {
            try
            {
                using var con = db.CriarConexao();
                var hashAdmin123 = BCrypt.Net.BCrypt.HashPassword("admin123");

                // Garante que todos os usuários de demonstração tenham um hash BCrypt 100% válido para a senha 'admin123'
                await con.ExecuteAsync(@"
                    UPDATE USUARIOS
                    SET SENHA_HASH = @Hash
                    WHERE EMAIL IN (
                        'superadmin@personalpro.com',
                        'personal@personalpro.com',
                        'amanda@personalpro.com',
                        'aluno1@personalpro.com',
                        'mariana@personalpro.com'
                    )",
                    new { Hash = hashAdmin123 }
                );
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[DatabaseSeeder] Aviso ao sincronizar hashes demo: {ex.Message}");
            }
        }
    }
}
