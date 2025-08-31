# Template Monolito Modular - Celuweb

Este template permite crear aplicaciones monolíticas modulares con Clean Architecture, CQRS, Mediator, PostgreSQL, y telemetría con Prometheus.

## 🏗️ Arquitectura v2.0 - SharedKernel + Módulos Autocontenidos

### Estructura del Proyecto (Nueva Arquitectura)

```
MiECommerce/
├── src/
│   ├── MiECommerce.Api/                        # 🚀 API Gateway principal (Entry Point)
│   ├── MiECommerce.SharedKernel/               # 🔧 Infraestructura común
│   │   ├── Common/                             # BaseEntity, IDomainEvent
│   │   ├── Behaviors/                          # ValidationBehavior, LoggingBehavior
│   │   └── Interfaces/                         # IUnitOfWork, IRepository<T>
│   └── Modules/                                # 📦 Módulos autocontenidos
│       ├── Users/                              # Módulo de usuarios
│       │   ├── MiECommerce.Users.Api/          # Controllers del módulo
│       │   ├── MiECommerce.Users.Application/  # Casos de uso (CQRS)
│       │   ├── MiECommerce.Users.Domain/       # Entidades y lógica de dominio
│       │   └── MiECommerce.Users.Infrastructure/ # DbContext + Repositorios
│       │       └── Persistence/
│       │           └── UsersDbContext.cs       # 🗄️ DbContext específico
│       └── Products/                           # Otro módulo...
│           ├── MiECommerce.Products.Api/
│           ├── MiECommerce.Products.Application/
│           ├── MiECommerce.Products.Domain/
│           └── MiECommerce.Products.Infrastructure/
│               └── Persistence/
│                   └── ProductsDbContext.cs    # 🗄️ DbContext específico
├── tests/
│   ├── Unit/                                   # Pruebas unitarias por módulo
│   └── Integration/                            # Pruebas de integración
└── scripts/
    ├── smart-create-module.ps1                 # 🤖 Script inteligente (recomendado)
    ├── create-module.ps1                       # Script para crear módulos (Windows)
    └── create-module.sh                        # Script para crear módulos (Linux/Mac)
```

### ✨ Novedades de la Arquitectura v2.0

- ✅ **SharedKernel**: Reemplaza las capas root (Domain, Application, Infrastructure)
- ✅ **DbContext por Módulo**: Cada módulo tiene su propia base de datos/contexto
- ✅ **Módulos Autocontenidos**: Sin dependencias entre módulos
- ✅ **Escalabilidad**: Preparado para migración a microservicios
- ✅ **Script Inteligente**: Detección automática de configuración del proyecto
- ✅ **Nomenclatura Limpia**: Sin la palabra "Modules" en nombres de proyectos

### Características Técnicas

- ✅ **Clean Architecture** con separación por capas
- ✅ **CQRS** con Mediator para comandos y consultas
- ✅ **Unit of Work** implementado por DbContext de cada módulo
- ✅ **EF Core** para operaciones CRUD por módulo
- ✅ **Dapper** para consultas optimizadas y reportes
- ✅ **PostgreSQL** como base de datos (conexión compartida, esquemas separados)
- ✅ **Logging** con Serilog
- ✅ **Telemetría** con OpenTelemetry y Prometheus
- ✅ **Docker** y docker-compose incluidos
- ✅ **Validación** con FluentValidation
- ✅ **Pruebas unitarias** con xUnit, FluentAssertions y NSubstitute

## 🚀 Instalación y Uso

### 1. Instalar el Template

```powershell
# Clonar o descargar este repositorio
cd Monolith.Template

# Instalar el template
dotnet new install ./
```

### 2. Crear un Nuevo Proyecto

Tienes **3 opciones** para crear un proyecto:

#### Opción 1: Script Simplificado (Recomendado) 🚀
```powershell
# Script interactivo que te pregunta todo
.\setup.ps1 -Action create

# O directo con parámetros
.\create-project.ps1 -ProjectName MiECommerce -RootNamespace MiEmpresa.ECommerce
```

#### Opción 2: Comando .NET Official 
```powershell
# Crear proyecto con valores por defecto
dotnet new modular-monolith -n MiECommerce

# Crear proyecto con parámetros personalizados
dotnet new modular-monolith -n MiECommerce -p:RootNamespace=MiEmpresa.ECommerce -p:ApplicationName=ECommerce
```

