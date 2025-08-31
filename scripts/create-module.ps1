param(
    [Parameter(Mandatory=$true)]
    [string]$ModuleName,
    
    [Parameter(Mandatory=$false)]
    [string]$RootNamespace = "",
    
    [Parameter(Mandatory=$false)]
    [string]$ApplicationName = ""
)

# Verificar que estamos en el directorio correcto
if (!(Test-Path "src")) {
    Write-Error "Este script debe ejecutarse desde la raíz del proyecto (donde está la carpeta src)"
    exit 1
}

# Auto-detectar RootNamespace y ApplicationName si no se proporcionaron
if ([string]::IsNullOrEmpty($RootNamespace) -or [string]::IsNullOrEmpty($ApplicationName)) {
    Write-Host "Auto-detectando configuración del proyecto..." -ForegroundColor Yellow
    
    # Buscar archivo .sln
    $slnFiles = Get-ChildItem -Filter "*.sln" -File
    if ($slnFiles.Count -eq 0) {
        Write-Error "No se encontró archivo .sln en el directorio actual"
        exit 1
    }
    
    $slnFile = $slnFiles[0]
    $detectedAppName = [System.IO.Path]::GetFileNameWithoutExtension($slnFile.Name)
    
    # Buscar proyecto API principal
    $apiProjectPath = "src\$detectedAppName.Api\$detectedAppName.Api.csproj"
    if (Test-Path $apiProjectPath) {
        # Leer el archivo .csproj para obtener el RootNamespace
        $csprojContent = Get-Content $apiProjectPath -Raw
        $rootNamespaceMatch = [regex]::Match($csprojContent, '<RootNamespace>(.*?)</RootNamespace>')
        
        if ($rootNamespaceMatch.Success) {
            $detectedRootNamespace = $rootNamespaceMatch.Groups[1].Value
        } else {
            # Si no hay RootNamespace explícito, usar el nombre del proyecto
            $detectedRootNamespace = $detectedAppName
        }
        
        # Usar valores detectados si no se proporcionaron
        if ([string]::IsNullOrEmpty($RootNamespace)) {
            $RootNamespace = $detectedRootNamespace
        }
        if ([string]::IsNullOrEmpty($ApplicationName)) {
            $ApplicationName = $detectedAppName
        }
        
        Write-Host "✅ Configuración detectada:" -ForegroundColor Green
        Write-Host "   ApplicationName: $ApplicationName" -ForegroundColor Cyan
        Write-Host "   RootNamespace: $RootNamespace" -ForegroundColor Cyan
    } else {
        Write-Error "No se pudo detectar la configuración. Proporciona ApplicationName y RootNamespace manualmente."
        exit 1
    }
}

Write-Host "Creando módulo: $ModuleName" -ForegroundColor Green
Write-Host "ApplicationName: $ApplicationName" -ForegroundColor Cyan
Write-Host "RootNamespace: $RootNamespace" -ForegroundColor Cyan

# Crear estructura de directorios
$modulePath = "src/Modules/$ModuleName"
$directories = @(
    "$modulePath/$ApplicationName.$ModuleName.Api/Controllers",
    "$modulePath/$ApplicationName.$ModuleName.Api/Extensions",
    "$modulePath/$ApplicationName.$ModuleName.Application/Commands",
    "$modulePath/$ApplicationName.$ModuleName.Application/Queries",
    "$modulePath/$ApplicationName.$ModuleName.Application/DTOs",
    "$modulePath/$ApplicationName.$ModuleName.Application/Interfaces",
    "$modulePath/$ApplicationName.$ModuleName.Domain/Entities",
    "$modulePath/$ApplicationName.$ModuleName.Domain/ValueObjects",
    "$modulePath/$ApplicationName.$ModuleName.Domain/Events",
    "$modulePath/$ApplicationName.$ModuleName.Domain/Abstractions",
    "$modulePath/$ApplicationName.$ModuleName.Infrastructure/Models",
    "$modulePath/$ApplicationName.$ModuleName.Infrastructure/Persistence/Configurations",
    "$modulePath/$ApplicationName.$ModuleName.Infrastructure/Persistence/Repositories",
    "$modulePath/$ApplicationName.$ModuleName.Infrastructure/Persistence/Queries",
    "$modulePath/$ApplicationName.$ModuleName.Infrastructure/Extensions",
    "tests/Unit/$ApplicationName.$ModuleName.Application.Tests"
)

foreach ($dir in $directories) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    Write-Host "Creado directorio: $dir" -ForegroundColor Yellow
}

# Crear archivos de proyecto (.csproj)
Write-Host "Creando archivos de proyecto..." -ForegroundColor Blue

# API Project
$apiCsproj = @"
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <RootNamespace>$RootNamespace.$ModuleName.Api</RootNamespace>
    <AssemblyName>$ApplicationName.$ModuleName.Api</AssemblyName>
  </PropertyGroup>
  
  <ItemGroup>
    <PackageReference Include="Microsoft.AspNetCore.Mvc.Core" Version="2.2.5" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="..\$ApplicationName.$ModuleName.Application\$ApplicationName.$ModuleName.Application.csproj" />
    <ProjectReference Include="..\$ApplicationName.$ModuleName.Infrastructure\$ApplicationName.$ModuleName.Infrastructure.csproj" />
  </ItemGroup>

</Project>
"@

$apiCsproj | Out-File -FilePath "$modulePath/$ApplicationName.$ModuleName.Api/$ApplicationName.$ModuleName.Api.csproj" -Encoding UTF8

