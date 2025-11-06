#!/bin/bash

# Script para crear módulos en Linux/Mac
# Uso: ./create-module.sh <ModuleName> <RootNamespace> <ApplicationName>

if [ $# -ne 3 ]; then
    echo "Uso: $0 <ModuleName> <RootNamespace> <ApplicationName>"
    echo "Ejemplo: $0 Products MiEmpresa.ECommerce ECommerce"
    exit 1
fi

MODULE_NAME=$1
ROOT_NAMESPACE=$2
APPLICATION_NAME=$3

echo "Creando módulo: $MODULE_NAME"
echo "RootNamespace: $ROOT_NAMESPACE"
echo "ApplicationName: $APPLICATION_NAME"

# Verificar que estamos en el directorio correcto
if [ ! -d "src" ]; then
    echo "ERROR: Este script debe ejecutarse desde la raíz del proyecto (donde está la carpeta src)"
    exit 1
fi

# Crear estructura de directorios
MODULE_PATH="src/Modules/$MODULE_NAME"

mkdir -p "$MODULE_PATH/$APPLICATION_NAME.$MODULE_NAME.Api/Controllers"
mkdir -p "$MODULE_PATH/$APPLICATION_NAME.$MODULE_NAME.Api/Extensions"
mkdir -p "$MODULE_PATH/$APPLICATION_NAME.$MODULE_NAME.Application/Commands"
mkdir -p "$MODULE_PATH/$APPLICATION_NAME.$MODULE_NAME.Application/Queries"
mkdir -p "$MODULE_PATH/$APPLICATION_NAME.$MODULE_NAME.Application/DTOs"
mkdir -p "$MODULE_PATH/$APPLICATION_NAME.$MODULE_NAME.Application/Interfaces"
mkdir -p "$MODULE_PATH/$APPLICATION_NAME.$MODULE_NAME.Domain/Entities"
mkdir -p "$MODULE_PATH/$APPLICATION_NAME.$MODULE_NAME.Domain/ValueObjects"
mkdir -p "$MODULE_PATH/$APPLICATION_NAME.$MODULE_NAME.Domain/Events"
mkdir -p "$MODULE_PATH/$APPLICATION_NAME.$MODULE_NAME.Domain/Abstractions"
mkdir -p "$MODULE_PATH/$APPLICATION_NAME.$MODULE_NAME.Infrastructure/Models"
mkdir -p "$MODULE_PATH/$APPLICATION_NAME.$MODULE_NAME.Infrastructure/Persistence/Configurations"
mkdir -p "$MODULE_PATH/$APPLICATION_NAME.$MODULE_NAME.Infrastructure/Persistence/Repositories"
mkdir -p "$MODULE_PATH/$APPLICATION_NAME.$MODULE_NAME.Infrastructure/Extensions"
mkdir -p "tests/Unit/$APPLICATION_NAME.$MODULE_NAME.Application.Tests"

echo "Estructura de directorios creada"

# Crear archivos de proyecto (.csproj)
echo "Creando archivos de proyecto..."

# API Project
cat > "$MODULE_PATH/$APPLICATION_NAME.$MODULE_NAME.Api/$APPLICATION_NAME.$MODULE_NAME.Api.csproj" << EOF
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <RootNamespace>$ROOT_NAMESPACE.$MODULE_NAME.Api</RootNamespace>
    <AssemblyName>$APPLICATION_NAME.$MODULE_NAME.Api</AssemblyName>
  </PropertyGroup>
  
  <ItemGroup>
    <PackageReference Include="Microsoft.AspNetCore.Mvc.Core" Version="2.2.5" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="..\$APPLICATION_NAME.$MODULE_NAME.Application\$APPLICATION_NAME.$MODULE_NAME.Application.csproj" />
    <ProjectReference Include="..\$APPLICATION_NAME.$MODULE_NAME.Infrastructure\$APPLICATION_NAME.$MODULE_NAME.Infrastructure.csproj" />
  </ItemGroup>

</Project>
EOF

# Application Project
cat > "$MODULE_PATH/$APPLICATION_NAME.$MODULE_NAME.Application/$APPLICATION_NAME.$MODULE_NAME.Application.csproj" << EOF
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <RootNamespace>$ROOT_NAMESPACE.$MODULE_NAME.Application</RootNamespace>
    <AssemblyName>$APPLICATION_NAME.$MODULE_NAME.Application</AssemblyName>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="MediatR" Version="12.2.0" />
    <PackageReference Include="FluentValidation" Version="11.9.2" />
  </ItemGroup>
  
  <ItemGroup>
    <ProjectReference Include="..\$APPLICATION_NAME.$MODULE_NAME.Domain\$APPLICATION_NAME.$MODULE_NAME.Domain.csproj" />
    <ProjectReference Include="..\..\..\$APPLICATION_NAME.SharedKernel\$APPLICATION_NAME.SharedKernel.csproj" />
  </ItemGroup>

</Project>
EOF

# Domain Project
cat > "$MODULE_PATH/$APPLICATION_NAME.$MODULE_NAME.Domain/$APPLICATION_NAME.$MODULE_NAME.Domain.csproj" << EOF
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <RootNamespace>$ROOT_NAMESPACE.$MODULE_NAME.Domain</RootNamespace>
    <AssemblyName>$APPLICATION_NAME.$MODULE_NAME.Domain</AssemblyName>
  </PropertyGroup>
  
  <ItemGroup>
    <ProjectReference Include="..\..\..\$APPLICATION_NAME.SharedKernel\$APPLICATION_NAME.SharedKernel.csproj" />
  </ItemGroup>

</Project>
EOF

# Infrastructure Project
cat > "$MODULE_PATH/$APPLICATION_NAME.$MODULE_NAME.Infrastructure/$APPLICATION_NAME.$MODULE_NAME.Infrastructure.csproj" << EOF
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <RootNamespace>$ROOT_NAMESPACE.$MODULE_NAME.Infrastructure</RootNamespace>
    <AssemblyName>$APPLICATION_NAME.$MODULE_NAME.Infrastructure</AssemblyName>
  </PropertyGroup>
    <ItemGroup>
    <PackageReference Include="Microsoft.EntityFrameworkCore" Version="8.0.0" />
    <PackageReference Include="Npgsql.EntityFrameworkCore.PostgreSQL" Version="8.0.0" />
    <PackageReference Include="Dapper" Version="2.1.35" />
  </ItemGroup>
  
  <ItemGroup>
    <ProjectReference Include="..\$APPLICATION_NAME.$MODULE_NAME.Domain\$APPLICATION_NAME.$MODULE_NAME.Domain.csproj" />
    <ProjectReference Include="..\..\..\$APPLICATION_NAME.SharedKernel\$APPLICATION_NAME.SharedKernel.csproj" />
  </ItemGroup>

</Project>
EOF

# Test Project
cat > "tests/Unit/$APPLICATION_NAME.$MODULE_NAME.Application.Tests/$APPLICATION_NAME.$MODULE_NAME.Application.Tests.csproj" << EOF
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <IsPackable>false</IsPackable>
    <IsTestProject>true</IsTestProject>
    <RootNamespace>$ROOT_NAMESPACE.$MODULE_NAME.Application.Tests</RootNamespace>
    <AssemblyName>$APPLICATION_NAME.$MODULE_NAME.Application.Tests</AssemblyName>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Microsoft.NET.Test.Sdk" Version="17.8.0" />
    <PackageReference Include="xunit" Version="2.6.1" />
    <PackageReference Include="xunit.runner.visualstudio" Version="2.5.3">
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
      <PrivateAssets>all</PrivateAssets>
    </PackageReference>
    <PackageReference Include="coverlet.collector" Version="6.0.0">
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
      <PrivateAssets>all</PrivateAssets>
    </PackageReference>
    <PackageReference Include="FluentAssertions" Version="6.12.0" />
    <PackageReference Include="NSubstitute" Version="5.1.0" />
  </ItemGroup>
  <ItemGroup>
    <ProjectReference Include="..\..\..\src\Modules\$MODULE_NAME\$APPLICATION_NAME.$MODULE_NAME.Application\$APPLICATION_NAME.$MODULE_NAME.Application.csproj" />
  </ItemGroup>

</Project>
EOF

echo "Archivos de proyecto creados"

# Crear archivos base
echo "Creando archivos base..."

# Assembly Marker para Application
cat > "$MODULE_PATH/$APPLICATION_NAME.$MODULE_NAME.Application/AssemblyMarker.cs" << EOF
using System.Reflection;

namespace $ROOT_NAMESPACE.$MODULE_NAME.Application;

/// <summary>
/// Assembly marker for $MODULE_NAME Application layer
/// </summary>
public static class AssemblyMarker
{
    public static Assembly Assembly => typeof(AssemblyMarker).Assembly;
}
EOF

# Controller
cat > "$MODULE_PATH/$APPLICATION_NAME.$MODULE_NAME.Api/Controllers/${MODULE_NAME}Controller.cs" << EOF
using Microsoft.AspNetCore.Mvc;
using MediatR;

namespace $ROOT_NAMESPACE.$MODULE_NAME.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ${MODULE_NAME}Controller : ControllerBase
{
    private readonly IMediator _mediator;

    public ${MODULE_NAME}Controller(IMediator mediator)
    {
        _mediator = mediator;
    }

    [HttpGet]
    public async Task<ActionResult<string>> Get()
    {
        // TODO: Implementar query
        return Ok("$MODULE_NAME module is working!");
    }
}
EOF

# DbContext
cat > "$MODULE_PATH/$APPLICATION_NAME.$MODULE_NAME.Infrastructure/Persistence/${MODULE_NAME}DbContext.cs" << EOF
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;
using $ROOT_NAMESPACE.SharedKernel.Interfaces;
using System.Reflection;

namespace $ROOT_NAMESPACE.$MODULE_NAME.Infrastructure.Persistence;

public class ${MODULE_NAME}DbContext : DbContext, IUnitOfWork
{
    private IDbContextTransaction? _currentTransaction;

    public ${MODULE_NAME}DbContext(DbContextOptions<${MODULE_NAME}DbContext> options) : base(options)
    {
    }

    // TODO: Agregar DbSets para entidades del módulo
    // public DbSet<EntityName> EntityNames { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.HasDefaultSchema("$(echo $MODULE_NAME | tr '[:upper:]' '[:lower:]')");
        
        // Aplicar configuraciones específicas del módulo
        modelBuilder.ApplyConfigurationsFromAssembly(Assembly.GetExecutingAssembly());
        
        base.OnModelCreating(modelBuilder);
    }

    public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        => base.SaveChangesAsync(cancellationToken);

    public async Task BeginTransactionAsync()
    {
        if (_currentTransaction is not null)
            return;

        _currentTransaction = await Database.BeginTransactionAsync();
    }

    public async Task CommitTransactionAsync()
    {
        try
        {
            await SaveChangesAsync();
            if (_currentTransaction is not null)
            {
                await _currentTransaction.CommitAsync();
            }
        }
        finally
        {
            if (_currentTransaction is not null)
            {
                await _currentTransaction.DisposeAsync();
                _currentTransaction = null;
            }
        }
    }

    public async Task RollbackTransactionAsync()
    {
        try
        {
            if (_currentTransaction is not null)
            {
                await _currentTransaction.RollbackAsync();
            }
        }
        finally
        {
            if (_currentTransaction is not null)
            {
                await _currentTransaction.DisposeAsync();
                _currentTransaction = null;
            }
        }
    }
}
EOF

