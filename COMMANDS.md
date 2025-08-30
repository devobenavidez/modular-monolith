# 📋 Comandos Útiles - Monolito Modular

Esta guía contiene todos los comandos útiles para trabajar con el template de monolito modular.

## 🚀 Instalación y Configuración Inicial

### Instalar Template
```powershell
# Método 1: Usando el script de setup
.\setup.ps1 -Action install

# Método 2: Manual
dotnet new install .
```

### Crear Nuevo Proyecto
```powershell
# Con script interactivo
.\setup.ps1 -Action create

# Con parámetros específicos
.\setup.ps1 -Action create -ProjectName ECommerce -RootNamespace MyCompany.ECommerce

# Manual
dotnet new modular-monolith -n ECommerce -p:RootNamespace=MyCompany.ECommerce
```

## 🐳 Docker y Contenedores

### Comandos Docker Compose
```powershell
# Levantar todos los servicios (desarrollo)
docker-compose up -d

# Levantar solo la base de datos
docker-compose up postgres -d

# Ver logs en tiempo real
docker-compose logs -f

# Ver logs de un servicio específico
docker-compose logs -f app
docker-compose logs -f postgres

# Parar todos los servicios
docker-compose down

# Parar y eliminar volúmenes
docker-compose down -v

# Rebuild de la aplicación
docker-compose build app
docker-compose up -d app

# Ver estado de los servicios
docker-compose ps
```

### Docker Manual
```powershell
# Construir imagen
docker build -t mi-monolito -f docker/Dockerfile .

# Ejecutar contenedor
docker run -d -p 5000:8080 --name mi-app mi-monolito

# Ver logs del contenedor
docker logs -f mi-app

# Ejecutar comando dentro del contenedor
docker exec -it mi-app bash
```

## 🏗️ Arquitectura Modular con SharedKernel

> **Nueva Arquitectura (v2.0)**: Eliminamos las capas root (Domain, Application, Infrastructure) y las reemplazamos con SharedKernel + Módulos autocontenidos.

### Estructura de la Nueva Arquitectura
```
src/
├── __ApplicationName__.Api/                 # Proyecto principal
├── __ApplicationName__.SharedKernel/        # Infraestructura común
│   ├── Common/                             # BaseEntity, IDomainEvent
│   ├── Behaviors/                          # ValidationBehavior, LoggingBehavior  
│   └── Interfaces/                         # IUnitOfWork, IRepository<T>
└── Modules/
    ├── Users/
    │   ├── __ApplicationName__.Modules.Users.Domain/
    │   ├── __ApplicationName__.Modules.Users.Application/
    │   ├── __ApplicationName__.Modules.Users.Infrastructure/    # ✅ Con UsersDbContext
    │   └── __ApplicationName__.Modules.Users.Api/
    └── Products/
        ├── __ApplicationName__.Modules.Products.Domain/
        ├── __ApplicationName__.Modules.Products.Application/
        ├── __ApplicationName__.Modules.Products.Infrastructure/ # ✅ Con ProductsDbContext
        └── __ApplicationName__.Modules.Products.Api/
```

### Comandos para Verificar la Nueva Arquitectura
```powershell
# Verificar que no existen proyectos root obsoletos
if (Test-Path "src/__ApplicationName__.Domain") {
    Write-Warning "⚠️  Proyecto root Domain encontrado - debe ser eliminado"
}
if (Test-Path "src/__ApplicationName__.Application") {
    Write-Warning "⚠️  Proyecto root Application encontrado - debe ser eliminado"  
}
if (Test-Path "src/__ApplicationName__.Infrastructure") {
    Write-Warning "⚠️  Proyecto root Infrastructure encontrado - debe ser eliminado"
}

# Verificar que SharedKernel existe
if (Test-Path "src/__ApplicationName__.SharedKernel") {
    Write-Host "✅ SharedKernel encontrado" -ForegroundColor Green
} else {
    Write-Error "❌ SharedKernel no encontrado"
}

# Verificar que los módulos tienen su propio DbContext
$modules = Get-ChildItem -Path "src/Modules" -Directory
foreach ($module in $modules) {
    $dbContextFile = "src/Modules/$($module.Name)/__ApplicationName__.Modules.$($module.Name).Infrastructure/Persistence/$($module.Name)DbContext.cs"
    if (Test-Path $dbContextFile) {
        Write-Host "✅ DbContext encontrado para módulo: $($module.Name)" -ForegroundColor Green
    } else {
        Write-Warning "⚠️  DbContext no encontrado para módulo: $($module.Name)"
    }
}
```