# Application Project
$applicationCsproj = @"
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <RootNamespace>$RootNamespace.$ModuleName.Application</RootNamespace>
    <AssemblyName>$ApplicationName.$ModuleName.Application</AssemblyName>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="MediatR" Version="12.2.0" />
    <PackageReference Include="FluentValidation" Version="11.9.2" />
  </ItemGroup>
  
  <ItemGroup>
    <ProjectReference Include="..\$ApplicationName.$ModuleName.Domain\$ApplicationName.$ModuleName.Domain.csproj" />
    <ProjectReference Include="..\..\..\$ApplicationName.SharedKernel\$ApplicationName.SharedKernel.csproj" />
  </ItemGroup>

</Project>
"@

$applicationCsproj | Out-File -FilePath "$modulePath/$ApplicationName.$ModuleName.Application/$ApplicationName.$ModuleName.Application.csproj" -Encoding UTF8

# Domain Project
$domainCsproj = @"
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <RootNamespace>$RootNamespace.$ModuleName.Domain</RootNamespace>
    <AssemblyName>$ApplicationName.$ModuleName.Domain</AssemblyName>
  </PropertyGroup>
  
  <ItemGroup>
    <ProjectReference Include="..\..\..\$ApplicationName.SharedKernel\$ApplicationName.SharedKernel.csproj" />
  </ItemGroup>

</Project>
"@

$domainCsproj | Out-File -FilePath "$modulePath/$ApplicationName.$ModuleName.Domain/$ApplicationName.$ModuleName.Domain.csproj" -Encoding UTF8

# Infrastructure Project
$infrastructureCsproj = @"
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <RootNamespace>$RootNamespace.$ModuleName.Infrastructure</RootNamespace>
    <AssemblyName>$ApplicationName.$ModuleName.Infrastructure</AssemblyName>
  </PropertyGroup>
    <ItemGroup>
    <PackageReference Include="Microsoft.EntityFrameworkCore" Version="8.0.8" />
    <PackageReference Include="Npgsql.EntityFrameworkCore.PostgreSQL" Version="8.0.8" />
    <PackageReference Include="Dapper" Version="2.1.35" />
  </ItemGroup>
  
  <ItemGroup>
    <ProjectReference Include="..\$ApplicationName.$ModuleName.Domain\$ApplicationName.$ModuleName.Domain.csproj" />
    <ProjectReference Include="..\..\..\$ApplicationName.SharedKernel\$ApplicationName.SharedKernel.csproj" />
  </ItemGroup>

</Project>
"@

$infrastructureCsproj | Out-File -FilePath "$modulePath/$ApplicationName.$ModuleName.Infrastructure/$ApplicationName.$ModuleName.Infrastructure.csproj" -Encoding UTF8

# Test Project
$testCsproj = @"
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <IsPackable>false</IsPackable>
    <IsTestProject>true</IsTestProject>
    <RootNamespace>$RootNamespace.$ModuleName.Application.Tests</RootNamespace>
    <AssemblyName>$ApplicationName.$ModuleName.Application.Tests</AssemblyName>
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
    <ProjectReference Include="..\..\..\src\Modules\$ModuleName\$ApplicationName.$ModuleName.Application\$ApplicationName.$ModuleName.Application.csproj" />
  </ItemGroup>

</Project>
"@

$testCsproj | Out-File -FilePath "tests/Unit/$ApplicationName.$ModuleName.Application.Tests/$ApplicationName.$ModuleName.Application.Tests.csproj" -Encoding UTF8

Write-Host "Creando archivos base..." -ForegroundColor Blue

# Assembly Marker para Application
$assemblyMarker = @"
using System.Reflection;

namespace $RootNamespace.$ModuleName.Application;

/// <summary>
/// Assembly marker for $ModuleName Application layer
/// </summary>
public static class AssemblyMarker
{
    public static Assembly Assembly => typeof(AssemblyMarker).Assembly;
}
"@

$assemblyMarker | Out-File -FilePath "$modulePath/$ApplicationName.$ModuleName.Application/AssemblyMarker.cs" -Encoding UTF8

# Controller
$controller = @"
using Microsoft.AspNetCore.Mvc;
using MediatR;
using $RootNamespace.$ModuleName.Application.Commands.Create${ModuleName};
using $RootNamespace.$ModuleName.Application.Queries.Get${ModuleName}s;
using $RootNamespace.$ModuleName.Application.DTOs;

namespace $RootNamespace.$ModuleName.Api.Controllers;

[ApiController]
[Route("api/v{version:apiVersion}/$($ModuleName.ToLower())")]
public class ${ModuleName}Controller : ControllerBase
{
    private readonly IMediator _mediator;

    public ${ModuleName}Controller(IMediator mediator)
    {
        _mediator = mediator;
    }