# Crear interface del repositorio en Domain/Abstractions
cat > "$MODULE_PATH/$APPLICATION_NAME.$MODULE_NAME.Domain/Abstractions/I${MODULE_NAME}Repository.cs" << EOF
using $ROOT_NAMESPACE.$MODULE_NAME.Domain.Entities;

namespace $ROOT_NAMESPACE.$MODULE_NAME.Domain.Abstractions;

public interface I${MODULE_NAME}Repository
{
    Task<${MODULE_NAME}?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<List<${MODULE_NAME}>> GetAllAsync(CancellationToken cancellationToken = default);
    Task AddAsync(${MODULE_NAME} entity, CancellationToken cancellationToken = default);
    void Update(${MODULE_NAME} entity);
    void Delete(${MODULE_NAME} entity);
}
EOF

# Crear implementación del repositorio en Infrastructure
cat > "$MODULE_PATH/$APPLICATION_NAME.$MODULE_NAME.Infrastructure/Persistence/Repositories/${MODULE_NAME}Repository.cs" << EOF
using Microsoft.EntityFrameworkCore;
using $ROOT_NAMESPACE.$MODULE_NAME.Domain.Entities;
using $ROOT_NAMESPACE.$MODULE_NAME.Domain.Abstractions;
using $ROOT_NAMESPACE.$MODULE_NAME.Infrastructure.Persistence;

