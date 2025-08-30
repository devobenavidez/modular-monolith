using System.Data;

namespace __RootNamespace__.SharedKernel.Interfaces;

/// <summary>
/// Factory para crear conexiones de base de datos para Dapper
/// </summary>
public interface IDapperConnectionFactory
{
    /// <summary>
    /// Crea una nueva conexión de base de datos
    /// </summary>
    IDbConnection CreateConnection();
    
    /// <summary>
    /// Crea una nueva conexión de base de datos de forma asíncrona
    /// </summary>
    Task<IDbConnection> CreateConnectionAsync();
    
    /// <summary>
    /// Obtiene la cadena de conexión
    /// </summary>
    string GetConnectionString();
}