### Comandos de Migración desde Arquitectura Antigua
```powershell
# Si tienes un proyecto con la arquitectura antigua, usa estos comandos para migrar:

# 1. Crear SharedKernel
dotnet new classlib -n __ApplicationName__.SharedKernel -o src/__ApplicationName__.SharedKernel

# 2. Mover entidades base desde Domain al SharedKernel
# Manualmente mover: BaseEntity, IDomainEvent, etc.

# 3. Actualizar referencias en módulos
$modules = Get-ChildItem -Path "src/Modules" -Directory
foreach ($module in $modules) {
    $domainProject = "src/Modules/$($module.Name)/__ApplicationName__.Modules.$($module.Name).Domain/__ApplicationName__.Modules.$($module.Name).Domain.csproj"
    $appProject = "src/Modules/$($module.Name)/__ApplicationName__.Modules.$($module.Name).Application/__ApplicationName__.Modules.$($module.Name).Application.csproj"
    
    # Remover referencias antiguas
    dotnet remove $domainProject reference "src/__ApplicationName__.Domain/__ApplicationName__.Domain.csproj"
    dotnet remove $appProject reference "src/__ApplicationName__.Application/__ApplicationName__.Application.csproj"
    
    # Agregar referencia a SharedKernel
    dotnet add $domainProject reference "src/__ApplicationName__.SharedKernel/__ApplicationName__.SharedKernel.csproj"
    dotnet add $appProject reference "src/__ApplicationName__.SharedKernel/__ApplicationName__.SharedKernel.csproj"
}

# 4. Eliminar proyectos obsoletos (después de verificar migración)
# Remove-Item -Path "src/__ApplicationName__.Domain" -Recurse -Force
# Remove-Item -Path "src/__ApplicationName__.Application" -Recurse -Force  
# Remove-Item -Path "src/__ApplicationName__.Infrastructure" -Recurse -Force
```

## 🧩 Gestión de Módulos

> **Nueva Arquitectura**: Los módulos son autocontenidos con su propio DbContext y referencias a SharedKernel.

### Crear Módulos (Recomendado - Script Inteligente)
```powershell
# Script inteligente que detecta automáticamente ApplicationName y RootNamespace
.\scripts\smart-create-module.ps1 -ModuleName Products

# El script creará automáticamente:
# - Domain: src/Modules/Products/__ApplicationName__.Modules.Products.Domain
# - Application: src/Modules/Products/__ApplicationName__.Modules.Products.Application  
# - Infrastructure: src/Modules/Products/__ApplicationName__.Modules.Products.Infrastructure (con ProductsDbContext)
# - API: src/Modules/Products/__ApplicationName__.Modules.Products.Api
# - Configuración automática en Program.cs
```

### Crear Módulos (Manual)
```powershell
# Windows - Especificando parámetros manualmente
.\scripts\create-module.ps1 -ModuleName Products
.\scripts\create-module.ps1 -ModuleName Products -RootNamespace MyCompany.ECommerce -ApplicationName ECommerce

# Linux/Mac
./scripts/create-module.sh Products
./scripts/create-module.sh Products MyCompany.ECommerce ECommerce
```

### Configurar Módulos en la Aplicación Principal
```powershell
# Configuración automática (recomendado)
.\scripts\configure-module.ps1 -ModuleName Products

# O agregar manualmente al Program.cs:
# builder.Services.AddProducts(builder.Configuration);
# app.UseProducts();
```

