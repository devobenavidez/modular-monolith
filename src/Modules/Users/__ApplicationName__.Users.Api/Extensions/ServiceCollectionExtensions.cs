using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.EntityFrameworkCore;
using __RootNamespace__.Users.Infrastructure.Extensions;
using System.Reflection;
using MediatR;
using FluentValidation;

namespace __RootNamespace__.Users.Api.Extensions;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddUsersModule(this IServiceCollection services, IConfiguration configuration)
    {
        // Infrastructure layer (Database, Repositories)
        services.AddDbContext<__RootNamespace__.Users.Infrastructure.Persistence.UsersDbContext>(options =>
            options.UseNpgsql(
                configuration.GetConnectionString("DefaultConnection"),
                b => b.MigrationsAssembly(typeof(__RootNamespace__.Users.Infrastructure.Persistence.UsersDbContext).Assembly.FullName)));

        // Registrar repositorios
        services.AddScoped<__RootNamespace__.Users.Domain.Abstractions.IUserRepository, __RootNamespace__.Users.Infrastructure.Persistence.Repositories.UserRepository>();
        services.AddScoped<__RootNamespace__.Users.Domain.Abstractions.IUserReadRepository, __RootNamespace__.Users.Infrastructure.Persistence.Repositories.UserReadRepository>();

        // MediatR for the module
        services.AddMediatR(cfg => cfg.RegisterServicesFromAssembly(
            Assembly.GetAssembly(typeof(__RootNamespace__.Users.Application.Commands.CreateUser.CreateUserCommand))!));

        // Validators for the module
        services.AddValidatorsFromAssembly(
            Assembly.GetAssembly(typeof(__RootNamespace__.Users.Application.Commands.CreateUser.CreateUserCommandValidator))!);

        return services;
    }
}
