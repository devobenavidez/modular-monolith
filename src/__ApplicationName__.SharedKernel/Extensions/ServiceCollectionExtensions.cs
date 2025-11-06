using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Configuration;
using __RootNamespace__.SharedKernel.Behaviors;
using __RootNamespace__.SharedKernel.Interfaces;
using __RootNamespace__.SharedKernel.Infrastructure;
using MediatR;
using FluentValidation;
using System.Reflection;

namespace __RootNamespace__.SharedKernel.Extensions;

/// <summary>
/// Extensiones para configurar servicios del SharedKernel
/// </summary>
public static class ServiceCollectionExtensions
{
    /// <summary>
    /// Agrega servicios del SharedKernel incluyendo Dapper
    /// </summary>
    public static IServiceCollection AddSharedKernel(this IServiceCollection services, IConfiguration configuration)
    {
        // Registrar MediatR
        services.AddMediatR(cfg => cfg.RegisterServicesFromAssembly(Assembly.GetExecutingAssembly()));

        // Registrar FluentValidation
        services.AddValidatorsFromAssembly(Assembly.GetExecutingAssembly());

        // Registrar behaviors de MediatR
        services.AddTransient(typeof(IPipelineBehavior<,>), typeof(ValidationBehavior<,>));
        services.AddTransient(typeof(IPipelineBehavior<,>), typeof(LoggingBehavior<,>));
        services.AddTransient(typeof(IPipelineBehavior<,>), typeof(TransactionBehavior<,>));
        services.AddTransient(typeof(IPipelineBehavior<,>), typeof(DapperQueryBehavior<,>));

        // Registrar Dapper Connection Factory
        services.AddSingleton<IDapperConnectionFactory>(provider =>
        {
            var connectionString = configuration.GetConnectionString("DefaultConnection");
            if (string.IsNullOrEmpty(connectionString))
            {
                throw new InvalidOperationException("Connection string 'DefaultConnection' is not configured.");
            }
            return new DapperConnectionFactory(connectionString);
        });

        // Registrar UnitOfWork Factory
        services.AddScoped<IUnitOfWorkFactory, Services.UnitOfWorkFactory>();

        return services;
    }

    /// <summary>
    /// Agrega servicios del SharedKernel sin configuración específica
    /// </summary>
    public static IServiceCollection AddSharedKernel(this IServiceCollection services)
    {
        // Registrar MediatR
        services.AddMediatR(cfg => cfg.RegisterServicesFromAssembly(Assembly.GetExecutingAssembly()));

        // Registrar FluentValidation
        services.AddValidatorsFromAssembly(Assembly.GetExecutingAssembly());

        // Registrar behaviors de MediatR
        services.AddTransient(typeof(IPipelineBehavior<,>), typeof(ValidationBehavior<,>));
        services.AddTransient(typeof(IPipelineBehavior<,>), typeof(LoggingBehavior<,>));
        services.AddTransient(typeof(IPipelineBehavior<,>), typeof(TransactionBehavior<,>));
        services.AddTransient(typeof(IPipelineBehavior<,>), typeof(DapperQueryBehavior<,>));

        // Registrar UnitOfWork Factory
        services.AddScoped<IUnitOfWorkFactory, Services.UnitOfWorkFactory>();

        return services;
    }
}
