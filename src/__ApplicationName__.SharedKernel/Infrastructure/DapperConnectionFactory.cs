using System.Data;
using Npgsql;
using __RootNamespace__.SharedKernel.Interfaces;

namespace __RootNamespace__.SharedKernel.Infrastructure;

/// <summary>
/// Implementación de la factory de conexiones Dapper para PostgreSQL
/// </summary>
public class DapperConnectionFactory : IDapperConnectionFactory
{
    private readonly string _connectionString;

    public DapperConnectionFactory(string connectionString)
    {
        _connectionString = connectionString ?? throw new ArgumentNullException(nameof(connectionString));
    }

    /// <summary>
    /// Crea una nueva conexión de base de datos
    /// </summary>
    public IDbConnection CreateConnection()
    {
        var connection = new NpgsqlConnection(_connectionString);
        connection.Open();
        return connection;
    }

    /// <summary>
    /// Crea una nueva conexión de base de datos de forma asíncrona
    /// </summary>
    public async Task<IDbConnection> CreateConnectionAsync()
    {
        var connection = new NpgsqlConnection(_connectionString);
        await connection.OpenAsync();
        return connection;
    }

    /// <summary>
    /// Obtiene la cadena de conexión
    /// </summary>
    public string GetConnectionString()
    {
        return _connectionString;
    }
}