namespace $ROOT_NAMESPACE.$MODULE_NAME.Infrastructure.Persistence.Repositories;

public class ${MODULE_NAME}Repository : I${MODULE_NAME}Repository
{
    private readonly ${MODULE_NAME}DbContext _context;
    private readonly DbSet<${MODULE_NAME}> _${MODULE_NAME,,}s;

    public ${MODULE_NAME}Repository(${MODULE_NAME}DbContext context)
    {
        _context = context;
        _${MODULE_NAME,,}s = context.Set<${MODULE_NAME}>();
    }

    public async Task<${MODULE_NAME}?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        return await _${MODULE_NAME,,}s.FindAsync(new object[] { id }, cancellationToken);
    }

    public async Task<List<${MODULE_NAME}>> GetAllAsync(CancellationToken cancellationToken = default)
    {
        return await _${MODULE_NAME,,}s.ToListAsync(cancellationToken);
    }

    public async Task AddAsync(${MODULE_NAME} ${MODULE_NAME,,}, CancellationToken cancellationToken = default)
    {
        await _${MODULE_NAME,,}s.AddAsync(${MODULE_NAME,,}, cancellationToken);
    }

    public void Update(${MODULE_NAME} ${MODULE_NAME,,})
    {
        _${MODULE_NAME,,}s.Update(${MODULE_NAME,,});
    }

    public void Delete(${MODULE_NAME} ${MODULE_NAME,,})
    {
        _${MODULE_NAME,,}s.Remove(${MODULE_NAME,,});
    }
}
EOF