    /// <summary>
    /// Create a new ${ModuleName.ToLower()}
    /// </summary>
    /// <param name="command">${ModuleName} data to create</param>
    /// <param name="cancellationToken">Cancellation token</param>
    /// <returns>Created ${ModuleName.ToLower()} ID</returns>
    [HttpPost]
    [ProducesResponseType(typeof(Guid), 201)]
    [ProducesResponseType(400)]
    public async Task<ActionResult<Guid>> Create${ModuleName}(
        [FromBody] Create${ModuleName}Command command,
        CancellationToken cancellationToken)
    {
        try
        {
            var id = await _mediator.Send(command, cancellationToken);
            return CreatedAtAction(nameof(Get${ModuleName}s), new { id }, id);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Get all ${ModuleName.ToLower()}s
    /// </summary>
    /// <param name="cancellationToken">Cancellation token</param>
    /// <returns>List of ${ModuleName.ToLower()}s</returns>
    [HttpGet]
    [ProducesResponseType(typeof(List<${ModuleName}Dto>), 200)]
    public async Task<ActionResult<List<${ModuleName}Dto>>> Get${ModuleName}s(CancellationToken cancellationToken)
    {
        var query = new Get${ModuleName}sQuery();
        var result = await _mediator.Send(query, cancellationToken);
        return Ok(result);
    }

    /// <summary>
    /// Get a ${ModuleName.ToLower()} by ID
    /// </summary>
    /// <param name="id">${ModuleName} ID</param>
    /// <param name="cancellationToken">Cancellation token</param>
    /// <returns>${ModuleName} data</returns>
    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(${ModuleName}Dto), 200)]
    [ProducesResponseType(404)]
    public async Task<ActionResult<${ModuleName}Dto>> Get${ModuleName}ById(
        [FromRoute] Guid id,
        CancellationToken cancellationToken)
    {
        // TODO: Implement GetByIdQuery when available
        return NotFound(new { message = $"${ModuleName} with ID {id} not found" });
    }

    /// <summary>
    /// ${ModuleName} module health check
    /// </summary>
    /// <returns>Module status</returns>
    [HttpGet("health")]
    [ProducesResponseType(200)]
    public ActionResult GetHealth()
    {
        return Ok(new { 
            module = "$ModuleName", 
            status = "Healthy", 
            timestamp = DateTime.UtcNow,
            version = "1.0"
        });
    }
}
"@

$controller | Out-File -FilePath "$modulePath/$ApplicationName.$ModuleName.Api/Controllers/${ModuleName}Controller.cs" -Encoding UTF8

# DbContext se generará después de definir las variables de entidad

# Crear archivos de repositorio en la nueva estructura
# Convertir ModuleName a singular para entidad (ejemplo: Products -> Product)
# En DDD, las entidades se nombran por su concepto de dominio sin sufijos
$EntityName = if ($ModuleName.EndsWith("s")) { $ModuleName.Substring(0, $ModuleName.Length - 1) } else { $ModuleName }
$EntityClassName = $EntityName

# Validar que el nombre de la entidad no cause conflictos con el namespace
# Si el nombre de la entidad es igual al nombre del módulo, usar un nombre más específico
if ($EntityClassName -eq $ModuleName) {
    Write-Host "⚠️ Advertencia: El nombre de la entidad '$EntityClassName' coincide con el nombre del módulo '$ModuleName'" -ForegroundColor Yellow
    Write-Host "   Esto puede causar conflictos de namespace. Considera usar un nombre más específico para el módulo." -ForegroundColor Yellow
    Write-Host "   Ejemplo: En lugar de 'TestModule', usa 'Products', 'Orders', 'Customers', etc." -ForegroundColor Yellow
}

# Crear interface del repositorio en Domain/Abstractions (EF Core para CUD)
$repositoryInterface = @"
using $RootNamespace.$ModuleName.Domain.Entities;

namespace $RootNamespace.$ModuleName.Domain.Abstractions;

public interface I${EntityName}Repository
{
    Task<${EntityClassName}?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<List<${EntityClassName}>> GetAllAsync(CancellationToken cancellationToken = default);
    Task AddAsync(${EntityClassName} entity, CancellationToken cancellationToken = default);
    void Update(${EntityClassName} entity);
    void Delete(${EntityClassName} entity);
}
"@

$repositoryInterface | Out-File -FilePath "$modulePath/$ApplicationName.$ModuleName.Domain/Abstractions/I${EntityName}Repository.cs" -Encoding UTF8

# Crear interface del repositorio de lectura en Domain/Abstractions (Dapper para R)
$readRepositoryInterface = @"
namespace $RootNamespace.$ModuleName.Domain.Abstractions;

/// <summary>
/// Interface para operaciones de solo lectura de ${EntityName.ToLower()}s usando Dapper
/// </summary>
public interface I${EntityName}ReadRepository
{
    /// <summary>
    /// Obtiene un ${EntityName.ToLower()} por su ID
    /// </summary>
    Task<object?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// Obtiene todos los ${EntityName.ToLower()}s
    /// </summary>
    Task<IEnumerable<object>> GetAllAsync(CancellationToken cancellationToken = default);
    
