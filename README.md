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
└── scripts/
    ├── smart-create-module.ps1                 # 🤖 Script inteligente (recomendado)
    ├── create-module.ps1                       # Script para crear módulos (Windows)
    └── create-module.sh                        # Script para crear módulos (Linux/Mac)
```

### ✨ Novedades de la Arquitectura v2.0

- ✅ **SharedKernel**: **Complementa** las capas de cada módulo con funcionalidad común
- ✅ **Arquitectura por Capas**: Cada módulo mantiene sus 4 capas completas (Domain, Application, Infrastructure, Api)
- ✅ **DbContext por Módulo**: Cada módulo tiene su propia base de datos/contexto
- ✅ **Módulos Autocontenidos**: Cada módulo implementa Arquitectura Hexagonal completa
- ✅ **Escalabilidad**: Preparado para migración a microservicios
- ✅ **Script Inteligente**: Detección automática de configuración del proyecto
- ✅ **Nomenclatura Limpia**: Sin la palabra "Modules" en nombres de proyectos

### 🔧 **¿Qué es SharedKernel?**

**SharedKernel NO reemplaza las capas, sino que las complementa:**

- **Domain de cada módulo**: Contiene entidades, eventos y lógica de negocio específica del módulo
- **Application de cada módulo**: Contiene comandos, queries y handlers específicos del módulo  
- **Infrastructure de cada módulo**: Contiene DbContext, repositorios y configuraciones específicas del módulo
- **Api de cada módulo**: Contiene controllers y endpoints específicos del módulo

**SharedKernel proporciona:**
- Interfaces base (`IUnitOfWork`, `IRepository<T>`)
- Implementaciones comunes (behaviors, extensiones)
- Clases base (`BaseEntity`, `IDomainEvent`)
- Funcionalidad compartida entre todos los módulos

### 🏗️ **Estructura Detallada de un Módulo (Ejemplo: Products)**

```
src/Modules/Products/
├── ERPCloud.Products.Api/                      # 🚀 Capa de presentación
│   ├── Controllers/
│   │   └── ProductsController.cs               # REST endpoints del módulo
│   ├── Extensions/
│   │   ├── ApplicationBuilderExtensions.cs     # Configuración del pipeline
│   │   └── ServiceCollectionExtensions.cs      # Registro de servicios
│   └── ERPCloud.Products.Api.csproj
├── ERPCloud.Products.Application/               # 🧠 Capa de aplicación (CQRS)
│   ├── Commands/
│   │   └── CreateProducts/
│   │       ├── CreateProductsCommand.cs         # Comando para crear productos
│   │       ├── CreateProductsCommandHandler.cs  # Handler del comando
│   │       └── CreateProductsValidator.cs       # Validación del comando
│   ├── Queries/
│   │   ├── GetProductsById/
│   │   │   ├── GetProductsByIdQuery.cs          # Query para obtener por ID
│   │   │   └── GetProductsByIdQueryHandler.cs   # Handler de la query
│   │   ├── GetProductss/
│   │   │   ├── GetProductssQuery.cs             # Query para obtener todos
│   │   │   └── GetProductssQueryHandler.cs      # Handler de la query
│   │   └── GetProductsReport/
│   │       ├── GetProductsReportQuery.cs        # Query para reportes
│   │       └── GetProductsReportQueryHandler.cs # Handler de reportes
│   ├── DTOs/
│   │   ├── ProductDto.cs                       # DTO principal del producto
│   │   ├── ProductFilterDto.cs                 # DTO para filtros
│   │   ├── ProductsDto.cs                      # DTO para listas
│   │   └── Reports/
│   │       └── ProductReportDto.cs             # DTO para reportes
│   ├── Interfaces/
│   │   └── IProductReadRepository.cs           # Interface para consultas
│   ├── AssemblyMarker.cs                       # Marcador de assembly
│   └── ERPCloud.Products.Application.csproj
├── ERPCloud.Products.Domain/                    # 🎯 Capa de dominio
│   ├── Abstractions/
│   │   └── IProductRepository.cs               # Interface del repositorio
│   ├── Entities/
│   │   └── Product.cs                          # Entidad principal del producto
│   └── ERPCloud.Products.Domain.csproj
└── ERPCloud.Products.Infrastructure/            # 🗄️ Capa de infraestructura
    ├── Extensions/
    │   └── ServiceCollectionExtensions.cs       # Configuración de servicios
    ├── Models/                                  # 📋 Modelos de BD (scaffold)
    │   └── [Modelos generados por EF Core]
    ├── Persistence/
    │   ├── ProductsExtendedDbContext.cs         # 🗄️ DbContext específico del módulo
    │   ├── Configurations/                      # Configuraciones EF Core
    │   └── Repositories/
    │       ├── ProductRepository.cs             # Repositorio EF Core
    │       └── ProductReadRepository.cs         # Repositorio de consultas (Dapper)
    └── ERPCloud.Products.Infrastructure.csproj
