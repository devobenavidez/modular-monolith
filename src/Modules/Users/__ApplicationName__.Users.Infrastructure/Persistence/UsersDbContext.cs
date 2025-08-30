using Microsoft.EntityFrameworkCore;
using __RootNamespace__.Users.Domain.Entities;
using __RootNamespace__.Users.Infrastructure.Persistence.Configurations;
using __RootNamespace__.SharedKernel.Interfaces;

namespace __RootNamespace__.Users.Infrastructure.Persistence;

public class UsersDbContext : DbContext, IUnitOfWork
{
    public UsersDbContext(DbContextOptions<UsersDbContext> options) : base(options)
    {
    }

    public DbSet<User> Users => Set<User>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.HasDefaultSchema("users");
        
        modelBuilder.ApplyConfiguration(new UserConfiguration());
        
        base.OnModelCreating(modelBuilder);
    }    public override async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        return await base.SaveChangesAsync(cancellationToken);
    }

    public async Task BeginTransactionAsync()
    {
        if (Database.CurrentTransaction is null)
        {
            await Database.BeginTransactionAsync();
        }
    }

    public async Task CommitTransactionAsync()
    {
        if (Database.CurrentTransaction is not null)
        {
            await Database.CurrentTransaction.CommitAsync();
        }
    }

    public async Task RollbackTransactionAsync()
    {
        if (Database.CurrentTransaction is not null)
        {
            await Database.CurrentTransaction.RollbackAsync();
        }
    }
}
