using System.Data;
using Dapper;
using __RootNamespace__.Users.Domain.Abstractions;
using __RootNamespace__.Users.Infrastructure.Persistence.Queries;
using __RootNamespace__.SharedKernel.Interfaces;

namespace __RootNamespace__.Users.Infrastructure.Persistence.Repositories;

/// <summary>
/// Repositorio de lectura para usuarios usando Dapper
/// </summary>
public class UserReadRepository : IUserReadRepository
{
    private readonly IDapperConnectionFactory _connectionFactory;

    public UserReadRepository(IDapperConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<object?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        using var connection = _connectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<dynamic>(
            UserQueries.GetById, 
            new { Id = id });
    }

    public async Task<object?> GetByEmailAsync(string email, CancellationToken cancellationToken = default)
    {
        using var connection = _connectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<dynamic>(
            UserQueries.GetByEmail, 
            new { Email = email });
    }

    public async Task<IEnumerable<object>> GetAllAsync(CancellationToken cancellationToken = default)
    {
        using var connection = _connectionFactory.CreateConnection();
        return await connection.QueryAsync<dynamic>(UserQueries.GetAll);
    }

    public async Task<IEnumerable<object>> GetActiveUsersAsync(CancellationToken cancellationToken = default)
    {
        using var connection = _connectionFactory.CreateConnection();
        return await connection.QueryAsync<dynamic>(UserQueries.GetActiveUsers);
    }

    public async Task<IEnumerable<object>> GetUsersByFilterAsync(object filter, CancellationToken cancellationToken = default)
    {
        // Usar reflection para acceder a las propiedades del filtro
        var filterType = filter.GetType();
        var searchTermProp = filterType.GetProperty("SearchTerm");
        var isActiveProp = filterType.GetProperty("IsActive");
        var createdFromProp = filterType.GetProperty("CreatedFrom");
        var createdToProp = filterType.GetProperty("CreatedTo");
        var lastLoginFromProp = filterType.GetProperty("LastLoginFrom");
        var lastLoginToProp = filterType.GetProperty("LastLoginTo");
        var pageProp = filterType.GetProperty("Page");
        var pageSizeProp = filterType.GetProperty("PageSize");
        var sortByProp = filterType.GetProperty("SortBy");
        var sortDescendingProp = filterType.GetProperty("SortDescending");

        var page = Convert.ToInt32(pageProp?.GetValue(filter) ?? 1);
        var pageSize = Convert.ToInt32(pageSizeProp?.GetValue(filter) ?? 10);
        var offset = (page - 1) * pageSize;

        var parameters = new
        {
            SearchTerm = searchTermProp?.GetValue(filter)?.ToString() != null ? $"%{searchTermProp.GetValue(filter)}%" : null,
            IsActive = isActiveProp?.GetValue(filter),
            CreatedFrom = createdFromProp?.GetValue(filter),
            CreatedTo = createdToProp?.GetValue(filter),
            LastLoginFrom = lastLoginFromProp?.GetValue(filter),
            LastLoginTo = lastLoginToProp?.GetValue(filter),
            PageSize = pageSize,
            Offset = offset,
            SortBy = sortByProp?.GetValue(filter) ?? "FirstName",
            SortDescending = sortDescendingProp?.GetValue(filter) ?? false
        };

        using var connection = _connectionFactory.CreateConnection();
        return await connection.QueryAsync<dynamic>(UserQueries.GetUsersByFilter, parameters);
    }

    public async Task<bool> ExistsByEmailAsync(string email, CancellationToken cancellationToken = default)
    {
        using var connection = _connectionFactory.CreateConnection();
        var count = await connection.ExecuteScalarAsync<int>(
            UserQueries.ExistsByEmail, 
            new { Email = email });
        return count > 0;
    }

    public async Task<int> CountAsync(CancellationToken cancellationToken = default)
    {
        using var connection = _connectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(UserQueries.Count);
    }

    public async Task<int> CountActiveAsync(CancellationToken cancellationToken = default)
    {
        using var connection = _connectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(UserQueries.CountActive);
    }
}