```

### 🔗 **Referencias entre Proyectos**

```
ERPCloud.Products.Application.csproj:
├── Referencia a: ERPCloud.Products.Domain        # Para entidades y interfaces
└── Referencia a: ERPCloud.SharedKernel          # Para funcionalidad común

ERPCloud.Products.Infrastructure.csproj:
├── Referencia a: ERPCloud.Products.Domain        # Para entidades
├── Referencia a: ERPCloud.Products.Application   # Para DTOs e interfaces
└── Referencia a: ERPCloud.SharedKernel          # Para funcionalidad común

ERPCloud.Products.Api.csproj:
├── Referencia a: ERPCloud.Products.Application   # Para comandos y queries
└── Referencia a: ERPCloud.Products.Infrastructure # Para servicios
```

### 🎯 **Beneficios de esta Arquitectura**

1. **Separación de Responsabilidades**: Cada capa tiene una responsabilidad específica
2. **Independencia de Módulos**: Cada módulo puede evolucionar independientemente
3. **Reutilización**: SharedKernel evita duplicación de código común
4. **Testabilidad**: Cada capa se puede probar de forma aislada
5. **Escalabilidad**: Fácil extracción de módulos como microservicios
6. **Mantenibilidad**: Código organizado y fácil de entender

### Características Técnicas

- ✅ **Arquitectura Hexagonal** con separación de puertos y adaptadores
- ✅ **CQRS** con Mediator para comandos y consultas
- ✅ **Unit of Work** implementado por DbContext de cada módulo
- ✅ **EF Core** para operaciones CRUD por módulo
- ✅ **EF Core Tools** centralizado para scaffold y migraciones
- ✅ **Dapper** para consultas optimizadas y reportes
- ✅ **PostgreSQL** como base de datos (conexión compartida, esquemas separados)
- ✅ **Logging** con Serilog
- ✅ **Telemetría** con OpenTelemetry y Prometheus
- ✅ **Docker** y docker-compose incluidos
- ✅ **Validación** con FluentValidation
- ✅ **Pruebas unitarias** con xUnit, FluentAssertions y Moq
- ✅ **Gestión centralizada de paquetes** con Directory.Build.props

## 🚀 Instalación y Uso

### 📋 Instalar el Template

**⚠️ IMPORTANTE: Debes estar en el directorio del template para instalarlo**

```powershell
# Navegar al directorio del template
cd C:\Users\Mauricio\source\repos\Celuweb\AGENTES-COMERCIALES\Monolith.Template-v1.0.1

# Instalar el template globalmente
dotnet new install ./
```

### 🏗️ Crear un Nuevo Proyecto

**⚠️ IMPORTANTE: Debes estar en el directorio donde quieres crear el proyecto**

```powershell
# Navegar al directorio destino (ejemplo: C:\Projects\)
cd C:\Projects\

# Crear proyecto con parámetros específicos
dotnet new modular-monolith -n ERPCloud --RootNamespace Celuweb.ERPCloud --ApplicationName ERPCloud
```

### 🧩 Crear Módulos

```powershell
# Navegar al proyecto creado
cd ERPCloud

# Crear módulo usando script inteligente
.\scripts\smart-create-module.ps1 -ModuleName Products
```

**🤖 El script te preguntará:**
```
¿Quieres que configure automáticamente el módulo? (y/n): y
```

- **Si respondes 'y'**: Configuración automática completa
- **Si respondes 'n'**: Debes configurar manualmente en Program.cs

### 🗄️ Scaffold de Base de Datos

```powershell
# Hacer scaffold desde base de datos existente
dotnet ef dbcontext scaffold 'Host=10.200.220.109;Database=erp-cloud-dev;Username=db.cwtest;Password=<l2>/4f8#q£7C6^(b8Or' Npgsql.EntityFrameworkCore.PostgreSQL -o Models --context ProductsDbContext --schema public --project src/Modules/Products/ERPCloud.Products.Infrastructure --no-onconfiguring --force
```

**🔑 El parámetro `--force` es OBLIGATORIO** para sobrescribir el DbContext de muestra que viene en el módulo.

### 🔄 Desinstalar/Reinstalar Template

**Cuándo hacerlo:** Cuando modifiques el template y quieras que los nuevos proyectos usen la versión actualizada.

```powershell
# 1. Ir al directorio del template
cd C:\Users\Mauricio\source\repos\Celuweb\AGENTES-COMERCIALES\Monolith.Template-v1.0.1

# 2. Desinstalar el template actual
dotnet new uninstall ./

# 3. Instalar la versión actualizada
dotnet new install ./
```

**⚠️ IMPORTANTE:** Los proyectos ya creados NO se afectan, solo los nuevos proyectos usarán la versión actualizada.