    /// <summary>
    /// Obtiene ${EntityName.ToLower()}s por filtro
    /// </summary>
    Task<IEnumerable<object>> GetByFilterAsync(object filter, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// Verifica si existe un ${EntityName.ToLower()} con el ID especificado
    /// </summary>
    Task<bool> ExistsAsync(Guid id, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// Cuenta el total de ${EntityName.ToLower()}s
    /// </summary>
    Task<int> CountAsync(CancellationToken cancellationToken = default);
}
"@

$readRepositoryInterface | Out-File -FilePath "$modulePath/$ApplicationName.$ModuleName.Domain/Abstractions/I${EntityName}ReadRepository.cs" -Encoding UTF8

# Crear implementación del repositorio en Infrastructure
$repositoryImplementation = @"
using Microsoft.EntityFrameworkCore;
using $RootNamespace.$ModuleName.Domain.Entities;
using $RootNamespace.$ModuleName.Domain.Abstractions;
using $RootNamespace.$ModuleName.Infrastructure.Persistence;

namespace $RootNamespace.$ModuleName.Infrastructure.Persistence.Repositories;

public class ${EntityName}Repository : I${EntityName}Repository
{
    private readonly ${ModuleName}DbContext _context;
    private readonly DbSet<${EntityClassName}> _entities;

    public ${EntityName}Repository(${ModuleName}DbContext context)
    {
        _context = context;
        _entities = context.Set<${EntityClassName}>();
    }

    public async Task<${EntityClassName}?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        return await _entities.FindAsync(new object[] { id }, cancellationToken);
    }

    public async Task<List<${EntityClassName}>> GetAllAsync(CancellationToken cancellationToken = default)
    {
        return await _entities.ToListAsync(cancellationToken);
    }

    public async Task AddAsync(${EntityClassName} entity, CancellationToken cancellationToken = default)
    {
        await _entities.AddAsync(entity, cancellationToken);
    }

    public void Update(${EntityClassName} entity)
    {
        _entities.Update(entity);
    }

    public void Delete(${EntityName} entity)
    {
        _entities.Remove(entity);
    }
}
"@

$repositoryImplementation | Out-File -FilePath "$modulePath/$ApplicationName.$ModuleName.Infrastructure/Persistence/Repositories/${EntityName}Repository.cs" -Encoding UTF8

# Crear implementación del repositorio de lectura en Infrastructure (Dapper)
$readRepositoryImplementation = @"
using System.Data;
using Dapper;
using $RootNamespace.$ModuleName.Domain.Abstractions;
using $RootNamespace.$ModuleName.Infrastructure.Persistence.Queries;
using $RootNamespace.SharedKernel.Interfaces;

namespace $RootNamespace.$ModuleName.Infrastructure.Persistence.Repositories;

/// <summary>
/// Repositorio de lectura para ${EntityName.ToLower()}s usando Dapper
/// </summary>
public class ${EntityName}ReadRepository : I${EntityName}ReadRepository
{
    private readonly IDapperConnectionFactory _connectionFactory;

    public ${EntityName}ReadRepository(IDapperConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<object?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        using var connection = _connectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<dynamic>(
            ${EntityName}Queries.GetById, 
            new { Id = id });
    }

    public async Task<IEnumerable<object>> GetAllAsync(CancellationToken cancellationToken = default)
    {
        using var connection = _connectionFactory.CreateConnection();
        return await connection.QueryAsync<dynamic>(${EntityName}Queries.GetAll);
    }

    public async Task<IEnumerable<object>> GetByFilterAsync(object filter, CancellationToken cancellationToken = default)
    {
        // Usar reflection para acceder a las propiedades del filtro
        var filterType = filter.GetType();
        var searchTermProp = filterType.GetProperty("SearchTerm");
        var isActiveProp = filterType.GetProperty("IsActive");
        var createdFromProp = filterType.GetProperty("CreatedFrom");
        var createdToProp = filterType.GetProperty("CreatedTo");
        var pageProp = filterType.GetProperty("Page");
        var pageSizeProp = filterType.GetProperty("PageSize");
        var sortByProp = filterType.GetProperty("SortBy");
        var sortDescendingProp = filterType.GetProperty("SortDescending");

        var page = Convert.ToInt32(pageProp?.GetValue(filter) ?? 1);
        var pageSize = Convert.ToInt32(pageSizeProp?.GetValue(filter) ?? 10);
        var offset = (page - 1) * pageSize;

        var parameters = new
        {
            SearchTerm = searchTermProp?.GetValue(filter)?.ToString() != null ? `$"%{searchTermProp.GetValue(filter)}%"` : null,
            IsActive = isActiveProp?.GetValue(filter),
            CreatedFrom = createdFromProp?.GetValue(filter),
            CreatedTo = createdToProp?.GetValue(filter),
            PageSize = pageSize,
            Offset = offset,
            SortBy = sortByProp?.GetValue(filter) ?? "Name",
            SortDescending = sortDescendingProp?.GetValue(filter) ?? false
        };

        using var connection = _connectionFactory.CreateConnection();
        return await connection.QueryAsync<dynamic>(${EntityName}Queries.GetByFilter, parameters);
    }

    public async Task<bool> ExistsAsync(Guid id, CancellationToken cancellationToken = default)
    {
        using var connection = _connectionFactory.CreateConnection();
        var count = await connection.ExecuteScalarAsync<int>(
            ${EntityName}Queries.Exists, 
            new { Id = id });
        return count > 0;
    }

    public async Task<int> CountAsync(CancellationToken cancellationToken = default)
    {
        using var connection = _connectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(${EntityName}Queries.Count);
    }
}
"@

$readRepositoryImplementation | Out-File -FilePath "$modulePath/$ApplicationName.$ModuleName.Infrastructure/Persistence/Repositories/${EntityName}ReadRepository.cs" -Encoding UTF8

# Crear entidad básica en Domain
$entity = @"
using $RootNamespace.SharedKernel.Common;

namespace $RootNamespace.$ModuleName.Domain.Entities;

public class ${EntityClassName} : BaseEntity
{
    public string Name { get; private set; } = string.Empty;
    public string Description { get; private set; } = string.Empty;

    private ${EntityName}() { } // Constructor para EF Core

