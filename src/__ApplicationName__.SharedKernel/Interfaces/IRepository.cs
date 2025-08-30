using __RootNamespace__.SharedKernel.Common;

namespace __RootNamespace__.SharedKernel.Interfaces;

/// <summary>
/// Interface base para operaciones de escritura usando EF Core
/// </summary>
/// <typeparam name="T">Tipo de entidad que hereda de BaseEntity</typeparam>
public interface IRepository<T> where T : BaseEntity
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
    /// Agrega una nueva entidad
    /// </summary>
    Task AddAsync(T entity, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// Actualiza una entidad existente
    /// </summary>
    void Update(T entity);
    
    /// <summary>
    /// Elimina una entidad (soft delete)
    /// </summary>
    void Delete(T entity);
    
    /// <summary>
    /// Elimina una entidad permanentemente
    /// </summary>
    void DeletePermanently(T entity);
    
    /// <summary>
    /// Verifica si existe una entidad con el ID especificado
    /// </summary>
    Task<bool> ExistsAsync(Guid id, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// Cuenta el total de entidades
    /// </summary>
    Task<int> CountAsync(CancellationToken cancellationToken = default);
}