#### Opción 3: Setup Completo
```powershell
# Script con instalación automática del template
.\setup.ps1 -Action install    # Instala el template
.\setup.ps1 -Action create     # Crea el proyecto interactivamente
```

> 💡 **Recomendación**: Usa la **Opción 1** para mayor simplicidad. Los scripts personalizados detectan automáticamente la configuración y son más fáciles de usar.

### 3. Configurar Base de Datos

Editar `appsettings.json` con la cadena de conexión de PostgreSQL:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Database=MiECommerce;Username=postgres;Password=password"
  }
}
```

### 4. Crear Primer Módulo

```powershell
cd MiECommerce

# Usar script inteligente (recomendado) - detecta automáticamente la configuración
.\scripts\smart-create-module.ps1 -ModuleName Products

# O manual con parámetros
.\scripts\create-module.ps1 -ModuleName Products -RootNamespace MiEmpresa.ECommerce -ApplicationName ECommerce
```

### 5. Ejecutar Migraciones (Por Módulo)

```powershell
# Crear migración inicial para el módulo Products
dotnet ef migrations add InitialCreate --project src/Modules/Products/MiECommerce.Modules.Products.Infrastructure --startup-project src/MiECommerce.Api --context ProductsDbContext

# Aplicar migración
dotnet ef database update --project src/Modules/Products/MiECommerce.Modules.Products.Infrastructure --startup-project src/MiECommerce.Api --context ProductsDbContext
```

### 6. Ejecutar la Aplicación

```powershell
# Opción 1: Con Docker
docker-compose up

# Opción 2: Directamente
cd src/MiECommerce.Api
dotnet run

# Opción 3: Con hot reload
dotnet watch --project src/MiECommerce.Api
```

## 📦 Crear Nuevos Módulos (Arquitectura v2.0)

### Script Inteligente (Recomendado)

```powershell
# El script detecta automáticamente ApplicationName y RootNamespace
.\scripts\smart-create-module.ps1 -ModuleName Orders

# Crea automáticamente:
# - Módulo completo con DbContext propio
# - Referencias a SharedKernel
# - Configura en Program.cs
# - Agrega a la solución
```

### 🔄 Refactorizar Módulo Users Existente

Si tienes un proyecto creado con la versión anterior del template, el módulo `Users` puede seguir usando la nomenclatura antigua (`Modules.Users`). Para actualizarlo a la nueva nomenclatura:

```powershell
# Refactorizar módulo Users existente
.\scripts\refactor-users-module.ps1

# El script:
# ✅ Detecta automáticamente la configuración del proyecto
# ✅ Crea un backup antes de refactorizar
# ✅ Renombra directorios y archivos
# ✅ Actualiza namespaces y referencias
# ✅ Actualiza la solución
# ✅ Actualiza Program.cs
```

**Después de la refactorización:**
```powershell
# Restaurar dependencias
dotnet restore

# Compilar para verificar
dotnet build

# Ejecutar tests
dotnet test
```

### Scripts Manuales

#### Windows (PowerShell)
```powershell
# Desde la raíz del proyecto
.\scripts\create-module.ps1 -ModuleName Orders -RootNamespace MiEmpresa.ECommerce -ApplicationName ECommerce
```

#### Linux/Mac (Bash)
```bash
# Desde la raíz del proyecto
./scripts/create-module.sh Orders MiEmpresa.ECommerce ECommerce
```

### Estructura del Módulo Creado

El script crea automáticamente la siguiente estructura:

```
src/Modules/Orders/
├── MiECommerce.Orders.Domain/
│   ├── Entities/
│   ├── Events/
│   └── Interfaces/
├── MiECommerce.Orders.Application/
│   ├── Commands/
│   ├── Queries/
│   └── Handlers/
├── MiECommerce.Orders.Infrastructure/
│   ├── Persistence/
│   │   ├── OrdersDbContext.cs           # 🗄️ DbContext específico
│   │   └── Repositories/
│   └── Extensions/
│       └── ServiceCollectionExtensions.cs
└── MiECommerce.Orders.Api/
    ├── Controllers/
    └── Extensions/
        └── ServiceCollectionExtensions.cs
