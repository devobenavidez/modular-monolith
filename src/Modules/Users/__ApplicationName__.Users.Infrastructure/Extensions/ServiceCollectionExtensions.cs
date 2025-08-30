using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using __RootNamespace__.Users.Domain.Abstractions;
using __RootNamespace__.Users.Infrastructure.Persistence;
using __RootNamespace__.Users.Infrastructure.Persistence.Repositories;
using __RootNamespace__.SharedKernel.Interfaces;

namespace __RootNamespace__.Users.Infrastructure.Extensions;

/// <summary>
/// Extensiones para configurar servicios del módulo Users
/// </summary>
public static class ServiceCollectionExtensions
{
    /// <summary>
    /// Agrega servicios del módulo Users
    /// </summary>
    public static IServiceCollection AddUsersModule(this IServiceCollection services, IConfiguration configuration)
    {
        // Registrar DbContext
        services.AddDbContext<UsersDbContext>(options =>
            options.UseNpgsql(
                configuration.GetConnectionString("DefaultConnection"),
                b => b.MigrationsAssembly(typeof(UsersDbContext).Assembly.FullName)));

        // Registrar IUnitOfWork usando el DbContext
        services.AddScoped<IUnitOfWork>(provider => provider.GetRequiredService<UsersDbContext>());

        // Registrar repositorios
        services.AddScoped<IUserRepository, UserRepository>();
        services.AddScoped<IUserReadRepository, UserReadRepository>();

        return services;
    }
}