### Estructura de un Módulo Completo
```
src/Modules/Products/
├── __ApplicationName__.Modules.Products.Domain/
│   ├── Entities/
│   ├── Events/
│   └── Interfaces/
├── __ApplicationName__.Modules.Products.Application/
│   ├── Commands/
│   ├── Queries/
│   └── Handlers/
├── __ApplicationName__.Modules.Products.Infrastructure/
│   ├── Persistence/
│   │   ├── ProductsDbContext.cs
│   │   └── Repositories/
│   └── Extensions/
│       └── ServiceCollectionExtensions.cs
└── __ApplicationName__.Modules.Products.Api/
    ├── Controllers/
    └── Extensions/
        └── ServiceCollectionExtensions.cs
```

### Integración Manual de Módulos (Si no usas los scripts)
```powershell
# 1. Agregar referencia al proyecto principal
dotnet add src/__ApplicationName__.Api/__ApplicationName__.Api.csproj reference src/Modules/Products/__ApplicationName__.Modules.Products.Api/__ApplicationName__.Modules.Products.Api.csproj

# 2. Agregar a la solución
dotnet sln add src/Modules/Products/__ApplicationName__.Modules.Products.Api/__ApplicationName__.Modules.Products.Api.csproj
dotnet sln add src/Modules/Products/__ApplicationName__.Modules.Products.Application/__ApplicationName__.Modules.Products.Application.csproj
dotnet sln add src/Modules/Products/__ApplicationName__.Modules.Products.Domain/__ApplicationName__.Modules.Products.Domain.csproj
dotnet sln add src/Modules/Products/__ApplicationName__.Modules.Products.Infrastructure/__ApplicationName__.Modules.Products.Infrastructure.csproj

# 3. Configurar en Program.cs manualmente
# builder.Services.AddProducts(builder.Configuration);
# app.UseProducts();
```

## 🗄️ Base de Datos

### Entity Framework Commands (Arquitectura Modular)

> **Nota**: Con la nueva arquitectura modular, cada módulo tiene su propio DbContext. Los comandos EF se ejecutan por módulo.

```powershell
# Agregar migración para un módulo específico
dotnet ef migrations add AddUsersTable --project src/Modules/Users/__ApplicationName__.Modules.Users.Infrastructure --startup-project src/__ApplicationName__.Api --context UsersDbContext

# Aplicar migraciones de un módulo
dotnet ef database update --project src/Modules/Users/__ApplicationName__.Modules.Users.Infrastructure --startup-project src/__ApplicationName__.Api --context UsersDbContext

# Agregar migración para módulo Products (ejemplo)
dotnet ef migrations add AddProductsTable --project src/Modules/Products/__ApplicationName__.Modules.Products.Infrastructure --startup-project src/__ApplicationName__.Api --context ProductsDbContext

# Ver migraciones aplicadas de un módulo
dotnet ef migrations list --project src/Modules/Users/__ApplicationName__.Modules.Users.Infrastructure --startup-project src/__ApplicationName__.Api --context UsersDbContext

# Revertir migración de un módulo
dotnet ef database update PreviousMigrationName --project src/Modules/Users/__ApplicationName__.Modules.Users.Infrastructure --startup-project src/__ApplicationName__.Api --context UsersDbContext

# Eliminar última migración de un módulo
dotnet ef migrations remove --project src/Modules/Users/__ApplicationName__.Modules.Users.Infrastructure --startup-project src/__ApplicationName__.Api --context UsersDbContext

# Generar script SQL para un módulo
dotnet ef migrations script --project src/Modules/Users/__ApplicationName__.Modules.Users.Infrastructure --startup-project src/__ApplicationName__.Api --context UsersDbContext --output users-migrations.sql

# Eliminar base de datos completa (todos los módulos)
dotnet ef database drop --project src/Modules/Users/__ApplicationName__.Modules.Users.Infrastructure --startup-project src/__ApplicationName__.Api
```

