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
            if (string.IsNullOrWhiteSpace(conn))
            {
                conn = "Server=tcp:coachcenter-srv-ronald.database.windows.net,1433;Initial Catalog=coachcenter-db;User Id=coachadmin;Password=Soore1020.;Encrypt=True;TrustServerCertificate=False;Connection Timeout=60;";
            }
            _connectionString = conn;
        }

        public IDbConnection CriarConexao() => new SqlConnection(_connectionString);
    }
}
