using Microsoft.EntityFrameworkCore;
using __RootNamespace__.Users.Domain.Entities;
using __RootNamespace__.Users.Domain.Abstractions;
using __RootNamespace__.Users.Infrastructure.Persistence;

namespace __RootNamespace__.Users.Infrastructure.Persistence.Repositories;

public class UserRepository : IUserRepository
{
    private readonly UsersDbContext _context;
    private readonly DbSet<User> _users;

    public UserRepository(UsersDbContext context)
    {
        _context = context;
        _users = context.Set<User>();
    }

    public async Task<User?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        return await _users.FirstOrDefaultAsync(u => u.Id == id, cancellationToken);
    }

    public async Task<User?> GetByEmailAsync(string email, CancellationToken cancellationToken = default)
    {
        return await _users.FirstOrDefaultAsync(u => u.Email == email, cancellationToken);
    }

    public async Task<List<User>> GetAllAsync(CancellationToken cancellationToken = default)
    {
        return await _users.OrderBy(u => u.FirstName).ThenBy(u => u.LastName).ToListAsync(cancellationToken);
    }

    public async Task<List<User>> GetActiveUsersAsync(CancellationToken cancellationToken = default)
    {
        return await _users
            .Where(u => u.IsActive)
            .OrderBy(u => u.FirstName)
            .ThenBy(u => u.LastName)
            .ToListAsync(cancellationToken);
    }

    public async Task<bool> ExistsByEmailAsync(string email, CancellationToken cancellationToken = default)
    {
        return await _users.AnyAsync(u => u.Email == email, cancellationToken);
    }

    public async Task AddAsync(User user, CancellationToken cancellationToken = default)
    {
        await _users.AddAsync(user, cancellationToken);
    }

    public void Update(User user)
    {
        _users.Update(user);
    }

    public void Delete(User user)
    {
        user.IsDeleted = true;
        _users.Update(user);
    }
}
