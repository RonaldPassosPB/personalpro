using Microsoft.Data.SqlClient;
using System.Data;

namespace PersonalProAPI.Data
{
    public class DbConnection
    {
        private readonly string _connectionString;

        public DbConnection(IConfiguration config)
        {
            var conn = config.GetConnectionString("PersonalPro");
            if (string.IsNullOrWhiteSpace(conn))
            {
                conn = config["ConnectionStrings:PersonalPro"] ??
                       Environment.GetEnvironmentVariable("ConnectionStrings__PersonalPro") ??
                       Environment.GetEnvironmentVariable("SQLAZURECONNSTR_PersonalPro");
            }
            // Sem senha no código: em produção vem da cadeia de conexão "PersonalPro" do App Service,
            // localmente do appsettings.Development.json (fora do git)
            if (string.IsNullOrWhiteSpace(conn))
            {
                throw new InvalidOperationException(
                    "Connection string 'PersonalPro' não configurada. No Azure: Variáveis de ambiente → Cadeias de conexão. " +
                    "Localmente: PersonalProAPI/appsettings.Development.json.");
            }
            _connectionString = conn;
        }

        public IDbConnection CriarConexao() => new SqlConnection(_connectionString);
    }
}
