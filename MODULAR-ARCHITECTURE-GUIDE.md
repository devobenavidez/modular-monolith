# 🏗️ Guía de Arquitectura Modular con SharedKernel

> **Plantilla Monolito Modular v2.0** - Arquitectura mejorada sin capas root

## 📋 Resumen de la Nueva Arquitectura

### ✅ Lo que TENEMOS ahora (v2.0)
- **SharedKernel**: Infraestructura común (BaseEntity, IDomainEvent, Behaviors, IUnitOfWork)
- **Módulos Autocontenidos**: Cada módulo tiene su propio DbContext
- **Separación Clara**: Sin dependencias entre módulos
- **Escalabilidad**: Fácil migración futura a microservicios

### ❌ Lo que ELIMINAMOS (v1.0)
- ~~Proyectos root: Domain, Application, Infrastructure~~
- ~~DbContext centralizado~~
- ~~Dependencias acopladas~~

## 🏗️ Estructura de Proyecto

```
MyECommerce/
├── src/
│   ├── MyECommerce.Api/                          # 🚀 Proyecto principal
│   ├── MyECommerce.SharedKernel/                 # 🔧 Infraestructura común
│   │   ├── Common/
│   │   │   ├── BaseEntity.cs
│   │   │   └── IDomainEvent.cs
│   │   ├── Behaviors/
│   │   │   ├── ValidationBehavior.cs
│   │   │   └── LoggingBehavior.cs
│   │   └── Interfaces/
│   │       ├── IUnitOfWork.cs
│   │       └── IRepository.cs
│   └── Modules/
│       ├── Users/                                # 👥 Módulo de Usuarios
│       │   ├── MyECommerce.Modules.Users.Domain/
│       │   ├── MyECommerce.Modules.Users.Application/
│       │   ├── MyECommerce.Modules.Users.Infrastructure/
│       │   │   ├── Persistence/
│       │   │   │   └── UsersDbContext.cs         # 🗄️ DbContext específico
│       │   │   └── Extensions/
│       │   │       └── ServiceCollectionExtensions.cs
│       │   └── MyECommerce.Modules.Users.Api/
│       └── Products/                             # 🛍️ Módulo de Productos
│           ├── MyECommerce.Modules.Products.Domain/
│           ├── MyECommerce.Modules.Products.Application/
│           ├── MyECommerce.Modules.Products.Infrastructure/
│           │   ├── Persistence/
│           │   │   └── ProductsDbContext.cs      # 🗄️ DbContext específico
│           │   └── Extensions/
│           │       └── ServiceCollectionExtensions.cs
│           └── MyECommerce.Modules.Products.Api/
├── tests/
└── scripts/
```

## 🚀 Comandos Esenciales

### 1. Crear Nuevo Proyecto
```powershell
dotnet new modular-monolith -n MyECommerce -p:RootNamespace=MyCompany.ECommerce
```

### 2. Crear Nuevo Módulo
```powershell
cd MyECommerce
.\scripts\smart-create-module.ps1 -ModuleName Products
```

### 3. Gestión de Base de Datos por Módulo
```powershell
# Crear migración para Users
dotnet ef migrations add AddUsersTable `
  --project src/Modules/Users/MyECommerce.Modules.Users.Infrastructure `
  --startup-project src/MyECommerce.Api `
  --context UsersDbContext

# Aplicar migración
dotnet ef database update `
  --project src/Modules/Users/MyECommerce.Modules.Users.Infrastructure `
  --startup-project src/MyECommerce.Api `
  --context UsersDbContext
```

### 4. Verificar Arquitectura
```powershell
# Verificar que la arquitectura es correcta
function Test-ModularArchitecture {
    Write-Host "🔍 Verificando arquitectura modular..." -ForegroundColor Yellow
    
    # ✅ Verificar SharedKernel
    if (Test-Path "src/*SharedKernel*") {
        Write-Host "✅ SharedKernel encontrado" -ForegroundColor Green
    }
    
    # ❌ Verificar que no hay proyectos obsoletos
    $obsolete = @("Domain", "Application", "Infrastructure") | Where-Object { Test-Path "src/*$_*" -and $_ -notlike "*SharedKernel*" -and $_ -notlike "*Modules*" }
    if ($obsolete.Count -eq 0) {
        Write-Host "✅ No hay proyectos root obsoletos" -ForegroundColor Green
    }
    
    # 📦 Listar módulos
    $modules = Get-ChildItem -Path "src/Modules" -Directory -ErrorAction SilentlyContinue
    Write-Host "📦 Módulos encontrados: $($modules.Count)" -ForegroundColor Cyan
    $modules | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor White }
}
```