# Crear entidad básica en Domain
cat > "$MODULE_PATH/$APPLICATION_NAME.$MODULE_NAME.Domain/Entities/${MODULE_NAME}.cs" << EOF
using $ROOT_NAMESPACE.SharedKernel.Common;

namespace $ROOT_NAMESPACE.$MODULE_NAME.Domain.Entities;

public class ${MODULE_NAME} : BaseEntity
{
    public string Name { get; private set; } = string.Empty;
    public string Description { get; private set; } = string.Empty;

    private ${MODULE_NAME}() { } // Constructor para EF Core

    public static ${MODULE_NAME} Create(string name, string description)
    {
        return new ${MODULE_NAME}
        {
            Name = name,
            Description = description
        };
    }

    public void Update(string name, string description)
    {
        Name = name;
        Description = description;
        UpdatedAt = DateTime.UtcNow;
    }
}
EOF

# DI Extensions para API
cat > "$MODULE_PATH/$APPLICATION_NAME.$MODULE_NAME.Api/Extensions/ServiceCollectionExtensions.cs" << EOF
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Configuration;
using MediatR;
using FluentValidation;
using System.Reflection;
using $ROOT_NAMESPACE.$MODULE_NAME.Infrastructure.Extensions;

namespace $ROOT_NAMESPACE.$MODULE_NAME.Api.Extensions;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection Add${MODULE_NAME}Module(this IServiceCollection services, IConfiguration configuration)
    {
        // Registrar infraestructura del módulo (DbContext, repositorios, etc.)
        services.Add${MODULE_NAME}Infrastructure(configuration);

        // Registrar MediatR para el módulo
        services.AddMediatR(cfg => cfg.RegisterServicesFromAssembly(
            Assembly.GetAssembly(typeof($ROOT_NAMESPACE.$MODULE_NAME.Application.AssemblyMarker))!));

        // Registrar validadores del módulo
        services.AddValidatorsFromAssembly(
            Assembly.GetAssembly(typeof($ROOT_NAMESPACE.$MODULE_NAME.Application.AssemblyMarker))!);

        return services;
    }
}
EOF

