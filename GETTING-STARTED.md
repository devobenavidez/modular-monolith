# 🚀 Guía de Inicio Rápido

Esta guía te ayudará a tener un monolito modular funcionando en menos de 10 minutos.

## ⚡ Inicio Rápido (5 minutos)

### 1. Instalar Template
```bash
# Descargar y navegar al directorio
cd Monolith.Template

# Instalar template
dotnet new install ./
```

### 2. Crear Proyecto
```bash
# Crear nuevo monolito
dotnet new modular-monolith -n ECommerce -p:RootNamespace=MyCompany.ECommerce

# Navegar al proyecto
cd ECommerce
```

### 3. Configurar Base de Datos
Editar `src/ECommerce.Api/appsettings.json`:
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Database=ECommerce;Username=postgres;Password=postgres"
  }
}
```

### 4. Ejecutar con Docker
```bash
# Levantar PostgreSQL + App
docker-compose up -d
```

**¡Listo!** 🎉 Ve a http://localhost:5000/swagger

## 🐳 Opción Docker (Recomendada)

### docker-compose.yml incluido
```yaml
version: '3.8'
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: ECommerce
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  app:
    build: .
    ports:
      - "5000:8080"
    depends_on:
      - postgres
    environment:
      - ConnectionStrings__DefaultConnection=Host=postgres;Database=ECommerce;Username=postgres;Password=postgres

volumes:
  postgres_data:
```

### Comandos Docker
```bash
# Levantar todo
docker-compose up -d

# Ver logs
docker-compose logs -f app

# Parar servicios
docker-compose down
```

## 🖥️ Desarrollo Local (Sin Docker)

### Prerrequisitos
- .NET 8 SDK
- PostgreSQL 12+

### 1. Instalar PostgreSQL
```bash
# Ubuntu/Debian
sudo apt-get install postgresql postgresql-contrib

# macOS (Homebrew)
brew install postgresql

# Windows: Descargar desde postgresql.org
```

### 2. Crear Base de Datos
```sql
-- Conectar como postgres
createdb ECommerce
```

### 3. Configurar Connection String
En `appsettings.Development.json`:
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Database=ECommerce;Username=postgres;Password=tu_password"
  }
}
```

### 4. Ejecutar Migraciones
```bash
cd src/ECommerce.Shared
dotnet ef database update --startup-project ../ECommerce.Api
```

### 5. Ejecutar Aplicación
```bash
cd src/ECommerce.Api
dotnet run
```

## 🧪 Verificar Instalación

### 1. Health Check
```bash
curl http://localhost:5000/health
```
Respuesta esperada: `Healthy`

### 2. Swagger UI
Visita: http://localhost:5000/swagger

### 3. Prometheus Metrics
```bash
curl http://localhost:5000/metrics
```

### 4. Probar API del módulo Orders
```bash
# GET Orders
curl http://localhost:5000/api/orders

# Respuesta esperada:
{
  "isSuccess": true,
  "value": "Orders module is working!",
  "error": null
}
```

## 📦 Crear Tu Primer Módulo

### 1. Usar Script
```bash
# Windows
./scripts/create-module.ps1 -ModuleName Products

# Linux/Mac
./scripts/create-module.sh Products
```

### 2. Integrar Módulo
```bash
# Agregar referencia
dotnet add src/ECommerce.Api/ECommerce.Api.csproj reference src/Modules/Products/Products.Api/Products.Api.csproj
```

### 3. Configurar en Program.cs
```csharp
// Agregar estas líneas
using MyCompany.ECommerce.Products.Api;
using MyCompany.ECommerce.Products.Infrastructure.Extensions;

// En ConfigureServices
builder.Services.AddProductsModule();
builder.Services.AddProductsInfrastructure(builder.Configuration);
```

### 4. Compilar y Probar
```bash
dotnet build
dotnet run --project src/ECommerce.Api

# Probar nuevo endpoint
curl http://localhost:5000/api/products
```

## 🛠️ Comandos Útiles

### Desarrollo
```bash
# Hot reload
dotnet watch --project src/ECommerce.Api

# Ejecutar tests
dotnet test

# Limpiar y compilar
dotnet clean && dotnet build
```

### Base de Datos
```bash
# Crear migración
dotnet ef migrations add MigracionName --project src/ECommerce.Shared --startup-project src/ECommerce.Api

# Aplicar migraciones
dotnet ef database update --project src/ECommerce.Shared --startup-project src/ECommerce.Api

# Eliminar última migración
dotnet ef migrations remove --project src/ECommerce.Shared --startup-project src/ECommerce.Api
```

### Docker
```bash
# Rebuild imagen
docker-compose build app

# Solo base de datos
docker-compose up postgres -d

# Ver logs específicos
docker-compose logs -f postgres
```

## 🔍 Estructura Generada

```
ECommerce/
├── src/
│   ├── ECommerce.Api/              # 🌐 API Gateway
│   ├── ECommerce.Shared/           # 📚 Componentes compartidos
│   └── Modules/
│       └── Orders/                 # 📦 Módulo ejemplo
│           ├── Orders.Api/         # Controllers
│           ├── Orders.Application/ # CQRS Handlers
│           ├── Orders.Domain/      # Entidades
│           └── Orders.Infrastructure/ # Repositorios
├── tests/                          # 🧪 Pruebas
├── scripts/                        # 📜 Scripts
└── docker-compose.yml             # 🐳 Docker
```

## 📊 URLs Importantes

| Servicio | URL | Descripción |
|----------|-----|-------------|
| Swagger | http://localhost:5000/swagger | Documentación API |
| Health | http://localhost:5000/health | Estado de la app |
| Metrics | http://localhost:5000/metrics | Métricas Prometheus |
| PostgreSQL | localhost:5432 | Base de datos |

## ⚠️ Troubleshooting

### Error: Puerto ya en uso
```bash
# Cambiar puerto en docker-compose.yml
ports:
  - "5001:8080"  # En lugar de 5000
```

### Error: PostgreSQL no conecta
```bash
# Verificar que PostgreSQL esté corriendo
docker-compose ps

# Ver logs de PostgreSQL
docker-compose logs postgres
```

### Error: Migraciones fallan
```bash
# Verificar connection string
dotnet ef database drop --project src/ECommerce.Shared --startup-project src/ECommerce.Api

# Recrear base de datos
dotnet ef database update --project src/ECommerce.Shared --startup-project src/ECommerce.Api
```

### Error: Paquetes NuGet
```bash
# Limpiar cache
dotnet nuget locals all --clear
dotnet restore
```

## 🎯 Próximos Pasos

1. **Explorar el módulo Orders** - Ve a `src/Modules/Orders`
2. **Crear tu propio módulo** - Usa los scripts en `scripts/`
3. **Revisar la documentación** - Lee `MODULE-CREATION.md`
4. **Escribir pruebas** - Agrega tests en `tests/`
5. **Configurar CI/CD** - Usa `.github/workflows/ci.yml`

## 🔗 Enlaces Útiles

- [Documentación completa](README.md)
- [Guía de módulos](MODULE-CREATION.md)
- [Swagger UI](http://localhost:5000/swagger)
- [PostgreSQL Admin](https://www.pgadmin.org/) para gestión de BD

---
¿Algún problema? Revisa los logs con `docker-compose logs -f` o abre un issue en el repositorio.
