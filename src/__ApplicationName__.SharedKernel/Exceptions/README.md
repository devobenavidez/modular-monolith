# Exception Handling & Problem Details

Este sistema implementa manejo centralizado de excepciones siguiendo el estándar **RFC 7807 Problem Details for HTTP APIs**.

## 🏗️ Arquitectura de Excepciones

### Jerarquía de Excepciones

```
BaseException (IException)
├── Business/
│   ├── DomainException (422 Unprocessable Entity)
│   ├── ValidationException (400 Bad Request)
│   └── BusinessRuleException (409 Conflict)
├── Technical/
│   ├── InfrastructureException (503 Service Unavailable)
│   └── DatabaseException (500 Internal Server Error)
└── Application/
    ├── NotFoundException (404 Not Found)
    ├── UnauthorizedException (401 Unauthorized)
    └── ForbiddenException (403 Forbidden)
```

## 🎯 Uso en Módulos

### 1. Excepciones de Dominio
```csharp
// Para violaciones de reglas de dominio
throw new DomainException("Product price cannot be negative", "Product", productId);

// Para reglas de negocio específicas
throw new BusinessRuleException("PRODUCT_MAX_QUANTITY", "Cannot exceed maximum quantity per order", new { ProductId = id, MaxQuantity = 100 });
```

### 2. Excepciones de Validación
```csharp
// Desde FluentValidation (automático via ValidationBehavior)
public class CreateProductValidator : AbstractValidator<CreateProductCommand>
{
    public CreateProductValidator()
    {
        RuleFor(x => x.Name).NotEmpty().WithMessage("Product name is required");
        RuleFor(x => x.Price).GreaterThan(0).WithMessage("Price must be positive");
    }
}

// Validación manual
throw new ValidationException("email", "Email format is invalid");

// Múltiples errores de validación
var errors = new Dictionary<string, string[]>
{
    { "name", new[] { "Name is required" } },
    { "price", new[] { "Price must be positive" } }
};
throw new ValidationException("Product validation failed", errors);
```

### 3. Excepciones de Aplicación
```csharp
// Recurso no encontrado
throw new NotFoundException("Product", productId);
throw new NotFoundException("Product", "SKU", sku);

// Problemas de autorización
throw new UnauthorizedException("products", "create");
throw new ForbiddenException("products", "delete", "ADMIN_ROLE");
```

### 4. Excepciones Técnicas
```csharp
// Errores de base de datos
throw new DatabaseException("INSERT", "products", "Duplicate key violation");

// Errores de infraestructura
throw new InfrastructureException("EmailService", "SMTP server is unavailable");
```

## 📋 Problem Details Output

### Excepción de Validación
```json
{
  "type": "https://tools.ietf.org/html/rfc7231#section-6.5.1",
  "title": "Validation Failed",
  "status": 400,
  "detail": "Product validation failed",
  "instance": "/api/v1/products",
  "traceId": "12345678-1234-1234-1234-123456789abc",
  "timestamp": "2025-09-23T10:30:00Z",
  "errorCode": "VALIDATION_ERROR",
  "domain": "validation",
  "errors": {
    "name": ["Product name is required"],
    "price": ["Price must be positive"]
  }
}
```

### Excepción de Dominio
```json
{
  "type": "https://datatracker.ietf.org/doc/html/rfc4918#section-11.2",
  "title": "Domain Rule Violation",
  "status": 422,
  "detail": "Product price cannot be negative",
  "instance": "/api/v1/products/123",
  "traceId": "12345678-1234-1234-1234-123456789abc",
  "timestamp": "2025-09-23T10:30:00Z",
  "errorCode": "DOMAIN_ERROR",
  "domain": "business_logic",
  "entityName": "Product",
  "entityId": 123
}
```

### Excepción Not Found
```json
{
  "type": "https://tools.ietf.org/html/rfc7231#section-6.5.4",
  "title": "Resource Not Found",
  "status": 404,
  "detail": "Product with ID '123' was not found",
  "instance": "/api/v1/products/123",
  "traceId": "12345678-1234-1234-1234-123456789abc",
  "timestamp": "2025-09-23T10:30:00Z",
  "errorCode": "RESOURCE_NOT_FOUND",
  "domain": "application",
  "resourceType": "Product",
  "resourceId": 123
}
```

## 🔧 Behaviors MediatR

### ValidationBehavior
Convierte automáticamente errores de FluentValidation en `ValidationException` personalizada.

### LoggingBehavior
- Log estructurado de requests y excepciones
- Diferentes niveles de log según tipo de excepción
- Métricas de tiempo de ejecución

### TransactionBehavior
- Manejo automático de transacciones para comandos
- Rollback seguro con logging detallado
- Manejo de errores de rollback críticos

## 🎨 Extensiones Útiles

### En Controllers
```csharp
[ProducesResponseType(typeof(ProblemDetails), 404)]
[ProducesResponseType(typeof(ValidationProblemDetails), 400)]
[ProducesResponseType(typeof(ProblemDetails), 422)]
public async Task<ActionResult<ProductDto>> CreateProduct([FromBody] CreateProductCommand command)
{
    // Las excepciones se convierten automáticamente en Problem Details
    var productId = await _mediator.Send(command);
    return CreatedAtAction(nameof(GetProduct), new { id = productId }, productId);
}
```

### Agregando Información Adicional
```csharp
var exception = new DomainException("Invalid operation", "Product", productId);
exception.AddExtension("module", "Products");
exception.AddExtension("correlationId", correlationId);
throw exception;
```

## 🎯 Niveles de Logging

| Tipo de Excepción | Nivel de Log | Descripción |
|-------------------|--------------|-------------|
| ValidationException | Warning | Errores de entrada del usuario |
| NotFoundException | Warning | Recursos no encontrados |
| BusinessRuleException | Warning | Violaciones de reglas |
| DomainException | Warning | Errores de dominio |
| UnauthorizedException | Warning | Problemas de autenticación |
| ForbiddenException | Warning | Problemas de autorización |
| DatabaseException | Error | Errores de base de datos |
| InfrastructureException | Error | Errores de servicios externos |
| Otras excepciones | Error | Errores no catalogados |

## 🔐 Seguridad por Ambiente

### Development
- Stack traces completos
- Detalles de excepciones internos
- Información de debugging

### Production
- Stack traces filtrados
- Mensajes de error seguros
- Información sensible omitida

## 📊 Integración con Telemetría

- **Prometheus**: Métricas de errores por tipo y módulo
- **Serilog**: Logging estructurado compatible con ELK
- **OpenTelemetry**: Traces con información de errores
- **Health Checks**: Estado de la aplicación con Problem Details