# ApplicationBuilderExtensions para API del módulo
cat > "$MODULE_PATH/$APPLICATION_NAME.$MODULE_NAME.Api/Extensions/ApplicationBuilderExtensions.cs" << EOF
using Microsoft.AspNetCore.Builder;

namespace $ROOT_NAMESPACE.$MODULE_NAME.Api.Extensions;

public static class ApplicationBuilderExtensions
{
    public static IApplicationBuilder Use${MODULE_NAME}Module(this IApplicationBuilder app)
    {
        // Configuración del pipeline específica del módulo si se requiere
        return app;
    }
}
EOF

# DI Extensions para Infrastructure
cat > "$MODULE_PATH/$APPLICATION_NAME.$MODULE_NAME.Infrastructure/Extensions/ServiceCollectionExtensions.cs" << EOF
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Configuration;
using Microsoft.EntityFrameworkCore;
using $ROOT_NAMESPACE.$MODULE_NAME.Domain.Abstractions;
using $ROOT_NAMESPACE.$MODULE_NAME.Infrastructure.Persistence;
using $ROOT_NAMESPACE.$MODULE_NAME.Infrastructure.Persistence.Repositories;
using $ROOT_NAMESPACE.SharedKernel.Interfaces;

namespace $ROOT_NAMESPACE.$MODULE_NAME.Infrastructure.Extensions;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection Add${MODULE_NAME}Infrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        // Registrar DbContext específico del módulo
        services.AddDbContext<${MODULE_NAME}DbContext>(options =>
            options.UseNpgsql(configuration.GetConnectionString("DefaultConnection")));

        // NOTA: IUnitOfWork ahora se resuelve automáticamente via UnitOfWorkFactory
        // services.AddScoped<IUnitOfWork>(provider => provider.GetRequiredService<${MODULE_NAME}DbContext>());

        // Registrar repositorios
        services.AddScoped<I${MODULE_NAME}Repository, ${MODULE_NAME}Repository>();

        return services;
    }
    }
}
EOF

# Sample Entity
cat > "$MODULE_PATH/$APPLICATION_NAME.$MODULE_NAME.Domain/Entities/${MODULE_NAME}Entity.cs" << EOF
using $ROOT_NAMESPACE.SharedKernel.Common;

namespace $ROOT_NAMESPACE.$MODULE_NAME.Domain.Entities;

public class ${MODULE_NAME}Entity : BaseEntity
{
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    
    // TODO: Agregar propiedades específicas del dominio
}
EOF

# Sample DTO
cat > "$MODULE_PATH/$APPLICATION_NAME.$MODULE_NAME.Application/DTOs/${MODULE_NAME}Dto.cs" << EOF
namespace $ROOT_NAMESPACE.$MODULE_NAME.Application.DTOs;

public record ${MODULE_NAME}Dto(
    Guid Id,
    string Name,
    string Description,
    DateTime CreatedAt,
    DateTime? UpdatedAt
);
EOF

# Sample Query
mkdir -p "$MODULE_PATH/$APPLICATION_NAME.$MODULE_NAME.Application/Queries/Get${MODULE_NAME}s"

cat > "$MODULE_PATH/$APPLICATION_NAME.$MODULE_NAME.Application/Queries/Get${MODULE_NAME}s/Get${MODULE_NAME}sQuery.cs" << EOF
using MediatR;
using $ROOT_NAMESPACE.$MODULE_NAME.Application.DTOs;