### Comandos para Múltiples Módulos
```powershell
# Script para aplicar migraciones de todos los módulos
$modules = @("Users", "Products", "Orders")
foreach ($module in $modules) {
    Write-Host "Aplicando migraciones para módulo: $module" -ForegroundColor Green
    dotnet ef database update --project "src/Modules/$module/__ApplicationName__.Modules.$module.Infrastructure" --startup-project "src/__ApplicationName__.Api" --context "${module}DbContext"
}

# Script para agregar migración a múltiples módulos
# Ejemplo: Agregar campo común a varios módulos
$migrationName = "AddAuditFields"
$modules = @("Users", "Products")
foreach ($module in $modules) {
    Write-Host "Agregando migración '$migrationName' al módulo: $module" -ForegroundColor Green
    dotnet ef migrations add $migrationName --project "src/Modules/$module/__ApplicationName__.Modules.$module.Infrastructure" --startup-project "src/__ApplicationName__.Api" --context "${module}DbContext"
}
```

### PostgreSQL Directo
```powershell
# Conectar a PostgreSQL (Docker)
docker exec -it myapp-postgres psql -U postgres -d MyApp

# Backup de base de datos
docker exec myapp-postgres pg_dump -U postgres MyApp > backup.sql

# Restaurar base de datos
docker exec -i myapp-postgres psql -U postgres -d MyApp < backup.sql
```

## 🛠️ Desarrollo

### Comandos .NET
```powershell
# Restaurar dependencias
dotnet restore

# Compilar solución
dotnet build

# Compilar en modo Release
dotnet build --configuration Release

# Limpiar solución
dotnet clean

# Ejecutar aplicación
dotnet run --project src/__ApplicationName__.Api

# Ejecutar con hot reload
dotnet watch --project src/__ApplicationName__.Api

# Publicar aplicación
dotnet publish src/__ApplicationName__.Api --configuration Release --output ./publish
```

### Gestión de Paquetes
```powershell
# Agregar paquete NuGet al SharedKernel
dotnet add src/__ApplicationName__.SharedKernel package PackageName

# Agregar paquete a un módulo específico
dotnet add src/Modules/Users/__ApplicationName__.Modules.Users.Domain package PackageName

# Remover paquete
dotnet remove src/__ApplicationName__.Api package PackageName

# Listar paquetes
dotnet list package

# Actualizar paquetes (verificar compatibilidad entre módulos)
dotnet list package --outdated
dotnet add package PackageName --version NewVersion

# Verificar vulnerabilidades
dotnet list package --vulnerable

# Limpiar referencias duplicadas (común después del refactoring)
dotnet list package --include-transitive | findstr "duplicate"
```

### Comandos Específicos de la Nueva Arquitectura
```powershell
# Verificar que todos los módulos compilan correctamente
$modules = Get-ChildItem -Path "src/Modules" -Directory
foreach ($module in $modules) {
    Write-Host "Compilando módulo: $($module.Name)" -ForegroundColor Green
    dotnet build "src/Modules/$($module.Name)" --no-restore
}

# Verificar referencias del SharedKernel
dotnet list src/__ApplicationName__.SharedKernel package

# Verificar que ningún módulo referencia los antiguos proyectos root
Select-String -Path "src/Modules/**/*.csproj" -Pattern "Application\.csproj|Domain\.csproj|Infrastructure\.csproj" -SimpleMatch
```

## 🧪 Testing

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

# Con output detallado
dotnet test --verbosity detailed

# Filtrar por nombre
dotnet test --filter "TestMethodName"
dotnet test --filter "ClassName"

# Ejecutar en paralelo
dotnet test --parallel
```

### Generación de Reportes
```powershell
# Instalar herramienta de reportes
dotnet tool install -g dotnet-reportgenerator-globaltool

# Generar reporte HTML
reportgenerator -reports:"**/coverage.cobertura.xml" -targetdir:"coveragereport" -reporttypes:Html
```

## 📊 Monitoreo y Observabilidad

### Endpoints de Monitoreo
```powershell
# Health check
curl http://localhost:5000/health

# Métricas Prometheus
curl http://localhost:5000/metrics

# Info de la aplicación
curl http://localhost:5000/info
```

### Logs
```powershell
# Ver logs en tiempo real (Docker)
docker-compose logs -f app