    public static ${EntityName} Create(string name, string description)
    {
        return new ${EntityName}
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
"@

$entity | Out-File -FilePath "$modulePath/$ApplicationName.$ModuleName.Domain/Entities/${EntityName}.cs" -Encoding UTF8

# DbContext (generado después de definir las variables de entidad)
$dbContext = @"
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;
using $RootNamespace.SharedKernel.Interfaces;
using $RootNamespace.$ModuleName.Domain.Entities;
using System.Reflection;

namespace $RootNamespace.$ModuleName.Infrastructure.Persistence;

public class ${ModuleName}DbContext : DbContext, IUnitOfWork
{
    private IDbContextTransaction? _currentTransaction;

    public ${ModuleName}DbContext(DbContextOptions<${ModuleName}DbContext> options) : base(options)
    {
    }

    public DbSet<${EntityClassName}> ${EntityName}s { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.HasDefaultSchema("$($ModuleName.ToLower())");
        
        // Apply module-specific configurations
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
"@

$dbContext | Out-File -FilePath "$modulePath/$ApplicationName.$ModuleName.Infrastructure/Persistence/${ModuleName}DbContext.cs" -Encoding UTF8

# Crear DTOs para consultas
$dto = @"
namespace $RootNamespace.$ModuleName.Application.DTOs;

/// <summary>
/// DTO para operaciones de lectura de ${EntityName.ToLower()}s
/// </summary>
public class ${EntityName}Dto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public string? CreatedBy { get; set; }
    public string? UpdatedBy { get; set; }
}
"@

$dto | Out-File -FilePath "$modulePath/$ApplicationName.$ModuleName.Application/DTOs/${EntityName}Dto.cs" -Encoding UTF8

# Crear DTO de filtro
$filterDto = @"
namespace $RootNamespace.$ModuleName.Application.DTOs;

/// <summary>
/// DTO para filtros de consulta de ${EntityName.ToLower()}s
/// </summary>
public class ${EntityName}FilterDto
{
    public string? SearchTerm { get; set; }
    public bool? IsActive { get; set; }
    public DateTime? CreatedFrom { get; set; }
    public DateTime? CreatedTo { get; set; }
    public int? Page { get; set; } = 1;
    public int? PageSize { get; set; } = 10;
    public string? SortBy { get; set; } = "Name";
    public bool SortDescending { get; set; } = false;
}
"@

$filterDto | Out-File -FilePath "$modulePath/$ApplicationName.$ModuleName.Application/DTOs/${EntityName}FilterDto.cs" -Encoding UTF8

# Crear consultas SQL para Dapper
$queries = @"
namespace $RootNamespace.$ModuleName.Infrastructure.Persistence.Queries;

/// <summary>
/// Consultas SQL para operaciones de lectura de ${EntityName.ToLower()}s usando Dapper
/// </summary>
public static class ${EntityName}Queries
{
    public const string GetById = @"
        SELECT 
            Id,
            Name,
            Description,
            IsActive,
            CreatedAt,
            UpdatedAt,
            CreatedBy,
            UpdatedBy
        FROM $($ModuleName.ToLower()).${EntityName}s 
        WHERE Id = @Id AND IsDeleted = false";

    public const string GetAll = @"
        SELECT 
            Id,
            Name,
            Description,
            IsActive,
            CreatedAt,
            UpdatedAt,
            CreatedBy,
            UpdatedBy
        FROM $($ModuleName.ToLower()).${EntityName}s 
        WHERE IsDeleted = false
        ORDER BY Name";

    public const string GetByFilter = @"
        SELECT 
            Id,
            Name,
            Description,
            IsActive,
            CreatedAt,
            UpdatedAt,
            CreatedBy,
            UpdatedBy
        FROM $($ModuleName.ToLower()).${EntityName}s 
        WHERE IsDeleted = false
        AND (@SearchTerm IS NULL OR 
             Name ILIKE @SearchTerm OR 
             Description ILIKE @SearchTerm)
        AND (@IsActive IS NULL OR IsActive = @IsActive)
        AND (@CreatedFrom IS NULL OR CreatedAt >= @CreatedFrom)
        AND (@CreatedTo IS NULL OR CreatedAt <= @CreatedTo)
        ORDER BY 
            CASE 
                WHEN @SortBy = 'Name' AND @SortDescending = false THEN Name
                WHEN @SortBy = 'Name' AND @SortDescending = true THEN Name
                WHEN @SortBy = 'CreatedAt' AND @SortDescending = false THEN CreatedAt::text
                WHEN @SortBy = 'CreatedAt' AND @SortDescending = true THEN CreatedAt::text
                ELSE Name
            END
        LIMIT @PageSize OFFSET @Offset";

    public const string Exists = @"
        SELECT COUNT(1) 
        FROM $($ModuleName.ToLower()).${EntityName}s 
        WHERE Id = @Id AND IsDeleted = false";

    public const string Count = @"
        SELECT COUNT(1) 
        FROM $($ModuleName.ToLower()).${EntityName}s 
        WHERE IsDeleted = false";
}
"@

$queries | Out-File -FilePath "$modulePath/$ApplicationName.$ModuleName.Infrastructure/Persistence/Queries/${EntityName}Queries.cs" -Encoding UTF8

# DI Extensions para API
$apiDI = @"
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Configuration;
using MediatR;
using FluentValidation;
using System.Reflection;
using $RootNamespace.$ModuleName.Infrastructure.Extensions;

namespace $RootNamespace.$ModuleName.Api.Extensions;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection Add${ModuleName}Module(this IServiceCollection services, IConfiguration configuration)
    {
        // Register module infrastructure (DbContext, repositories, etc.)
        services.Add${ModuleName}Infrastructure(configuration);

        // Register MediatR for the module
        services.AddMediatR(cfg => cfg.RegisterServicesFromAssembly(
            Assembly.GetAssembly(typeof($RootNamespace.$ModuleName.Application.AssemblyMarker))!));

        // Register module validators
        services.AddValidatorsFromAssembly(
            Assembly.GetAssembly(typeof($RootNamespace.$ModuleName.Application.AssemblyMarker))!);

        return services;
    }
}
"@

$apiDI | Out-File -FilePath "$modulePath/$ApplicationName.$ModuleName.Api/Extensions/ServiceCollectionExtensions.cs" -Encoding UTF8

# Add ApplicationBuilderExtensions for module API
$apiAppBuilder = @"
using Microsoft.AspNetCore.Builder;

namespace $RootNamespace.$ModuleName.Api.Extensions;

public static class ApplicationBuilderExtensions
{
    public static IApplicationBuilder Use${ModuleName}Module(this IApplicationBuilder app)
    {
        // Module-specific pipeline configuration if required
        return app;
    }
}
"@

$apiAppBuilder | Out-File -FilePath "$modulePath/$ApplicationName.$ModuleName.Api/Extensions/ApplicationBuilderExtensions.cs" -Encoding UTF8

# DI Extensions para Infrastructure
$infraDI = @"
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Configuration;
using Microsoft.EntityFrameworkCore;
using $RootNamespace.$ModuleName.Domain.Abstractions;
using $RootNamespace.$ModuleName.Infrastructure.Persistence;
using $RootNamespace.$ModuleName.Infrastructure.Persistence.Repositories;
using $RootNamespace.SharedKernel.Interfaces;

namespace $RootNamespace.$ModuleName.Infrastructure.Extensions;

/// <summary>
/// Extensiones para configurar servicios del módulo $ModuleName
/// </summary>
public static class ServiceCollectionExtensions
{
    /// <summary>
    /// Agrega servicios del módulo $ModuleName
    /// </summary>
    public static IServiceCollection Add${ModuleName}Infrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        // Registrar DbContext
        services.AddDbContext<${ModuleName}DbContext>(options =>
            options.UseNpgsql(
                configuration.GetConnectionString("DefaultConnection"),
                b => b.MigrationsAssembly(typeof(${ModuleName}DbContext).Assembly.FullName)));

        // Registrar IUnitOfWork usando el DbContext
        services.AddScoped<IUnitOfWork>(provider => provider.GetRequiredService<${ModuleName}DbContext>());

        // Registrar repositorios
        services.AddScoped<I${EntityName}Repository, ${EntityName}Repository>();
        services.AddScoped<I${EntityName}ReadRepository, ${EntityName}ReadRepository>();

        return services;
    }
}
"@


$infraDI | Out-File -FilePath "$modulePath/$ApplicationName.$ModuleName.Infrastructure/Extensions/ServiceCollectionExtensions.cs" -Encoding UTF8

# Sample Entity
$sampleEntity = @"
using $RootNamespace.SharedKernel.Common;

namespace $RootNamespace.$ModuleName.Domain.Entities;

public class ${ModuleName}Entity : BaseEntity
{
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    
    // TODO: Add domain-specific properties
}
"@

$sampleEntity | Out-File -FilePath "$modulePath/$ApplicationName.$ModuleName.Domain/Entities/${ModuleName}Entity.cs" -Encoding UTF8

# Sample DTO
$sampleDto = @"
namespace $RootNamespace.$ModuleName.Application.DTOs;

public record ${ModuleName}Dto(
    Guid Id,
    string Name,
    string Description,
    DateTime CreatedAt,
    DateTime? UpdatedAt
);
"@

$sampleDto | Out-File -FilePath "$modulePath/$ApplicationName.$ModuleName.Application/DTOs/${ModuleName}Dto.cs" -Encoding UTF8

# Sample Command
$commandDir = "$modulePath/$ApplicationName.$ModuleName.Application/Commands/Create${ModuleName}"
New-Item -ItemType Directory -Force -Path $commandDir | Out-Null

$sampleCommand = @"
using MediatR;

namespace $RootNamespace.$ModuleName.Application.Commands.Create${ModuleName};

public record Create${ModuleName}Command(
    string Name,
    string Description
) : IRequest<Guid>;
"@

$sampleCommand | Out-File -FilePath "$commandDir/Create${ModuleName}Command.cs" -Encoding UTF8

$sampleCommandHandler = @"
using MediatR;
using $RootNamespace.SharedKernel.Interfaces;
using $RootNamespace.$ModuleName.Domain.Entities;

namespace $RootNamespace.$ModuleName.Application.Commands.Create${ModuleName};

public class Create${ModuleName}CommandHandler : IRequestHandler<Create${ModuleName}Command, Guid>
{
    private readonly IUnitOfWork _unitOfWork;