```

### Configuración Automática

El script inteligente configura automáticamente:

1. **Referencias del proyecto**: SharedKernel en lugar de capas root
2. **DbContext específico**: OrdersDbContext implementando IUnitOfWork
3. **Program.cs**: Registro de servicios del módulo
4. **Solución**: Agrega todos los proyectos del módulo

```csharp
// Program.cs - Se agrega automáticamente:
builder.Services.AddOrdersModule(builder.Configuration);
app.UseOrdersModule();
```

## 🏗️ Estructura de un Módulo (Arquitectura v2.0)

Cada módulo sigue Clean Architecture con CQRS y es completamente autocontenido:

### Orders.Domain
```
MiECommerce.Orders.Domain/
├── Entities/
│   ├── Order.cs                    # Entidad principal
│   └── OrderItem.cs               # Entidades relacionadas
├── Events/
│   ├── OrderCreatedEvent.cs       # Eventos de dominio
│   └── OrderStatusChangedEvent.cs
├── Enums/
│   └── OrderStatus.cs
└── Interfaces/
    └── IOrderRepository.cs        # Contratos del dominio
```

### Orders.Application
```
MiECommerce.Orders.Application/
├── Commands/
│   ├── CreateOrder/
│   │   ├── CreateOrderCommand.cs
│   │   ├── CreateOrderHandler.cs
│   │   └── CreateOrderValidator.cs
│   └── UpdateOrderStatus/
│       ├── UpdateOrderStatusCommand.cs
│       └── UpdateOrderStatusHandler.cs
├── Queries/
│   ├── GetOrders/
│   │   ├── GetOrdersQuery.cs
│   │   └── GetOrdersHandler.cs
│   └── GetOrderById/
│       ├── GetOrderByIdQuery.cs
│       └── GetOrderByIdHandler.cs
├── DTOs/
│   ├── OrderDto.cs
│   └── OrderItemDto.cs
└── Interfaces/
    └── IOrderReadRepository.cs    # Interfaces para consultas
```

### Orders.Infrastructure (Con DbContext Propio)
```
MiECommerce.Orders.Infrastructure/
├── Models/                        # 📋 Modelos específicos de infraestructura
│   └── ModelsPlaceholder.cs       # ⚠️ Eliminar antes de scaffold
├── Persistence/
│   ├── OrdersDbContext.cs         # 🗄️ DbContext específico del módulo
│   ├── Configurations/
│   │   ├── OrderConfiguration.cs  # Configuración EF Core
│   │   └── OrderItemConfiguration.cs
│   └── Repositories/
│       ├── OrderRepository.cs     # EF Core para CRUD
│       └── OrderReadRepository.cs # Dapper para consultas
└── Extensions/
    └── ServiceCollectionExtensions.cs  # Registro de servicios
```

### Orders.Api
```
MiECommerce.Orders.Api/
├── Controllers/
│   └── OrdersController.cs        # REST endpoints
└── Extensions/
    └── ServiceCollectionExtensions.cs  # Configuración del módulo
```

### 📋 Directorio Models

El directorio `Models/` en cada módulo Infrastructure contiene:

- **ViewModels**: Modelos específicos para vistas o endpoints de lectura
- **ReportModels**: Modelos para reportes y consultas complejas
- **IntegrationModels**: Modelos para integraciones externas
- **DTOs específicos**: Modelos de transferencia de datos de infraestructura

> ⚠️ **Importante**: Al crear un nuevo módulo, se genera automáticamente un archivo `ModelsPlaceholder.cs` en el directorio `Models/`. **Debes eliminar este archivo antes de hacer scaffold de migraciones** para evitar conflictos.

```powershell
# Eliminar el placeholder antes de crear migraciones
Remove-Item "src/Modules/Orders/MiECommerce.Orders.Infrastructure/Models/ModelsPlaceholder.cs"
```

## 🗄️ Gestión de Base de Datos por Módulo

### Cada Módulo = Su Propio DbContext

```csharp
// OrdersDbContext.cs
public class OrdersDbContext : DbContext, IUnitOfWork
{
    public OrdersDbContext(DbContextOptions<OrdersDbContext> options) : base(options) { }
    
    public DbSet<Order> Orders { get; set; }
    public DbSet<OrderItem> OrderItems { get; set; }
    
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Aplicar configuraciones específicas del módulo
        modelBuilder.ApplyConfigurationsFromAssembly(Assembly.GetExecutingAssembly());
    }
}
```

### Comandos de Migración por Módulo

> ⚠️ **Recordatorio**: Antes de crear migraciones, elimina el archivo `ModelsPlaceholder.cs` del directorio `Models/` del módulo.

```powershell
# Eliminar placeholder antes de crear migraciones
Remove-Item "src/Modules/Orders/MiECommerce.Orders.Infrastructure/Models/ModelsPlaceholder.cs"

