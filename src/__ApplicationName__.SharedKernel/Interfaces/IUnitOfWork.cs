namespace __RootNamespace__.SharedKernel.Interfaces;

/// <summary>
/// Interface for Unit of Work pattern shared between modules
/// </summary>
public interface IUnitOfWork
{
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
    Task BeginTransactionAsync();
    Task CommitTransactionAsync();
    Task RollbackTransactionAsync();
}
