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
    
    # Si el nombre del archivo .sln contiene placeholders, usar valores por defecto
    if ($detectedAppName -like "*__*") {
        Write-Host "⚠️ Detectado template con placeholders. Usando valores por defecto..." -ForegroundColor Yellow
        $detectedAppName = "MonolithTemplate"
        $detectedRootNamespace = "MonolithTemplate"
    } else {
        # Buscar proyecto API principal
        $apiProjectPath = "src\$detectedAppName.Api\$detectedAppName.Api.csproj"
        if (Test-Path $apiProjectPath) {
            # Leer el archivo .csproj para obtener el RootNamespace
            $csprojContent = Get-Content $apiProjectPath -Raw
            $rootNamespaceMatch = [regex]::Match($csprojContent, '<RootNamespace>(.*?)</RootNamespace>')
            
            if ($rootNamespaceMatch.Success) {
                $detectedRootNamespace = $rootNamespaceMatch.Groups[1].Value
                # Si el RootNamespace también contiene placeholders, usar el nombre del proyecto
                if ($detectedRootNamespace -like "*__*") {
                    $detectedRootNamespace = $detectedAppName
                }
            } else {
                # Si no hay RootNamespace explícito, usar el nombre del proyecto
                $detectedRootNamespace = $detectedAppName
            }
        } else {
            Write-Error "No se pudo detectar la configuración. Proporciona ApplicationName y RootNamespace manualmente."
            exit 1
        }
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
    "$modulePath/$ApplicationName.$ModuleName.Application/DTOs/Reports",
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
    <!-- Los paquetes de ASP.NET Core se incluyen automáticamente desde Directory.Build.props -->
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
    <!-- Los paquetes de MediatR y FluentValidation se incluyen automáticamente desde Directory.Build.props -->
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
    <!-- Los paquetes de EF Core y Dapper se incluyen automáticamente desde Directory.Build.props -->
  </ItemGroup>
  
  <ItemGroup>
    <ProjectReference Include="..\$ApplicationName.$ModuleName.Domain\$ApplicationName.$ModuleName.Domain.csproj" />
    <ProjectReference Include="..\$ApplicationName.$ModuleName.Application\$ApplicationName.$ModuleName.Application.csproj" />
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
    <!-- Los paquetes de testing se incluyen automáticamente desde Directory.Build.props -->
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

# Definir EntityName antes de generar el controller
$EntityName = if ($ModuleName.EndsWith("s")) { $ModuleName.Substring(0, $ModuleName.Length - 1) } else { $ModuleName }
$EntityClassName = $EntityName

# Validar que el nombre de la entidad no cause conflictos con el namespace
if ($EntityClassName -eq $ModuleName) {
    Write-Host "⚠️ Advertencia: El nombre de la entidad '$EntityClassName' coincide con el nombre del módulo '$ModuleName'" -ForegroundColor Yellow
    Write-Host "   Esto puede causar conflictos de namespace. Considera usar un nombre más específico para el módulo." -ForegroundColor Yellow
    Write-Host "   Ejemplo: En lugar de 'TestModule', usa 'Products', 'Orders', 'Customers', etc." -ForegroundColor Yellow
}

# Controller
$controller = @"
using Microsoft.AspNetCore.Mvc;
using MediatR;
using $RootNamespace.$ModuleName.Application.Commands.Create${ModuleName};
using $RootNamespace.$ModuleName.Application.Queries.Get${ModuleName}s;
using $RootNamespace.$ModuleName.Application.Queries.Get${ModuleName}ById;
using $RootNamespace.$ModuleName.Application.Queries.Get${ModuleName}Report;
using $RootNamespace.$ModuleName.Application.DTOs;
using $RootNamespace.$ModuleName.Application.DTOs.Reports;

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
    [ProducesResponseType(typeof(long), 201)]
    [ProducesResponseType(400)]
    public async Task<ActionResult<long>> Create${ModuleName}(
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
    [HttpGet("{id:long}")]
    [ProducesResponseType(typeof(${ModuleName}Dto), 200)]
    [ProducesResponseType(404)]
    public async Task<ActionResult<${ModuleName}Dto>> Get${ModuleName}ById(
        [FromRoute] long id,
        CancellationToken cancellationToken)
    {
        try
        {
            var query = new Get${ModuleName}ByIdQuery(id);
            var result = await _mediator.Send(query, cancellationToken);
            
            if (result == null)
                return NotFound(new { message = $"${ModuleName} with ID {id} not found" });
                
            return Ok(result);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
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

    /// <summary>
    /// Get ${ModuleName.ToLower()} report with additional data
    /// </summary>
    /// <param name="cancellationToken">Cancellation token</param>
    /// <returns>${ModuleName} report data</returns>
    [HttpGet("report")]
    [ProducesResponseType(typeof(IEnumerable<${EntityName}ReportDto>), 200)]
    public async Task<ActionResult<IEnumerable<${EntityName}ReportDto>>> Get${ModuleName}Report(CancellationToken cancellationToken)
    {
        try
        {
            var query = new Get${ModuleName}ReportQuery();
            var result = await _mediator.Send(query, cancellationToken);
            
            return Ok(result);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}
"@

$controller | Out-File -FilePath "$modulePath/$ApplicationName.$ModuleName.Api/Controllers/${ModuleName}Controller.cs" -Encoding UTF8

# DbContext se generará después de definir las variables de entidad

# Crear archivos de repositorio en la nueva estructura
# Las variables $EntityName y $EntityClassName ya están definidas arriba

# Crear interface del repositorio en Domain/Abstractions (EF Core para CUD)
$repositoryInterface = @"
using $RootNamespace.$ModuleName.Domain.Entities;

namespace $RootNamespace.$ModuleName.Domain.Abstractions;

public interface I${EntityName}Repository
{
    Task AddAsync(${EntityClassName} entity, CancellationToken cancellationToken = default);
    void Update(${EntityClassName} entity);
    void Delete(${EntityClassName} entity);
}
"@

$repositoryInterface | Out-File -FilePath "$modulePath/$ApplicationName.$ModuleName.Domain/Abstractions/I${EntityName}Repository.cs" -Encoding UTF8

# NO crear interface del repositorio de lectura en Domain/Abstractions
# Solo se crea en Application/Interfaces para mantener Domain limpio

# Crear interface del repositorio de lectura en Application/Interfaces (Dapper para R)
$readRepositoryInterfaceApp = @"
using $RootNamespace.$ModuleName.Application.DTOs;
using $RootNamespace.$ModuleName.Application.DTOs.Reports;

namespace $RootNamespace.$ModuleName.Application.Interfaces;

/// <summary>
/// Interface para operaciones de solo lectura de ${EntityName.ToLower()}s usando Dapper
/// Incluye consultas básicas y reportes en un solo repositorio
/// Retorna DTOs directamente para evitar violar DDD
/// </summary>
public interface I${EntityName}ReadRepository
{
    /// <summary>
    /// Obtiene un ${EntityName.ToLower()} por su ID
    /// </summary>
    Task<${ModuleName}Dto?> GetByIdAsync(long id, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// Obtiene todos los ${EntityName.ToLower()}s
    /// </summary>
    Task<IEnumerable<${ModuleName}Dto>> GetAllAsync(CancellationToken cancellationToken = default);
    
    /// <summary>
    /// Obtiene ${EntityName.ToLower()}s por filtro
    /// </summary>
    Task<IEnumerable<${ModuleName}Dto>> GetByFilterAsync(object filter, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// Verifica si existe un ${EntityName.ToLower()} con el ID especificado
    /// </summary>
    Task<bool> ExistsAsync(long id, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// Cuenta el total de ${EntityName.ToLower()}s
    /// </summary>
    Task<int> CountAsync(CancellationToken cancellationToken = default);
    
    /// <summary>
    /// Reporte básico de ${EntityName.ToLower()}s con datos hardcodeados para pruebas
    /// </summary>
    Task<IEnumerable<${EntityName}ReportDto>> GetBasicReportAsync(CancellationToken cancellationToken = default);
    
    /// <summary>
    /// Reporte de ${EntityName.ToLower()}s con filtros
    /// </summary>
    Task<IEnumerable<${EntityName}ReportDto>> GetFilteredReportAsync(object filter, CancellationToken cancellationToken = default);
}
"@

# NO crear interface separada para reportes - se unifica en I${EntityName}ReadRepository

# Escribir interface del repositorio de lectura en Application/Interfaces (incluye reportes)
$readRepositoryInterfaceApp | Out-File -FilePath "$modulePath/$ApplicationName.$ModuleName.Application/Interfaces/I${EntityName}ReadRepository.cs" -Encoding UTF8

# Crear implementación del repositorio en Infrastructure
$repositoryImplementation = @"
using Microsoft.EntityFrameworkCore;
using $RootNamespace.$ModuleName.Domain.Entities;
using $RootNamespace.$ModuleName.Domain.Abstractions;
using $RootNamespace.$ModuleName.Infrastructure.Persistence;
using Infrastructure${EntityName} = $RootNamespace.$ModuleName.Infrastructure.Models.${EntityName};

namespace $RootNamespace.$ModuleName.Infrastructure.Persistence.Repositories;

/// <summary>
/// Repositorio para operaciones CUD (Create, Update, Delete) usando EF Core
/// Implementa mapeo entre entidad de dominio y modelo de infraestructura
/// </summary>
public class ${EntityName}Repository : I${EntityName}Repository
{
    private readonly ${ModuleName}ExtendedDbContext _context;

    public ${EntityName}Repository(${ModuleName}ExtendedDbContext context)
    {
        _context = context ?? throw new ArgumentNullException(nameof(context));
    }

    public async Task AddAsync(${EntityClassName} entity, CancellationToken cancellationToken = default)
    {
        var model = MapToInfrastructureModel(entity);
        await _context.AddAsync(model, cancellationToken);
        
        // Asignar el ID generado de vuelta a la entidad de dominio
        entity.Id = model.Id;
    }

    public void Update(${EntityClassName} entity)
    {
        var model = MapToInfrastructureModel(entity);
        _context.Update(model);
    }

    public void Delete(${EntityName} entity)
    {
        var model = MapToInfrastructureModel(entity);
        _context.Remove(model);
    }

    /// <summary>
    /// Mapea entidad de dominio a modelo de infraestructura
    /// </summary>
    private Infrastructure${EntityName} MapToInfrastructureModel(${EntityClassName} entity)
    {
        return new Infrastructure${EntityName}
        {
            Id = entity.Id,
            Name = entity.Name,
            Description = entity.Description,
            IsActive = true, // Valor por defecto para nuevas entidades
            CreatedAt = entity.CreatedAt,
            UpdatedAt = entity.UpdatedAt
        };
    }
}
"@

$repositoryImplementation | Out-File -FilePath "$modulePath/$ApplicationName.$ModuleName.Infrastructure/Persistence/Repositories/${EntityName}Repository.cs" -Encoding UTF8

# Crear implementación del repositorio de lectura en Infrastructure (Dapper)
$readRepositoryImplementation = @"
using System.Data;
using Dapper;
using $RootNamespace.$ModuleName.Application.Interfaces;
using $RootNamespace.$ModuleName.Application.DTOs;
using $RootNamespace.$ModuleName.Application.DTOs.Reports;
using $RootNamespace.$ModuleName.Infrastructure.Persistence.Queries;
using $RootNamespace.SharedKernel.Interfaces;

namespace $RootNamespace.$ModuleName.Infrastructure.Persistence.Repositories;

/// <summary>
/// Repositorio de lectura para ${EntityName.ToLower()}s usando Dapper
/// Implementa la interfaz de Application para mantener Domain limpio
/// Incluye consultas básicas y reportes en un solo repositorio
/// </summary>
public class ${EntityName}ReadRepository : I${EntityName}ReadRepository
{
    private readonly IDapperConnectionFactory _connectionFactory;

    public ${EntityName}ReadRepository(IDapperConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<${ModuleName}Dto?> GetByIdAsync(long id, CancellationToken cancellationToken = default)
    {
        // TODO: Implementar con Dapper cuando tengas la base de datos
        // Por ahora retornar datos hardcodeados para pruebas
        
        await Task.Delay(100, cancellationToken); // Simular operación async
        
        // Simular búsqueda por ID
        if (id == 1)
        {
            return new ${ModuleName}Dto
            {
                Id = 1L,
                Name = "Producto de Prueba 1",
                Description = "Descripción del producto de prueba 1",
                IsActive = true,
                CreatedAt = DateTime.UtcNow.AddDays(-30),
                UpdatedAt = DateTime.UtcNow.AddDays(-5)
            };
        }
        
        return null; // No encontrado
    }

    public async Task<IEnumerable<${ModuleName}Dto>> GetAllAsync(CancellationToken cancellationToken = default)
    {
        // TODO: Implementar con Dapper cuando tengas la base de datos
        // Por ahora retornar datos hardcodeados para pruebas
        
        await Task.Delay(100, cancellationToken); // Simular operación async
        
        return new List<${ModuleName}Dto>
        {
            new ${ModuleName}Dto
            {
                Id = 1L,
                Name = "Producto de Prueba 1",
                Description = "Descripción del producto de prueba 1",
                IsActive = true,
                CreatedAt = DateTime.UtcNow.AddDays(-30),
                UpdatedAt = DateTime.UtcNow.AddDays(-5)
            },
            new ${ModuleName}Dto
            {
                Id = 2L,
                Name = "Producto de Prueba 2",
                Description = "Descripción del producto de prueba 2",
                IsActive = true,
                CreatedAt = DateTime.UtcNow.AddDays(-25),
                UpdatedAt = DateTime.UtcNow.AddDays(-3)
            }
        };
    }

    public async Task<IEnumerable<${ModuleName}Dto>> GetByFilterAsync(object filter, CancellationToken cancellationToken = default)
    {
        // TODO: Implementar filtros cuando tengas la base de datos
        // Por ahora retornar el mismo resultado que GetAllAsync
        return await GetAllAsync(cancellationToken);
    }

    public async Task<bool> ExistsAsync(long id, CancellationToken cancellationToken = default)
    {
        // TODO: Implementar con Dapper cuando tengas la base de datos
        // Por ahora retornar datos hardcodeados para pruebas
        await Task.Delay(100, cancellationToken); // Simular operación async
        return id == 1 || id == 2; // Solo existen los IDs 1 y 2
    }

    public async Task<int> CountAsync(CancellationToken cancellationToken = default)
    {
        // TODO: Implementar con Dapper cuando tengas la base de datos
        // Por ahora retornar datos hardcodeados para pruebas
        await Task.Delay(100, cancellationToken); // Simular operación async
        return 2; // Solo tenemos 2 productos de prueba
    }

    public async Task<IEnumerable<${EntityName}ReportDto>> GetBasicReportAsync(CancellationToken cancellationToken = default)
    {
        // TODO: Implementar con Dapper cuando tengas la base de datos
        // Por ahora retornar datos hardcodeados para pruebas
        
        await Task.Delay(100, cancellationToken); // Simular operación async
        
        return new List<${EntityName}ReportDto>
        {
            new ${EntityName}ReportDto
            {
                Id = 1L,
                Name = "Producto de Prueba 1",
                Description = "Descripción del producto de prueba 1",
                IsActive = true,
                CreatedAt = DateTime.UtcNow.AddDays(-30),
                UpdatedAt = DateTime.UtcNow.AddDays(-5),
                Status = "Activo",
                Category = "Electrónicos",
                Price = 99.99m,
                Stock = 50
            },
            new ${EntityName}ReportDto
            {
                Id = 2L,
                Name = "Producto de Prueba 2",
                Description = "Descripción del producto de prueba 2",
                IsActive = true,
                CreatedAt = DateTime.UtcNow.AddDays(-25),
                UpdatedAt = DateTime.UtcNow.AddDays(-3),
                Status = "Activo",
                Category = "Ropa",
                Price = 45.50m,
                Stock = 25
            },
            new ${EntityName}ReportDto
            {
                Id = 3L,
                Name = "Producto de Prueba 3",
                Description = "Descripción del producto de prueba 3",
                IsActive = false,
                CreatedAt = DateTime.UtcNow.AddDays(-20),
                UpdatedAt = DateTime.UtcNow.AddDays(-1),
                Status = "Inactivo",
                Category = "Hogar",
                Price = 75.00m,
                Stock = 0
            }
        };
    }

    public async Task<IEnumerable<${EntityName}ReportDto>> GetFilteredReportAsync(object filter, CancellationToken cancellationToken = default)
    {
        // TODO: Implementar filtros cuando tengas la base de datos
        // Por ahora retornar el reporte básico
        return await GetBasicReportAsync(cancellationToken);
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
            Description = description,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
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

# DbContext base en Models (será reemplazado por scaffold)
$dbContextBase = @"
using Microsoft.EntityFrameworkCore;

namespace $RootNamespace.$ModuleName.Infrastructure.Models;

/// <summary>
/// DbContext base generado por el script de creación de módulos.
/// Este archivo será reemplazado cuando ejecutes scaffold de la base de datos.
/// 
/// Comando para scaffold:
/// dotnet ef dbcontext scaffold "ConnectionString" Microsoft.EntityFrameworkCore.SqlServer --project src/Modules/$ModuleName/$ApplicationName.$ModuleName.Infrastructure --output-dir Models --context ${ModuleName}DbContext --force
/// </summary>
public partial class ${ModuleName}DbContext : DbContext
{
    public ${ModuleName}DbContext()
    {
    }

    public ${ModuleName}DbContext(DbContextOptions<${ModuleName}DbContext> options) : base(options)
    {
    }

    // Este DbSet será reemplazado por los DbSets generados desde la base de datos
    // public virtual DbSet<${EntityClassName}> ${EntityName}s { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Configuraciones específicas del módulo
        modelBuilder.HasDefaultSchema("$($ModuleName.ToLower())");
        
        base.OnModelCreating(modelBuilder);
    }
}
"@

$dbContextBase | Out-File -FilePath "$modulePath/$ApplicationName.$ModuleName.Infrastructure/Models/${ModuleName}DbContext.cs" -Encoding UTF8

# DbContext extendido en Persistence (con UnitOfWork)
$dbContextExtended = @"
using $RootNamespace.$ModuleName.Infrastructure.Models;
using $RootNamespace.SharedKernel.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;

namespace $RootNamespace.$ModuleName.Infrastructure.Persistence;

/// <summary>
/// DbContext extendido que hereda del DbContext generado por scaffold
/// e implementa la lógica de UnitOfWork para transacciones
/// </summary>
public class ${ModuleName}ExtendedDbContext : ${ModuleName}DbContext, IUnitOfWork
{
    private IDbContextTransaction? _currentTransaction;

    public ${ModuleName}ExtendedDbContext(DbContextOptions<${ModuleName}DbContext> options) : base(options)
    {
    }

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

$dbContextExtended | Out-File -FilePath "$modulePath/$ApplicationName.$ModuleName.Infrastructure/Persistence/${ModuleName}ExtendedDbContext.cs" -Encoding UTF8

# Crear DTOs para consultas
$dto = @"
namespace $RootNamespace.$ModuleName.Application.DTOs;

/// <summary>
/// DTO para operaciones de lectura de ${EntityName.ToLower()}s
/// </summary>
public class ${EntityName}Dto
{
    public long Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
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

# Crear DTOs de reporte
$reportDto = @"
namespace $RootNamespace.$ModuleName.Application.DTOs.Reports;

/// <summary>
/// DTO para reportes de ${EntityName.ToLower()}s
/// Ejemplo: Reporte básico con datos hardcodeados para pruebas
/// </summary>
public class ${EntityName}ReportDto
{
    public long Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    
    // Campos adicionales para reportes (ejemplo)
    public string Status { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public int Stock { get; set; }
}
"@

$filterDto | Out-File -FilePath "$modulePath/$ApplicationName.$ModuleName.Application/DTOs/${EntityName}FilterDto.cs" -Encoding UTF8

# Escribir DTOs de reporte
$reportDto | Out-File -FilePath "$modulePath/$ApplicationName.$ModuleName.Application/DTOs/Reports/${EntityName}ReportDto.cs" -Encoding UTF8

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
            UpdatedAt
        FROM $($ModuleName.ToLower()).${EntityName}s 
        WHERE Id = @Id AND IsDeleted = false";

    public const string GetAll = @"
        SELECT 
            Id,
            Name,
            Description,
            IsActive,
            CreatedAt,
            UpdatedAt
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
            UpdatedAt
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
                WHEN @SortBy = 'Name' AND @SortDescending = true THEN CreatedAt::text
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

# Crear placeholder del modelo en Models
$modelPlaceholder = @"
namespace $RootNamespace.$ModuleName.Infrastructure.Models;

/// <summary>
/// Modelo placeholder para ${EntityName.ToLower()}s
/// Este archivo será reemplazado cuando ejecutes scaffold de la base de datos
/// </summary>
public class ${EntityName}
{
    public long Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}

/// <summary>
/// Modelo de datos para consultas Dapper
/// Usado para mapear resultados de consultas SQL
/// </summary>
public class ${EntityName}Data
{
    public long Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}
"@

$modelPlaceholder | Out-File -FilePath "$modulePath/$ApplicationName.$ModuleName.Infrastructure/Models/${EntityName}.cs" -Encoding UTF8

# Crear archivo placeholder en Models para que Visual Studio reconozca el directorio
$modelsPlaceholder = @"
// Este archivo se crea para que Visual Studio reconozca el directorio Models
// Puedes eliminar este archivo cuando agregues tus propios modelos

namespace $RootNamespace.$ModuleName.Infrastructure.Models;

/// <summary>
/// Placeholder para el directorio Models
/// </summary>
public static class ModelsPlaceholder
{
    // Este directorio está destinado para modelos específicos de infraestructura
    // como modelos para vistas, reportes, o integraciones externas
}
"@

$modelsPlaceholder | Out-File -FilePath "$modulePath/$ApplicationName.$ModuleName.Infrastructure/Models/ModelsPlaceholder.cs" -Encoding UTF8

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
using $RootNamespace.$ModuleName.Application.Interfaces;
using $RootNamespace.$ModuleName.Infrastructure.Persistence;
using $RootNamespace.$ModuleName.Infrastructure.Persistence.Repositories;
using $RootNamespace.$ModuleName.Infrastructure.Models;
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
        // Registrar DbContext base (para scaffold y migraciones)
        services.AddDbContext<Models.${ModuleName}DbContext>(options =>
            options.UseNpgsql(
                configuration.GetConnectionString("DefaultConnection"),
                b => b.MigrationsAssembly(typeof(Models.${ModuleName}DbContext).Assembly.FullName)));

        // Registrar DbContext extendido (para operaciones con UnitOfWork)
        services.AddDbContext<${ModuleName}ExtendedDbContext>(options =>
            options.UseNpgsql(
                configuration.GetConnectionString("DefaultConnection"),
                b => b.MigrationsAssembly(typeof(Models.${ModuleName}DbContext).Assembly.FullName)));

        // Registrar IUnitOfWork usando el DbContext extendido
        services.AddScoped<IUnitOfWork>(provider => provider.GetRequiredService<${ModuleName}ExtendedDbContext>());

        // Registrar repositorios (usar DbContext extendido para operaciones CUD)
        services.AddScoped<I${EntityName}Repository, ${EntityName}Repository>();
        services.AddScoped<I${EntityName}ReadRepository, ${EntityName}ReadRepository>();
        // NO registrar repositorio de reportes separado - se unifica en ${EntityName}ReadRepository

        return services;
    }
}
"@


$infraDI | Out-File -FilePath "$modulePath/$ApplicationName.$ModuleName.Infrastructure/Extensions/ServiceCollectionExtensions.cs" -Encoding UTF8



# Sample DTO
$sampleDto = @"
namespace $RootNamespace.$ModuleName.Application.DTOs;

public class ${ModuleName}Dto
{
    public long Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}
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
) : IRequest<long>;
"@

$sampleCommand | Out-File -FilePath "$commandDir/Create${ModuleName}Command.cs" -Encoding UTF8

$sampleCommandHandler = @"
using MediatR;
using $RootNamespace.SharedKernel.Interfaces;
using $RootNamespace.$ModuleName.Domain.Entities;
using $RootNamespace.$ModuleName.Domain.Abstractions;

namespace $RootNamespace.$ModuleName.Application.Commands.Create${ModuleName};

public class Create${ModuleName}CommandHandler : IRequestHandler<Create${ModuleName}Command, long>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly I${EntityName}Repository _repository;

    public Create${ModuleName}CommandHandler(IUnitOfWork unitOfWork, I${EntityName}Repository repository)
    {
        _unitOfWork = unitOfWork;
        _repository = repository;
    }

    public async Task<long> Handle(Create${ModuleName}Command request, CancellationToken cancellationToken)
    {
        // TODO: Validate input data if necessary
        
        // Create new entity
        var entity = ${EntityName}.Create(request.Name, request.Description);

        // Add to repository
        await _repository.AddAsync(entity, cancellationToken);

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
using $RootNamespace.$ModuleName.Application.Interfaces;

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
        
        if (result == null || !result.Any())
            return new List<${ModuleName}Dto>();
            
        // Ahora retorna DTOs directamente, no hay mapeo necesario
        return result.ToList();
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
using $RootNamespace.$ModuleName.Application.Interfaces;

namespace $RootNamespace.$ModuleName.Application.Queries.Get${ModuleName}ById;

public record Get${ModuleName}ByIdQuery(long Id) : IRequest<${ModuleName}Dto?>;

public class Get${ModuleName}ByIdHandler : IRequestHandler<Get${ModuleName}ByIdQuery, ${ModuleName}Dto?>
{
    private readonly I${EntityName}ReadRepository _readRepository;

    public Get${ModuleName}ByIdHandler(I${EntityName}ReadRepository readRepository)
    {
        _readRepository = readRepository;
    }

    public async Task<${ModuleName}Dto?> Handle(Get${ModuleName}ByIdQuery request, CancellationToken cancellationToken)
    {
        // Ahora retorna DTO directamente, no hay mapeo necesario
        return await _readRepository.GetByIdAsync(request.Id, cancellationToken);
    }
}
"@

$sampleQueryById | Out-File -FilePath "$queryByIdDir/Get${ModuleName}ByIdQuery.cs" -Encoding UTF8

# Sample Query - Get Report
$queryReportDir = "$modulePath/$ApplicationName.$ModuleName.Application/Queries/Get${ModuleName}Report"
New-Item -ItemType Directory -Force -Path $queryReportDir | Out-Null

$sampleQueryReport = @"
using MediatR;
using $RootNamespace.$ModuleName.Application.DTOs.Reports;
using $RootNamespace.$ModuleName.Application.Interfaces;

namespace $RootNamespace.$ModuleName.Application.Queries.Get${ModuleName}Report;

public record Get${ModuleName}ReportQuery : IRequest<IEnumerable<${EntityName}ReportDto>>;

public class Get${ModuleName}ReportHandler : IRequestHandler<Get${ModuleName}ReportQuery, IEnumerable<${EntityName}ReportDto>>
{
    private readonly I${EntityName}ReadRepository _readRepository;

    public Get${ModuleName}ReportHandler(I${EntityName}ReadRepository readRepository)
    {
        _readRepository = readRepository;
    }

    public async Task<IEnumerable<${EntityName}ReportDto>> Handle(Get${ModuleName}ReportQuery request, CancellationToken cancellationToken)
    {
        // Ahora retorna DTOs directamente, no hay mapeo necesario
        return await _readRepository.GetBasicReportAsync(cancellationToken);
    }
}
"@

$sampleQueryReport | Out-File -FilePath "$queryReportDir/Get${ModuleName}ReportQuery.cs" -Encoding UTF8

# Sample Test
$sampleTest = @"
using Xunit;
using FluentAssertions;
using $RootNamespace.$ModuleName.Application.Queries.Get${ModuleName}s;
using Moq;
using $RootNamespace.$ModuleName.Application.Interfaces;
using $RootNamespace.$ModuleName.Application.DTOs;

namespace $RootNamespace.$ModuleName.Application.Tests.Queries;

public class Get${ModuleName}sHandlerTests
{
    [Fact]
    public async Task Handle_ShouldReturnEmpty${ModuleName}List_WhenNoDataExists()
    {
        // Arrange
        var mockRepository = new Mock<I${EntityName}ReadRepository>();
        mockRepository.Setup(x => x.GetAllAsync(It.IsAny<CancellationToken>())).ReturnsAsync(new List<${ModuleName}Dto>());
        
        var handler = new Get${ModuleName}sHandler(mockRepository.Object);
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
│   │   ├── Get${ModuleName}ById/Get${ModuleName}ByIdQuery.cs
│   │   └── Get${ModuleName}Report/Get${ModuleName}ReportQuery.cs
│   ├── DTOs/
│   │   ├── ${ModuleName}Dto.cs
│   │   ├── ${EntityName}FilterDto.cs
│   │   └── Reports/${EntityName}ReportDto.cs
│   ├── Interfaces/
│   │   ├── I${EntityName}ReadRepository.cs
│   │   └── I${EntityName}ReportRepository.cs
│   └── AssemblyMarker.cs
├── $ApplicationName.$ModuleName.Domain/
│   ├── Entities/${EntityName}.cs
│   └── Abstractions/
│       └── I${EntityName}Repository.cs        # Solo CRUD básico
└── $ApplicationName.$ModuleName.Infrastructure/
    ├── Models/
    │   ├── ${ModuleName}DbContext.cs          # ← Base (reemplazado por scaffold)
    │   ├── ${EntityName}.cs                   # ← Placeholder para scaffold
    │   └── ModelsPlaceholder.cs               # ← Eliminar antes de scaffold
    └── Persistence/
        ├── ${ModuleName}ExtendedDbContext.cs  # ← Extendido (con UnitOfWork)
        ├── Repositories/
        │   ├── ${EntityName}Repository.cs     # CRUD con EF Core
        │   ├── ${EntityName}ReadRepository.cs # Lectura con Dapper (NotImplemented)
        │   └── ${EntityName}ReportRepository.cs # Reportes (datos hardcodeados)
        └── Queries/
            └── ${EntityName}Queries.cs        # SQL para Dapper

tests/Unit/$ApplicationName.$ModuleName.Application.Tests/
└── ${ModuleName}HandlerTests.cs
```

## Características implementadas:
- ✅ **CQRS Pattern**: Commands y Queries separados
- ✅ **MediatR**: Para manejar comandos y consultas
- ✅ **Records**: Para commands y DTOs
- ✅ **Database First**: Preparado para scaffold de base de datos existente
- ✅ **Doble DbContext**: Base (para scaffold) y Extendido (con UnitOfWork)
- ✅ **Mapeo de Entidades**: Separación entre entidades de dominio y modelos de infraestructura
- ✅ **Repositorio CUD**: Solo operaciones Create, Update, Delete con EF Core
- ✅ **Repositorio de Lectura**: Operaciones de consulta con Dapper y mapeo a DTOs
- ✅ **Repositorio de Reportes**: Reportes con datos hardcodeados para pruebas
- ✅ **Flujo Completo de Queries**: Controller → MediatR → QueryHandler → Repository → DTO
- ✅ **Flujo de Reportes**: Endpoint /report con datos de ejemplo
- ✅ **EF Core Tools**: Incluido automáticamente para scaffold y migraciones
- ✅ **Controller versionado**: Con rutas en minúsculas (api/v1/$($ModuleName.ToLower()))
- ✅ **Endpoints RESTful**: CREATE, GET (lista), GET (por ID), GET (report) y Health check
- ✅ **Documentación Swagger**: Con versionado y camelCase

## Arquitectura de DbContext (Database First):

### **Doble DbContext Pattern:**
- **`Models/${ModuleName}DbContext.cs`**: DbContext base generado por scaffold
- **`Persistence/${ModuleName}ExtendedDbContext.cs`**: DbContext extendido con UnitOfWork

### **Uso:**
- **Scaffold y Migraciones**: Usar `${ModuleName}DbContext` (base)
- **Operaciones CUD**: Usar `${ModuleName}DbContext` (base) con mapeo a entidades de dominio
- **Operaciones de Negocio con Transacciones**: Usar `${ModuleName}ExtendedDbContext` (extendido)
- **Operaciones de Lectura**: Usar Dapper a través de `${EntityName}ReadRepository`

## Para integrar el módulo:

### 1. Configurar en Program.cs:
```csharp
using $RootNamespace.$ModuleName.Api.Extensions;

// En ConfigureServices:
builder.Services.Add${ModuleName}Module(builder.Configuration);

// En el pipeline:
app.Use${ModuleName}Module();
```

### 2. Database First - Hacer Scaffold de la Base de Datos:
```bash
# Eliminar el placeholder del directorio Models (si existe)
Remove-Item "src/Modules/$ModuleName/$ApplicationName.$ModuleName.Infrastructure/Models/ModelsPlaceholder.cs" -ErrorAction SilentlyContinue

# Hacer scaffold de la base de datos
dotnet ef dbcontext scaffold "ConnectionString" Microsoft.EntityFrameworkCore.SqlServer \
  --project src/Modules/$ModuleName/$ApplicationName.$ModuleName.Infrastructure \
  --output-dir Models \
  --context ${ModuleName}DbContext \
  --force

# Para PostgreSQL usar:
# dotnet ef dbcontext scaffold "ConnectionString" Npgsql.EntityFrameworkCore.PostgreSQL \
#   --project src/Modules/$ModuleName/$ApplicationName.$ModuleName.Infrastructure \
#   --output-dir Models \
#   --context ${ModuleName}DbContext \
#   --force
```

### 3. Code First - Crear y aplicar migraciones (opcional):
```bash
# Crear migración inicial (usar el DbContext base)
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
3. [OK] Estructura CQRS implementada (Commands + Queries + Reports)
4. [OK] Controller con endpoints básicos, queries y reportes
5. [OK] DbContext extendido con UnitOfWork
6. [OK] Repositorios implementados (CUD con EF Core, Lectura con Dapper, Reportes con datos hardcodeados)
7. [PENDIENTE] Hacer scaffold de la base de datos (Database First)
8. [PENDIENTE] Implementar repositorios de lectura con Dapper real
9. [PENDIENTE] Implementar validaciones con FluentValidation
10. [PENDIENTE] Agregar tests unitarios

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