# Crear migración para módulo Orders
dotnet ef migrations add AddOrdersTable --project src/Modules/Orders/MiECommerce.Orders.Infrastructure --startup-project src/MiECommerce.Api --context OrdersDbContext

# Aplicar migración
dotnet ef database update --project src/Modules/Orders/MiECommerce.Orders.Infrastructure --startup-project src/MiECommerce.Api --context OrdersDbContext

# Ver migraciones del módulo
dotnet ef migrations list --project src/Modules/Orders/MiECommerce.Orders.Infrastructure --startup-project src/MiECommerce.Api --context OrdersDbContext
```

## 🛠️ Comandos Útiles (Arquitectura v2.0)

### Desarrollo

```powershell
# Ejecutar con hot-reload
dotnet watch --project src/MiECommerce.Api

# Ejecutar tests
dotnet test

# Ejecutar tests de un módulo específico
dotnet test tests/Unit/MiECommerce.Orders.Application.Tests/

# Compilar solo un módulo
dotnet build src/Modules/Orders/

# Verificar arquitectura modular
if (Test-Path "src/*SharedKernel*") { Write-Host "✅ SharedKernel OK" -ForegroundColor Green }
$modules = Get-ChildItem -Path "src/Modules" -Directory
Write-Host "📦 Módulos: $($modules.Count)" -ForegroundColor Cyan

# Refactorizar módulo Users existente (si es necesario)
.\scripts\refactor-users-module.ps1
```

### Base de Datos por Módulo

```powershell
# Crear y aplicar migración para un módulo
$ModuleName = "Orders"
$ProjectPath = "src/Modules/$ModuleName/MiECommerce.$ModuleName.Infrastructure"
$StartupProject = "src/MiECommerce.Api"
$ContextName = "${ModuleName}DbContext"

# Crear migración
dotnet ef migrations add AddInitialTables --project $ProjectPath --startup-project $StartupProject --context $ContextName

# Aplicar migración
dotnet ef database update --project $ProjectPath --startup-project $StartupProject --context $ContextName
```

### Script para Migrar Múltiples Módulos

```powershell
# Aplicar migraciones de todos los módulos
$modules = @("Users", "Orders", "Products")
foreach ($module in $modules) {
    Write-Host "Aplicando migraciones para módulo: $module" -ForegroundColor Green
    $projectPath = "src/Modules/$module/MiECommerce.$module.Infrastructure"
    $contextName = "${module}DbContext"
    
    dotnet ef database update --project $projectPath --startup-project "src/MiECommerce.Api" --context $contextName
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ $module actualizado correctamente" -ForegroundColor Green
    } else {
        Write-Host "❌ Error en módulo $module" -ForegroundColor Red
    }
}
```

### Docker

```powershell
# Construir imagen
docker build -t mi-monolito .

# Ejecutar con PostgreSQL
docker-compose up -d

# Ver logs
docker-compose logs -f

# Parar servicios
docker-compose down

# Limpiar volúmenes
docker-compose down -v
```

## 📊 Monitoreo y Observabilidad

### Endpoints Disponibles

- **Swagger UI**: `/swagger`
- **Health Checks**: `/health`
- **Métricas Prometheus**: `/metrics`

### Logging

Los logs se configuran con Serilog y se escriben a:
- Consola (desarrollo)
- Archivos en `logs/` (producción)
- Structured logging para análisis
- Logs por módulo con contexto específico

### Métricas

Se incluyen métricas automáticas para:
- HTTP requests por módulo
- Duración de operaciones por DbContext
- Errores por endpoint y módulo
- Métricas de base de datos por módulo
- Performance de queries CQRS

## 🧪 Testing (Arquitectura Modular)

### Estructura de Tests

```
tests/
├── Unit/
│   ├── MiECommerce.Modules.Users.Application.Tests/     # Tests unitarios por módulo
│   ├── MiECommerce.Modules.Orders.Application.Tests/
│   └── MiECommerce.Modules.Products.Application.Tests/
└── Integration/
    └── MiECommerce.Integration.Tests/                    # Tests de integración
        ├── Users/                                        # Tests por módulo
        ├── Orders/
        └── Products/
```

### Tests Unitarios por Módulo

```powershell
# Ejecutar tests de un módulo específico
dotnet test tests/Unit/MiECommerce.Orders.Application.Tests/