# Ver logs locales
Get-Content -Path "logs/app-*.txt" -Wait

# Buscar en logs
Select-String -Pattern "ERROR" -Path "logs/*.txt"
```

## 🔍 Debugging y Troubleshooting

### Verificación de Estado
```powershell
# Verificar puertos ocupados
netstat -an | findstr ":5000"
netstat -an | findstr ":5432"

# Verificar servicios Docker
docker-compose ps

# Verificar espacio en disco
docker system df

# Limpiar Docker
docker system prune -a
```

### Troubleshooting Arquitectura Modular
```powershell
# Verificar que todos los módulos están registrados correctamente
# Buscar en Program.cs
Select-String -Path "src/__ApplicationName__.Api/Program.cs" -Pattern "Add.*Module|Use.*Module"

# Verificar conexiones de base de datos por módulo
$modules = Get-ChildItem -Path "src/Modules" -Directory
foreach ($module in $modules) {
    Write-Host "Verificando configuración DB para módulo: $($module.Name)" -ForegroundColor Yellow
    Select-String -Path "src/Modules/$($module.Name)/**/*.cs" -Pattern "ConnectionStrings" -SimpleMatch
}

# Verificar que no hay referencias circulares entre módulos
dotnet build --verbosity diagnostic 2>&1 | Select-String "circular"

# Limpiar y verificar referencias duplicadas
dotnet nuget locals all --clear
dotnet restore
dotnet list package --include-transitive | Group-Object | Where-Object Count -gt 1
```

### Errores Comunes y Soluciones
```powershell
# Error: "DbContext no registrado"
# Solución: Verificar que el módulo está registrado en Program.cs
Select-String -Path "src/__ApplicationName__.Api/Program.cs" -Pattern "builder.Services.Add.*\(\)"

# Error: "Migración no se aplica"
# Solución: Verificar contexto específico
dotnet ef migrations list --project src/Modules/Users/__ApplicationName__.Modules.Users.Infrastructure --startup-project src/__ApplicationName__.Api --context UsersDbContext

# Error: "Namespace not found" después del refactoring
# Solución: Buscar y reemplazar namespaces antiguos
Select-String -Path "src/**/*.cs" -Pattern "__RootNamespace__.Domain|__RootNamespace__.Application" -SimpleMatch

# Error: "Package version conflicts"
# Solución: Sincronizar versiones entre módulos
dotnet list package --outdated
# Actualizar a versiones compatibles manualmente
```

### Análisis de Performance
```powershell
# Profiling con dotnet-trace
dotnet tool install -g dotnet-trace
dotnet trace collect --process-id PID --providers Microsoft-Extensions-Logging

# Análisis de memoria
dotnet tool install -g dotnet-dump
dotnet dump collect --process-id PID

# Verificar performance de DbContext por módulo
# Habilitar logging detallado en appsettings.Development.json:
# "Microsoft.EntityFrameworkCore": "Debug"
```

## 🚀 Despliegue

### Build para Producción
```powershell
# Build optimizado
dotnet publish src/MyApp.Api --configuration Release --runtime linux-x64 --self-contained

# Build Docker para producción
docker build -t myapp:production -f docker/Dockerfile .
docker tag myapp:production myregistry/myapp:latest
docker push myregistry/myapp:latest
```

### Variables de Entorno
```powershell
# Desarrollo
$env:ASPNETCORE_ENVIRONMENT = "Development"
$env:ConnectionStrings__DefaultConnection = "Host=localhost;Database=MyApp;Username=postgres;Password=postgres"

# Producción
$env:ASPNETCORE_ENVIRONMENT = "Production"
$env:ConnectionStrings__DefaultConnection = "Host=prod-db;Database=MyApp;Username=user;Password=password"
```

## 🔧 Mantenimiento

### Actualización de Template
```powershell
# Desinstalar versión anterior
dotnet new uninstall Celuweb.ModularMonolith.Template

# Reinstalar nueva versión
dotnet new install .

# Verificar templates instalados
dotnet new list
```

### Limpieza del Sistema
```powershell
# Limpiar cache NuGet
dotnet nuget locals all --clear

