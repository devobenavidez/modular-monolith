namespace __RootNamespace__.SharedKernel.Interfaces;

/// <summary>
/// Interface base para operaciones de solo lectura usando Dapper
/// </summary>
/// <typeparam name="T">Tipo de entidad</typeparam>
public interface IReadOnlyRepository<T> where T : class
{
    /// <summary>
    /// Obtiene una entidad por su ID
    /// </summary>
    Task<T?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// Obtiene todas las entidades
    /// </summary>
    Task<IEnumerable<T>> GetAllAsync(CancellationToken cancellationToken = default);
    
    /// <summary>
    /// Obtiene entidades que cumplan con el filtro especificado
    /// </summary>
    Task<IEnumerable<T>> GetAsync(Func<T, bool> predicate, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// Verifica si existe una entidad con el ID especificado
    /// </summary>
    Task<bool> ExistsAsync(Guid id, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// Cuenta el total de entidades
    /// </summary>
    Task<int> CountAsync(CancellationToken cancellationToken = default);
}

