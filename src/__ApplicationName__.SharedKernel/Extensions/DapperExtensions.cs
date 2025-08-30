using System.Data;
using Dapper;

namespace __RootNamespace__.SharedKernel.Extensions;

/// <summary>
/// Extensiones útiles para Dapper
/// </summary>
public static class DapperExtensions
{
    /// <summary>
    /// Ejecuta una consulta y mapea el resultado a un tipo específico
    /// </summary>
    public static async Task<IEnumerable<T>> QueryAsync<T>(this IDbConnection connection, string sql, object? param = null, IDbTransaction? transaction = null, int? commandTimeout = null, CommandType? commandType = null)
    {
        return await connection.QueryAsync<T>(sql, param, transaction, commandTimeout, commandType);
    }

    /// <summary>
    /// Ejecuta una consulta y mapea el resultado a un tipo específico (primer resultado)
    /// </summary>
    public static async Task<T?> QueryFirstOrDefaultAsync<T>(this IDbConnection connection, string sql, object? param = null, IDbTransaction? transaction = null, int? commandTimeout = null, CommandType? commandType = null)
    {
        return await connection.QueryFirstOrDefaultAsync<T>(sql, param, transaction, commandTimeout, commandType);
    }

    /// <summary>
    /// Ejecuta una consulta y mapea el resultado a un tipo específico (resultado único)
    /// </summary>
    public static async Task<T> QuerySingleAsync<T>(this IDbConnection connection, string sql, object? param = null, IDbTransaction? transaction = null, int? commandTimeout = null, CommandType? commandType = null)
    {
        return await connection.QuerySingleAsync<T>(sql, param, transaction, commandTimeout, commandType);
    }

    /// <summary>
    /// Ejecuta una consulta y mapea el resultado a un tipo específico (resultado único o null)
    /// </summary>
    public static async Task<T?> QuerySingleOrDefaultAsync<T>(this IDbConnection connection, string sql, object? param = null, IDbTransaction? transaction = null, int? commandTimeout = null, CommandType? commandType = null)
    {
        return await connection.QuerySingleOrDefaultAsync<T>(sql, param, transaction, commandTimeout, commandType);
    }

    /// <summary>
    /// Ejecuta una consulta y retorna el número de filas afectadas
    /// </summary>
    public static async Task<int> ExecuteAsync(this IDbConnection connection, string sql, object? param = null, IDbTransaction? transaction = null, int? commandTimeout = null, CommandType? commandType = null)
    {
        return await connection.ExecuteAsync(sql, param, transaction, commandTimeout, commandType);
    }

    /// <summary>
    /// Ejecuta una consulta y retorna el primer valor de la primera fila
    /// </summary>
    public static async Task<T> ExecuteScalarAsync<T>(this IDbConnection connection, string sql, object? param = null, IDbTransaction? transaction = null, int? commandTimeout = null, CommandType? commandType = null)
    {
        return await connection.ExecuteScalarAsync<T>(sql, param, transaction, commandTimeout, commandType);
    }
}