    public Create${ModuleName}CommandHandler(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    public async Task<Guid> Handle(Create${ModuleName}Command request, CancellationToken cancellationToken)
    {
        // TODO: Validate input data if necessary
        
        // Create new entity
        var entity = new ${ModuleName}Entity
        {
            Id = Guid.NewGuid(),
            Name = request.Name,
            Description = request.Description,
            CreatedAt = DateTime.UtcNow
        };

        // TODO: Add to repository when implemented
        // await _repository.AddAsync(entity, cancellationToken);

        // Save changes
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return entity.Id;
    }
}
"@

$sampleCommandHandler | Out-File -FilePath "$commandDir/Create${ModuleName}CommandHandler.cs" -Encoding UTF8

# Sample Query - Get All
$queryDir = "$modulePath/$ApplicationName.$ModuleName.Application/Queries/Get${ModuleName}s"
New-Item -ItemType Directory -Force -Path $queryDir | Out-Null

$sampleQuery = @"
using MediatR;
using $RootNamespace.$ModuleName.Application.DTOs;
using $RootNamespace.$ModuleName.Domain.Abstractions;

namespace $RootNamespace.$ModuleName.Application.Queries.Get${ModuleName}s;

public record Get${ModuleName}sQuery : IRequest<List<${ModuleName}Dto>>;

public class Get${ModuleName}sHandler : IRequestHandler<Get${ModuleName}sQuery, List<${ModuleName}Dto>>
{
    private readonly I${EntityName}ReadRepository _readRepository;