namespace $ROOT_NAMESPACE.$MODULE_NAME.Application.Queries.Get${MODULE_NAME}s;

public record Get${MODULE_NAME}sQuery : IRequest<List<${MODULE_NAME}Dto>>;

public class Get${MODULE_NAME}sHandler : IRequestHandler<Get${MODULE_NAME}sQuery, List<${MODULE_NAME}Dto>>
{
    public async Task<List<${MODULE_NAME}Dto>> Handle(Get${MODULE_NAME}sQuery request, CancellationToken cancellationToken)
    {
        // TODO: Implementar logica de consulta
        await Task.CompletedTask;
        return new List<${MODULE_NAME}Dto>();
    }
}
EOF

# Sample Test
cat > "tests/Unit/$APPLICATION_NAME.$MODULE_NAME.Application.Tests/${MODULE_NAME}HandlerTests.cs" << EOF
using Xunit;
using FluentAssertions;
using $ROOT_NAMESPACE.$MODULE_NAME.Application.Queries.Get${MODULE_NAME}s;

namespace $ROOT_NAMESPACE.$MODULE_NAME.Application.Tests.Queries;

public class Get${MODULE_NAME}sHandlerTests
{
    [Fact]
    public async Task Handle_ShouldReturnEmpty${MODULE_NAME}List_WhenNoDataExists()
    {
        // Arrange
        var handler = new Get${MODULE_NAME}sHandler();
        var query = new Get${MODULE_NAME}sQuery();

        // Act
        var result = await handler.Handle(query, CancellationToken.None);

        // Assert
        result.Should().NotBeNull();
        result.Should().BeEmpty();
    }
}
EOF

echo "Archivos base creados"

# Agregar proyectos a la solución
echo "Agregando proyectos a la solución..."

dotnet sln add "$MODULE_PATH/$APPLICATION_NAME.$MODULE_NAME.Api/$APPLICATION_NAME.$MODULE_NAME.Api.csproj"
dotnet sln add "$MODULE_PATH/$APPLICATION_NAME.$MODULE_NAME.Application/$APPLICATION_NAME.$MODULE_NAME.Application.csproj"
dotnet sln add "$MODULE_PATH/$APPLICATION_NAME.$MODULE_NAME.Domain/$APPLICATION_NAME.$MODULE_NAME.Domain.csproj"
dotnet sln add "$MODULE_PATH/$APPLICATION_NAME.$MODULE_NAME.Infrastructure/$APPLICATION_NAME.$MODULE_NAME.Infrastructure.csproj"
dotnet sln add "tests/Unit/$APPLICATION_NAME.$MODULE_NAME.Application.Tests/$APPLICATION_NAME.$MODULE_NAME.Application.Tests.csproj"

# Intentar agregar referencia al proyecto API principal
echo "Intentando agregar referencia al proyecto principal..."

API_PROJECT_PATH="src/$APPLICATION_NAME.Api/$APPLICATION_NAME.Api.csproj"
MODULE_API_PROJECT_PATH="src/Modules/$MODULE_NAME/$APPLICATION_NAME.$MODULE_NAME.Api/$APPLICATION_NAME.$MODULE_NAME.Api.csproj"

if [ -f "$API_PROJECT_PATH" ]; then
    dotnet add "$API_PROJECT_PATH" reference "$MODULE_API_PROJECT_PATH"
    echo "Referencia agregada exitosamente al proyecto principal"
else
    echo "No se pudo agregar la referencia automáticamente. Agrégala manualmente:"
    echo "dotnet add $API_PROJECT_PATH reference $MODULE_API_PROJECT_PATH"
fi

echo ""
echo "Módulo '$MODULE_NAME' creado exitosamente!"
echo ""
echo "Próximos pasos:"
echo "1. dotnet build"
echo "2. dotnet run --project src/$APPLICATION_NAME.Api"
echo "3. Probar: curl http://localhost:5000/api/$MODULE_NAME"
echo ""
echo "Instrucciones detalladas guardadas en: $MODULE_PATH/README.md"