## 🔗 Referencias entre Proyectos

### ✅ Referencias PERMITIDAS
```
Users.Domain → SharedKernel
Users.Application → SharedKernel + Users.Domain
Users.Infrastructure → SharedKernel + Users.Domain
Users.Api → SharedKernel + Users.Domain + Users.Application + Users.Infrastructure
Api → SharedKernel + *.Api (de cada módulo)
```

### ❌ Referencias PROHIBIDAS
```
Users.* → Products.*  (No comunicación directa entre módulos)
Users.* → Root.Domain/Application/Infrastructure (No existen)
Cualquier → Api (Solo Api referencia a otros)
```

## 🗄️ Patrón DbContext por Módulo

### Configuración por Módulo
```csharp
// UsersDbContext.cs
public class UsersDbContext : DbContext, IUnitOfWork
{
    public UsersDbContext(DbContextOptions<UsersDbContext> options) : base(options) { }
    
    public DbSet<User> Users { get; set; }
    
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(Assembly.GetExecutingAssembly());
    }
}

// ServiceCollectionExtensions.cs en Infrastructure
public static IServiceCollection AddUsersInfrastructure(this IServiceCollection services, IConfiguration configuration)
{
    services.AddDbContext<UsersDbContext>(options =>
        options.UseNpgsql(configuration.GetConnectionString("DefaultConnection")));
    
    services.AddScoped<IUnitOfWork>(provider => provider.GetRequiredService<UsersDbContext>());
    return services;
}
```

## 🧪 Testing por Módulo

### Tests Unitarios
```powershell
# Solo tests del módulo Users
dotnet test tests/Unit/MyECommerce.Modules.Users.Application.Tests/

# Todos los tests unitarios
dotnet test tests/Unit/
```

### Tests de Integración
```csharp
// CustomWebApplicationFactory.cs - Configurar múltiples DbContext
protected override void ConfigureWebHost(IWebHostBuilder builder)
{
    builder.ConfigureServices(services =>
    {
        // Configurar DbContext de prueba para cada módulo
        services.AddDbContext<UsersDbContext>(options =>
            options.UseInMemoryDatabase("UsersTestDb"));
            
        services.AddDbContext<ProductsDbContext>(options =>
            options.UseInMemoryDatabase("ProductsTestDb"));
    });
}
```

## 🔄 Comunicación Entre Módulos

### ✅ Métodos PERMITIDOS
1. **Events de Dominio** (a través de SharedKernel)
2. **APIs HTTP** entre módulos
3. **Message Bus** (para eventos)

### ❌ Métodos PROHIBIDOS
1. ~~Referencia directa entre módulos~~
2. ~~Acceso directo a DbContext de otro módulo~~
3. ~~Dependencias transitivas~~

## 🚀 Migración a Microservicios

### Preparación
Cada módulo ya está listo para ser extraído como microservicio:

```powershell
# 1. Extraer módulo Users
mkdir ../MyECommerce.Users.Service
cp -r src/Modules/Users/* ../MyECommerce.Users.Service/src/
cp -r src/MyECommerce.SharedKernel ../MyECommerce.Users.Service/src/

# 2. Crear API independiente
dotnet new webapi -n MyECommerce.Users.Service.Api

# 3. El módulo ya tiene su DbContext propio ✅
# 4. Las interfaces están en SharedKernel ✅
# 5. No hay dependencias con otros módulos ✅
```

## 📚 Recursos Adicionales

- [COMMANDS.md](COMMANDS.md) - Comandos completos
- [REFACTORING-COMPLETION-SUMMARY.md](REFACTORING-COMPLETION-SUMMARY.md) - Detalles de migración
- `scripts/` - Scripts de automatización

## 🎯 Próximos Pasos

1. **Crear tu primer módulo**: `.\scripts\smart-create-module.ps1 -ModuleName Products`
2. **Implementar lógica de negocio** en Domain y Application
3. **Crear migraciones** para el DbContext del módulo
4. **Escribir tests** unitarios e integración
5. **Documentar** APIs del módulo

---

**Arquitectura v2.0** - SharedKernel + Módulos Autocontenidos  
**Autor:** Oscar Mauricio Benavidez Suarez - Celuweb