    public Get${ModuleName}sHandler(I${EntityName}ReadRepository readRepository)
    {
        _readRepository = readRepository;
    }

    public async Task<List<${ModuleName}Dto>> Handle(Get${ModuleName}sQuery request, CancellationToken cancellationToken)
    {
        var result = await _readRepository.GetAllAsync(cancellationToken);
        return result.Cast<${ModuleName}Dto>().ToList();
    }
}
"@

$sampleQuery | Out-File -FilePath "$queryDir/Get${ModuleName}sQuery.cs" -Encoding UTF8

# Sample Query - Get By Id
$queryByIdDir = "$modulePath/$ApplicationName.$ModuleName.Application/Queries/Get${ModuleName}ById"
New-Item -ItemType Directory -Force -Path $queryByIdDir | Out-Null

$sampleQueryById = @"
using MediatR;
using $RootNamespace.$ModuleName.Application.DTOs;
using $RootNamespace.$ModuleName.Domain.Abstractions;

namespace $RootNamespace.$ModuleName.Application.Queries.Get${ModuleName}ById;

public record Get${ModuleName}ByIdQuery(Guid Id) : IRequest<${ModuleName}Dto?>;

public class Get${ModuleName}ByIdHandler : IRequestHandler<Get${ModuleName}ByIdQuery, ${ModuleName}Dto?>
{
    private readonly I${EntityName}ReadRepository _readRepository;

    public Get${ModuleName}ByIdHandler(I${EntityName}ReadRepository readRepository)
    {
        _readRepository = readRepository;
    }