# Ejecutar todos los tests unitarios
dotnet test tests/Unit/

# Con cobertura de código
dotnet test tests/Unit/ --collect:"XPlat Code Coverage"
```

### Tests de Integración con Múltiples DbContext

```csharp
// CustomWebApplicationFactory.cs
public class CustomWebApplicationFactory<TProgram> : WebApplicationFactory<TProgram> where TProgram : class
{
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.ConfigureServices(services =>
        {
            // Configurar DbContext de prueba para cada módulo
            services.AddDbContext<UsersDbContext>(options =>
                options.UseInMemoryDatabase("UsersTestDb"));
                
            services.AddDbContext<OrdersDbContext>(options =>
                options.UseInMemoryDatabase("OrdersTestDb"));
                
            services.AddDbContext<ProductsDbContext>(options =>
                options.UseInMemoryDatabase("ProductsTestDb"));
        });
    }
}
```

### Estructura de Pruebas

```
tests/
├── Unit/                           # Pruebas unitarias
│   ├── Products.Application.Tests/
│   └── Orders.Application.Tests/
└── Integration/                    # Pruebas de integración
    └── MiApp.Integration.Tests/
```

### Ejecutar Pruebas

```powershell
# Todas las pruebas
dotnet test

# Solo pruebas unitarias
dotnet test tests/Unit/

# Solo pruebas de integración
dotnet test tests/Integration/

# Con cobertura de código
dotnet test --collect:"XPlat Code Coverage"

# Generar reporte de cobertura
dotnet tool install -g dotnet-reportgenerator-globaltool
reportgenerator -reports:"**/coverage.cobertura.xml" -targetdir:"coveragereport" -reporttypes:Html
```

## 📚 Patrones Implementados (Arquitectura v2.0)

### CQRS (Command Query Responsibility Segregation)
- **Comandos**: Modifican estado, usan EF Core con DbContext específico por módulo
- **Consultas**: Solo lectura, usan Dapper para performance óptima

### Repository Pattern por Módulo
- `IRepository<T>` para operaciones de escritura (en SharedKernel)
- `IReadOnlyRepository<T>` para operaciones de lectura (en SharedKernel)
- Implementaciones específicas en cada módulo

### Unit of Work por Módulo
- Cada DbContext implementa IUnitOfWork
- Manejo automático de transacciones por módulo
- Implementado como pipeline behavior de Mediator

### Domain Events
- Eventos dentro del agregado (en SharedKernel)
- Publicación automática al guardar cambios
- Comunicación entre módulos vía eventos

### Modular Monolith Patterns
- **Bounded Context**: Cada módulo es un contexto delimitado
- **Shared Kernel**: Infraestructura común en SharedKernel
- **Database per Module**: Cada módulo maneja su propio esquema/contexto
- **Event-Driven Communication**: Comunicación entre módulos vía eventos

## 🚀 Migración a Microservicios

### Preparación para Extracción

Cada módulo está diseñado para ser extraído fácilmente como microservicio:

```powershell
# Ejemplo: Extraer módulo Orders como microservicio
mkdir ../MiECommerce.Orders.Service

