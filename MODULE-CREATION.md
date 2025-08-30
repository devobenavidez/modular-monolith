# Guía para Crear Nuevos Módulos

Esta guía explica cómo crear y configurar nuevos módulos en el monolito modular.

## 🎯 Conceptos Clave

### ¿Qué es un Módulo?

Un módulo es un conjunto cohesivo de funcionalidades que representa un bounded context del dominio. Cada módulo:

- Es **independiente** en términos de lógica de negocio
- Tiene su propia **estructura de Clean Architecture**
- Puede tener sus propias **tablas de base de datos**
- Se comunica con otros módulos a través de **eventos de integración**
- Sigue patrones **CQRS** para separar lectura y escritura

### Estructura de un Módulo

```
<ModuleName>/
├── <ApplicationName>.Modules.<ModuleName>.Api/
│   ├── Controllers/
│   ├── Extensions/
│   └── ModuleConfiguration.cs
├── <ApplicationName>.Modules.<ModuleName>.Application/
│   ├── Commands/
│   ├── Queries/
│   ├── Contracts/
│   └── Abstractions/
├── <ApplicationName>.Modules.<ModuleName>.Domain/
│   ├── Entities/
│   ├── ValueObjects/
│   └── Events/
└── <ApplicationName>.Modules.<ModuleName>.Infrastructure/
    ├── Persistence/
    │   ├── Configurations/
    │   └── Repositories/
    └── Extensions/
```

## 🚀 Creación Paso a Paso

### 1. Ejecutar el Script

#### Windows (PowerShell)
```powershell
./scripts/smart-create-module.ps1 -ModuleName Products
```

#### Linux/Mac (Bash)
```bash
./scripts/create-module.sh Products <RootNamespace> <ApplicationName> && \
./scripts/configure-module.sh Products <RootNamespace> <ApplicationName>
```

### 2. Agregar Referencia al API Principal (si el script no lo hizo)

```powershell
# Ejemplo general (ajusta según tu estructura)
dotnet add src/<ApplicationName>.Api/<ApplicationName>.Api.csproj reference \
  src/Modules/Products/<ApplicationName>.Modules.Products.Api/<ApplicationName>.Modules.Products.Api.csproj
```

### 3. Configurar en Program.cs

```csharp
using <RootNamespace>.Modules.Products.Api.Extensions;

var builder = WebApplication.CreateBuilder(args);

// ... otros servicios ...

// Agregar módulo
builder.Services.AddProductsModule(builder.Configuration);

var app = builder.Build();

// ... configuración pipeline ...
app.UseProductsModule();

app.Run();
```

## 🏗️ Implementar Funcionalidades

### Crear una Entidad

```csharp
using <RootNamespace>.SharedKernel.Common;

namespace <RootNamespace>.Modules.Products.Domain.Entities;

public class Product : BaseEntity
{
    public string Name { get; private set; } = string.Empty;
    public decimal Price { get; private set; }
    public string Description { get; private set; } = string.Empty;
    public bool IsActive { get; private set; } = true;

    private Product() { }

    public Product(string name, decimal price, string description)
    {
        Name = name;
        Price = price;
        Description = description;
        AddDomainEvent(new ProductCreatedEvent(Id, Name));
    }
}
```

### Crear un Value Object

```csharp
namespace <RootNamespace>.Modules.Products.Domain.ValueObjects;

public record Money(decimal Amount, string Currency = "USD");
```

### Crear un Evento de Dominio

```csharp
using <RootNamespace>.SharedKernel.Common;

namespace <RootNamespace>.Modules.Products.Domain.Events;

public record ProductCreatedEvent(Guid ProductId, string ProductName) : IDomainEvent;
```

### Crear un Comando CQRS

```csharp
using Mediator;
using <RootNamespace>.SharedKernel.Common;

namespace <RootNamespace>.Modules.Products.Application.Commands.CreateProduct;

public record CreateProductCommand(string Name, decimal Price, string Description) : ICommand<Result<Guid>>;
```

### Crear una Consulta CQRS

```csharp
using Mediator;
using <RootNamespace>.SharedKernel.Common;

namespace <RootNamespace>.Modules.Products.Application.Queries.GetProducts;

public record GetProductsQuery(int Page = 1, int PageSize = 10, string? SearchTerm = null) : IQuery<Result<PagedResult<ProductDto>>>;
```

### Configurar Dependency Injection (Infraestructura)

```csharp
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Configuration;

namespace <RootNamespace>.Modules.Products.Infrastructure.Extensions;

public static class DependencyInjection
{
    public static IServiceCollection AddProductsInfrastructure(this IServiceCollection services, IConfiguration configuration)
        => services; // agrega tus servicios concretos aquí
}
```

## 🗄️ Migraciones por Módulo (ejemplo)

```powershell
# Crear migración
$Module = "Products"
dotnet ef migrations add Add${Module} --project src/Modules/$Module/<ApplicationName>.Modules.$Module.Infrastructure \
  --startup-project src/<ApplicationName>.Api --context ${Module}DbContext

# Aplicar migración
dotnet ef database update --project src/Modules/$Module/<ApplicationName>.Modules.$Module.Infrastructure \
  --startup-project src/<ApplicationName>.Api --context ${Module}DbContext
```

## ✅ Lista de Verificación

- [ ] Ejecutar el script de creación
- [ ] Confirmar referencia al proyecto API
- [ ] Configurar Program.cs (Add…Module y Use…Module)
- [ ] Implementar entidades y CQRS
- [ ] Repositorios e Infrastructure
- [ ] Migraciones por módulo
- [ ] Tests unitarios