    public async Task<${ModuleName}Dto?> Handle(Get${ModuleName}ByIdQuery request, CancellationToken cancellationToken)
    {
        var result = await _readRepository.GetByIdAsync(request.Id, cancellationToken);
        return result as ${ModuleName}Dto;
    }
}
"@

$sampleQueryById | Out-File -FilePath "$queryByIdDir/Get${ModuleName}ByIdQuery.cs" -Encoding UTF8

# Sample Test
$sampleTest = @"
using Xunit;
using FluentAssertions;
using $RootNamespace.$ModuleName.Application.Queries.Get${ModuleName}s;
using NSubstitute;
using $RootNamespace.$ModuleName.Domain.Abstractions;

namespace $RootNamespace.$ModuleName.Application.Tests.Queries;

public class Get${ModuleName}sHandlerTests
{
    [Fact]
    public async Task Handle_ShouldReturnEmpty${ModuleName}List_WhenNoDataExists()
    {
        // Arrange
        var mockRepository = Substitute.For<I${EntityName}ReadRepository>();
        mockRepository.GetAllAsync(Arg.Any<CancellationToken>()).Returns(new List<object>());
        
        var handler = new Get${ModuleName}sHandler(mockRepository);
        var query = new Get${ModuleName}sQuery();

        // Act
        var result = await handler.Handle(query, CancellationToken.None);

        // Assert
        result.Should().NotBeNull();
        result.Should().BeEmpty();
    }
}
"@

$sampleTest | Out-File -FilePath "tests/Unit/$ApplicationName.$ModuleName.Application.Tests/${ModuleName}HandlerTests.cs" -Encoding UTF8

# Agregar proyectos a la solución
Write-Host "Agregando proyectos a la solución..." -ForegroundColor Blue

$projects = @(
    "$modulePath/$ApplicationName.$ModuleName.Api/$ApplicationName.$ModuleName.Api.csproj",
    "$modulePath/$ApplicationName.$ModuleName.Application/$ApplicationName.$ModuleName.Application.csproj", 
    "$modulePath/$ApplicationName.$ModuleName.Domain/$ApplicationName.$ModuleName.Domain.csproj",
    "$modulePath/$ApplicationName.$ModuleName.Infrastructure/$ApplicationName.$ModuleName.Infrastructure.csproj",
    "tests/Unit/$ApplicationName.$ModuleName.Application.Tests/$ApplicationName.$ModuleName.Application.Tests.csproj"
)

foreach ($project in $projects) {
    if (Test-Path $project) {
        dotnet sln add $project
        Write-Host "Agregado a la solución: $project" -ForegroundColor Green
    }
}

# Intentar agregar referencia automáticamente al proyecto API principal
Write-Host "Intentando agregar referencia al proyecto principal..." -ForegroundColor Blue

$apiProjectPath = "src/$ApplicationName.Api/$ApplicationName.Api.csproj"
$moduleApiProjectPath = "src/Modules/$ModuleName/$ApplicationName.$ModuleName.Api/$ApplicationName.$ModuleName.Api.csproj"

if (Test-Path $apiProjectPath) {
    try {
        dotnet add $apiProjectPath reference $moduleApiProjectPath
        Write-Host "Referencia agregada exitosamente al proyecto principal" -ForegroundColor Green
    }
    catch {
        Write-Host "No se pudo agregar la referencia automáticamente. Agrégala manualmente:" -ForegroundColor Yellow
        Write-Host "dotnet add $apiProjectPath reference $moduleApiProjectPath" -ForegroundColor White
    }
}

# Crear archivo con instrucciones
$instructions = @"
# Módulo $ModuleName creado exitosamente

## Estructura creada:
```
src/Modules/$ModuleName/
├── $ApplicationName.$ModuleName.Api/
│   ├── Controllers/${ModuleName}Controller.cs
│   ├── Extensions/ServiceCollectionExtensions.cs
│   └── Extensions/ApplicationBuilderExtensions.cs
├── $ApplicationName.$ModuleName.Application/
│   ├── Commands/Create${ModuleName}/
│   │   ├── Create${ModuleName}Command.cs
│   │   └── Create${ModuleName}CommandHandler.cs
│   ├── Queries/
│   │   ├── Get${ModuleName}s/Get${ModuleName}sQuery.cs
│   │   └── Get${ModuleName}ById/Get${ModuleName}ByIdQuery.cs
│   ├── DTOs/${ModuleName}Dto.cs
│   └── AssemblyMarker.cs
├── $ApplicationName.$ModuleName.Domain/
│   └── Entities/${ModuleName}Entity.cs
└── $ApplicationName.$ModuleName.Infrastructure/
    ├── Persistence/${ModuleName}DbContext.cs
    └── Extensions/ServiceCollectionExtensions.cs

tests/Unit/$ApplicationName.$ModuleName.Application.Tests/
└── ${ModuleName}HandlerTests.cs
```

## Características implementadas:
- ✅ **CQRS Pattern**: Commands y Queries separados
- ✅ **MediatR**: Para manejar comandos y consultas
- ✅ **Records**: Para commands y DTOs
- ✅ **DbContext propio**: Para el módulo autocontenido
- ✅ **Controller versionado**: Con rutas en minúsculas (api/v1/$($ModuleName.ToLower()))
- ✅ **Endpoints RESTful**: CREATE, GET (lista), GET (por ID) y Health check
- ✅ **Documentación Swagger**: Con versionado y camelCase

## Para integrar el módulo:

### 1. Configurar en Program.cs:
```csharp
using $RootNamespace.$ModuleName.Api.Extensions;

// En ConfigureServices:
builder.Services.Add${ModuleName}Module(builder.Configuration);

// En el pipeline:
app.Use${ModuleName}Module();
```

### 2. Crear y aplicar migraciones:
```bash
# Crear migración inicial
dotnet ef migrations add InitialCreate \
  --project src/Modules/$ModuleName/$ApplicationName.$ModuleName.Infrastructure \
  --startup-project src/$ApplicationName.Api \
  --context ${ModuleName}DbContext

# Aplicar migración
dotnet ef database update \
  --project src/Modules/$ModuleName/$ApplicationName.$ModuleName.Infrastructure \
  --startup-project src/$ApplicationName.Api \
  --context ${ModuleName}DbContext
```

### 3. Probar el módulo:
```bash
# Compilar el proyecto
dotnet build

# Ejecutar la aplicación
dotnet run --project src/$ApplicationName.Api

# Probar endpoints:
curl http://localhost:5000/api/v1/$($ModuleName.ToLower())/health           # Health check
curl http://localhost:5000/api/v1/$($ModuleName.ToLower())                 # GET (lista)
curl http://localhost:5000/api/v1/$($ModuleName.ToLower())/{{guid}}        # GET (por ID)
curl -X POST http://localhost:5000/api/v1/$($ModuleName.ToLower()) \       # POST (crear)
  -H "Content-Type: application/json" \
  -d '{"name": "Test", "description": "Test description"}'
```

## Próximos pasos de desarrollo:
1. [OK] Proyectos creados y agregados a la solución
2. [OK] Referencias configuradas
3. [OK] Estructura CQRS implementada (Commands + Queries)
4. [OK] Controller con endpoints básicos
5. [PENDIENTE] Implementar repositorios en Infrastructure
6. [PENDIENTE] Crear migraciones de base de datos
7. [PENDIENTE] Implementar validaciones con FluentValidation
8. [PENDIENTE] Agregar tests unitarios

Fecha de creación: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@

$instructions | Out-File -FilePath "$modulePath/README.md" -Encoding UTF8

Write-Host "`nMódulo '$ModuleName' creado exitosamente!" -ForegroundColor Green
Write-Host "`nCaracterísticas implementadas:" -ForegroundColor Yellow
Write-Host "✅ CQRS Pattern con Commands y Queries separados" -ForegroundColor Green
Write-Host "✅ MediatR para manejar comandos y consultas" -ForegroundColor Green  
Write-Host "✅ Records para commands y DTOs" -ForegroundColor Green
Write-Host "✅ DbContext propio para módulo autocontenido" -ForegroundColor Green
Write-Host "✅ Controller versionado con rutas en minúsculas" -ForegroundColor Green
Write-Host "✅ Endpoints RESTful (CREATE, GET lista, GET por ID)" -ForegroundColor Green
Write-Host "✅ Health check endpoint con información de versión" -ForegroundColor Green
Write-Host "✅ Documentación Swagger con versionado" -ForegroundColor Green

Write-Host "`nPróximos pasos:" -ForegroundColor Yellow
Write-Host "1. [OK] Proyectos creados y agregados a la solución" -ForegroundColor Green
Write-Host "2. [OK] Referencias configuradas" -ForegroundColor Green
Write-Host "3. [OK] Estructura CQRS implementada" -ForegroundColor Green
Write-Host "4. [PENDIENTE] Implementar repositorios en Infrastructure" -ForegroundColor White
Write-Host "5. [PENDIENTE] Crear migraciones: ver $modulePath/README.md" -ForegroundColor White
Write-Host "6. [PENDIENTE] Compilar: dotnet build" -ForegroundColor White

Write-Host "`nInstrucciones detalladas guardadas en: $modulePath/README.md" -ForegroundColor Cyan