# Limpiar bins y objs
Get-ChildItem -Path . -Recurse -Directory -Name "bin","obj" | Remove-Item -Recurse -Force

# Limpiar Docker
docker system prune -a --volumes
```

## 🎯 Comandos Útiles Específicos

### MSBuild Targets Personalizados
```powershell
# Ejecutar tests con coverage
dotnet build --target RunTestsWithCoverage

# Build Docker
dotnet build --target DockerBuild

# Ejecutar con Docker
dotnet build --target DockerRun

# Actualizar base de datos (todos los módulos)
dotnet build --target UpdateDatabase

# Agregar migración a un módulo específico
dotnet build --target AddMigration -p:MigrationName=AddProducts -p:ModuleName=Products
```

### Análisis de Código
```powershell
# Análisis estático
dotnet tool install -g Microsoft.CodeAnalysis.Analyzers
dotnet analyze

# Formato de código
dotnet format

# Verificar estilo
dotnet format --verify-no-changes
```

## 🚀 Comandos Rápidos para Nueva Arquitectura

### Setup Completo de Nuevo Proyecto
```powershell
# 1. Crear proyecto desde template
dotnet new modular-monolith -n MyECommerce -p:RootNamespace=MyCompany.ECommerce

# 2. Navegar al directorio
cd MyECommerce

# 3. Crear primer módulo
.\scripts\smart-create-module.ps1 -ModuleName Products

# 4. Compilar y ejecutar
dotnet build
dotnet run --project src/MyECommerce.Api
```

### Workflow Diario de Desarrollo
```powershell
# Crear nuevo módulo
.\scripts\smart-create-module.ps1 -ModuleName Orders

# Agregar migración al módulo
dotnet ef migrations add AddOrdersTable --project src/Modules/Orders/MyECommerce.Modules.Orders.Infrastructure --startup-project src/MyECommerce.Api --context OrdersDbContext

# Aplicar migración
dotnet ef database update --project src/Modules/Orders/MyECommerce.Modules.Orders.Infrastructure --startup-project src/MyECommerce.Api --context OrdersDbContext

# Ejecutar tests
dotnet test

# Ejecutar aplicación
dotnet run --project src/MyECommerce.Api
```

### Verificación Rápida de Arquitectura
```powershell
# Un comando para verificar todo
function Test-ModularArchitecture {
    Write-Host "🔍 Verificando arquitectura modular..." -ForegroundColor Yellow
    
    # Verificar SharedKernel
    if (Test-Path "src/*SharedKernel*") {
        Write-Host "✅ SharedKernel encontrado" -ForegroundColor Green
    } else {
        Write-Host "❌ SharedKernel no encontrado" -ForegroundColor Red
    }
    
    # Verificar que no hay proyectos root obsoletos
    $obsoleteProjects = @("*Domain*", "*Application*", "*Infrastructure*") | Where-Object { Test-Path "src/$_" -and $_ -notlike "*SharedKernel*" -and $_ -notlike "*Modules*" }
    if ($obsoleteProjects.Count -eq 0) {
        Write-Host "✅ No hay proyectos root obsoletos" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Proyectos obsoletos encontrados: $($obsoleteProjects -join ', ')" -ForegroundColor Yellow
    }
    
    # Verificar módulos
    $modules = Get-ChildItem -Path "src/Modules" -Directory -ErrorAction SilentlyContinue
    Write-Host "📦 Módulos encontrados: $($modules.Count)" -ForegroundColor Cyan
    foreach ($module in $modules) {
        Write-Host "  - $($module.Name)" -ForegroundColor White
    }
}

# Ejecutar verificación
Test-ModularArchitecture
```

---

> 💡 **Tip**: Guarda este archivo como referencia rápida y compártelo con tu equipo de desarrollo.
> 
> 🆕 **Arquitectura v2.0**: Ahora usando SharedKernel + Módulos autocontenidos con DbContext propio.

**Autor:** Oscar Mauricio Benavidez Suarez - Celuweb
