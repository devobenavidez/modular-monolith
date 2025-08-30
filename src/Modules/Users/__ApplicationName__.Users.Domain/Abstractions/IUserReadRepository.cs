namespace __RootNamespace__.Users.Domain.Abstractions;

/// <summary>
/// Interface para operaciones de solo lectura de usuarios usando Dapper
/// </summary>
public interface IUserReadRepository
{
    /// <summary>
    /// Obtiene un usuario por su ID
    /// </summary>
    Task<object?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// Obtiene un usuario por su email
    /// </summary>
    Task<object?> GetByEmailAsync(string email, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// Obtiene todos los usuarios
    /// </summary>
    Task<IEnumerable<object>> GetAllAsync(CancellationToken cancellationToken = default);
    
    /// <summary>
    /// Obtiene usuarios activos
    /// </summary>
    Task<IEnumerable<object>> GetActiveUsersAsync(CancellationToken cancellationToken = default);
    
    /// <summary>
    /// Obtiene usuarios por filtro
    /// </summary>
    Task<IEnumerable<object>> GetUsersByFilterAsync(object filter, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// Verifica si existe un usuario con el email especificado
    /// </summary>
    Task<bool> ExistsByEmailAsync(string email, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// Cuenta el total de usuarios
    /// </summary>
    Task<int> CountAsync(CancellationToken cancellationToken = default);
    
    /// <summary>
    /// Cuenta usuarios activos
    /// </summary>
    Task<int> CountActiveAsync(CancellationToken cancellationToken = default);
}
