using Microsoft.Data.SqlClient;
using System.Data;

namespace PersonalProAPI.Data
{
    public class DbConnection
    {
        private readonly string _connectionString;

        public DbConnection(IConfiguration config)
        {
            _connectionString = config.GetConnectionString("PersonalPro")
                ?? throw new InvalidOperationException("Connection string 'PersonalPro' não configurada.");
        }

        public IDbConnection CriarConexao() => new SqlConnection(_connectionString);
    }
}

