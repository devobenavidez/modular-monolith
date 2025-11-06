namespace __RootNamespace__.SharedKernel.Interfaces;

/// <summary>
/// Factory para crear instancias de IUnitOfWork específicas por módulo
/// basándose en el tipo de repositorio que se está utilizando
/// </summary>
public interface IUnitOfWorkFactory
{
    /// <summary>
    /// Obtiene la instancia correcta de IUnitOfWork basándose en el tipo de repositorio
    /// </summary>
    /// <typeparam name="TRepository">Tipo del repositorio que determina el módulo</typeparam>
    /// <returns>Instancia de IUnitOfWork del módulo correcto</returns>
    IUnitOfWork GetUnitOfWork<TRepository>() where TRepository : class;
}