# Copiar módulo
cp -r src/Modules/Orders/* ../MiECommerce.Orders.Service/src/

# Copiar SharedKernel 
cp -r src/MiECommerce.SharedKernel ../MiECommerce.Orders.Service/src/

# El módulo ya tiene:
# ✅ Su propio DbContext
# ✅ Referencias solo a SharedKernel
# ✅ API independiente
# ✅ Sin dependencias con otros módulos
```

### Beneficios de la Arquitectura

1. **Escalabilidad Gradual**: Extraer módulos según necesidad
2. **Equipos Independientes**: Cada módulo puede ser mantenido por equipos diferentes
3. **Despliegue Independiente**: Preparado para CI/CD por módulo
4. **Base de Datos por Servicio**: Cada módulo maneja su propio esquema

## 🔧 Configuración Avanzada

### Variables de Entorno

```powershell
# Desarrollo
$env:ASPNETCORE_ENVIRONMENT = "Development"
$env:ConnectionStrings__DefaultConnection = "Host=localhost;Database=MiECommerce;Username=postgres;Password=postgres"

# Producción
$env:ASPNETCORE_ENVIRONMENT = "Production"  
$env:ConnectionStrings__DefaultConnection = "Host=prod-db;Database=MiECommerce;Username=user;Password=securepassword"
```

### Configuración por Módulo

```json
// appsettings.json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Database=MiECommerce;Username=postgres;Password=postgres"
  },
  "Modules": {
    "Users": {
      "EnableCaching": true,
      "CacheExpirationMinutes": 30
    },
    "Orders": {
      "EnableCaching": false,
      "MaxOrderItems": 100
    },
    "Products": {
      "EnableCaching": true,
      "CacheExpirationMinutes": 60
    }
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "MiECommerce.Modules.Users": "Debug",
      "MiECommerce.Modules.Orders": "Information"
    }
  }
}
```

## 📖 Documentación Adicional

- **[COMMANDS.md](COMMANDS.md)** - Lista completa de comandos útiles
- **[MODULAR-ARCHITECTURE-GUIDE.md](MODULAR-ARCHITECTURE-GUIDE.md)** - Guía detallada de la arquitectura
- **[REFACTORING-COMPLETION-SUMMARY.md](REFACTORING-COMPLETION-SUMMARY.md)** - Resumen de la migración arquitectural

## 🎯 Casos de Uso

### Desarrollo de E-Commerce
```powershell
# Opción Rápida (Recomendada)
.\create-project.ps1 -ProjectName MyECommerce -RootNamespace MyCompany.ECommerce

# O interactiva
.\setup.ps1 -Action create

cd MyECommerce

# Crear módulos principales
.\scripts\smart-create-module.ps1 -ModuleName Products
.\scripts\smart-create-module.ps1 -ModuleName Orders  
.\scripts\smart-create-module.ps1 -ModuleName Customers
.\scripts\smart-create-module.ps1 -ModuleName Inventory

# Ejecutar
dotnet run --project src/MyECommerce.Api
```

### Sistema de Gestión
```powershell
# Opción con .NET template
dotnet new modular-monolith -n ManagementSystem -p:RootNamespace=Enterprise.Management

# O con script personalizado
.\create-project.ps1 -ProjectName ManagementSystem -RootNamespace Enterprise.Management

cd ManagementSystem

# Crear módulos de gestión
.\scripts\smart-create-module.ps1 -ModuleName Employees
.\scripts\smart-create-module.ps1 -ModuleName Projects
.\scripts\smart-create-module.ps1 -ModuleName TimeTracking
.\scripts\smart-create-module.ps1 -ModuleName Reporting
```

## 🤝 Contribución

1. Fork el repositorio
2. Crear rama feature (`git checkout -b feature/nueva-caracteristica`)
3. Commit cambios (`git commit -am 'Agregar nueva característica'`)
4. Push rama (`git push origin feature/nueva-caracteristica`)  
5. Crear Pull Request

## 📝 Licencia

Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para más detalles.

## 👥 Autores

- **Oscar Mauricio Benavidez Suarez** - Celuweb
- Arquitectura v2.0 con SharedKernel y módulos autocontenidos

## 📞 Soporte

Para preguntas o soporte:
- **Email**: [mauricio@celuweb.com](mailto:mauricio@celuweb.com)
- **GitHub Issues**: [Crear issue](../../issues)

---

> 🚀 **Template Monolito Modular v2.0**  
> Arquitectura moderna con SharedKernel + Módulos Autocontenidos  
> Lista para escalar a microservicios cuando sea necesario
ASPNETCORE_ENVIRONMENT=Development
ConnectionStrings__DefaultConnection="Host=localhost;Database=MyApp;Username=postgres;Password=password"

# Producción
ASPNETCORE_ENVIRONMENT=Production
ConnectionStrings__DefaultConnection="[connection-string-produccion]"
```

### appsettings.json

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Database=MyApp;Username=postgres;Password=password"
  },
  "Serilog": {
    "MinimumLevel": "Information",
    "WriteTo": [
      { "Name": "Console" },
      { "Name": "File", "Args": { "path": "logs/app-.txt", "rollingInterval": "Day" } }
    ]
  },
  "Prometheus": {
    "Enabled": true,
    "Path": "/metrics"
  }
}
```

## 🤝 Contribución

1. Fork el proyecto
2. Crear branch para feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commit cambios (`git commit -am 'Agregar nueva funcionalidad'`)
4. Push al branch (`git push origin feature/nueva-funcionalidad`)
5. Crear Pull Request

## 📄 Licencia

Este proyecto está bajo la licencia MIT. Ver archivo `LICENSE` para más detalles.

---

**Desarrollado por:** Oscar Mauricio Benavidez Suarez - Celuweb
**Versión:** 1.0.0
