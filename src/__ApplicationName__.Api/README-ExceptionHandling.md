# Sistema de Manejo de Excepciones - Problem Details RFC 7807

## 📋 Descripción

Este sistema proporciona un manejo centralizado y consistente de excepciones siguiendo el estándar **RFC 7807 Problem Details for HTTP APIs**. Convierte automáticamente todas las excepciones no controladas en respuestas HTTP estructuradas y bien formateadas.

## 🏗️ Arquitectura

### Componentes Principales

1. **Middleware Global** (`GlobalExceptionHandlerMiddleware`): Captura todas las excepciones no controladas
2. **Problem Details Factory**: Convierte excepciones en Problem Details
3. **Extensions**: Métodos de extensión para facilitar el uso
4. **Exception Hierarchy**: Jerarquía de excepciones personalizadas

## 🚀 Funcionalidades

### ✅ Características Implementadas

- ✅ **RFC 7807 Compliance**: Respuestas HTTP siguiendo el estándar
- ✅ **Logging Estructurado**: Logs con niveles apropiados según el tipo de excepción
- ✅ **Correlation IDs**: Trazabilidad de requests
- ✅ **Environment-aware**: Comportamiento diferente en Development vs Production
- ✅ **Validation Errors**: Manejo especial para errores de validación
- ✅ **Custom Headers**: Headers adicionales para debugging y seguridad
- ✅ **JSON Serialization**: Respuestas en formato JSON camelCase

## 📊 Tipos de Excepciones Soportadas

### Business Exceptions (Warning Level)
- `ValidationException` → HTTP 400 + ValidationProblemDetails
- `BusinessRuleException` → HTTP 422
- `DomainException` → HTTP 422

### Application Exceptions (Warning Level)
- `NotFoundException` → HTTP 404
- `UnauthorizedException` → HTTP 401
- `ForbiddenException` → HTTP 403

### Technical Exceptions (Error Level)
- `InfrastructureException` → HTTP 500
- `DatabaseException` → HTTP 500

### Generic Exceptions (Error Level)
- Todas las demás excepciones → HTTP 500

## 🛠️ Uso del Sistema

### 1. Lanzar Excepciones en Controladores

```csharp
[HttpGet("{id}")]
public async Task<UserDto> GetUser(int id)
{
    var user = await _userService.GetByIdAsync(id);
    
    if (user == null)
        throw new NotFoundException($"Usuario con ID {id} no fue encontrado");
    
    return user;
}
```

### 2. Validación con ValidationException

```csharp
public async Task<Result> CreateUser(CreateUserCommand command)
{
    var validationErrors = new Dictionary<string, string[]>
    {
        ["Email"] = new[] { "El email es requerido", "Formato inválido" },
        ["Password"] = new[] { "Mínimo 8 caracteres", "Debe contener números" }
    };
    
    if (validationErrors.Any())
        throw new ValidationException("Datos inválidos", validationErrors);
    
    // ... lógica de negocio
}
```

### 3. Business Rules

```csharp
public async Task ProcessOrder(int orderId)
{
    var order = await _orderRepository.GetByIdAsync(orderId);
    
    if (order.Status != OrderStatus.Pending)
        throw new BusinessRuleException("BR001", 
            "Solo se pueden procesar órdenes en estado Pendiente");
    
    // ... procesar orden
}
```

## 🧪 Testing del Sistema

### Endpoints de Prueba

El sistema incluye un `ExceptionTestController` con endpoints para probar cada tipo de excepción:

```bash
# Validation Error
POST /api/v1/exception-test/validation-error

# Business Rule Error  
POST /api/v1/exception-test/business-rule-error

# Not Found Error
GET /api/v1/exception-test/not-found-error/123

# Unauthorized Error
POST /api/v1/exception-test/unauthorized-error

# Generic Error
POST /api/v1/exception-test/generic-error
```

### Respuestas de Ejemplo

#### ValidationException Response
```json
{
  "type": "https://tools.ietf.org/html/rfc7231#section-6.5.1",
  "title": "Validation Failed", 
  "status": 400,
  "detail": "Los datos proporcionados no son válidos",
  "instance": "/api/v1/exception-test/validation-error",
  "errors": {
    "email": ["El email es requerido", "El formato del email es inválido"],
    "password": ["La contraseña debe tener al menos 8 caracteres"]
  },
  "traceId": "0HN7GCPL5L4R2:00000001",
  "timestamp": "2025-09-23T19:30:45.123Z"
}
```

#### BusinessRuleException Response
```json
{
  "type": "https://datatracker.ietf.org/doc/html/rfc4918#section-11.2",
  "title": "Business Rule Violation",
  "status": 422,
  "detail": "No se puede procesar la orden porque el inventario es insuficiente",
  "instance": "/api/v1/exception-test/business-rule-error",
  "errorCode": "BR001",
  "traceId": "0HN7GCPL5L4R2:00000002",
  "timestamp": "2025-09-23T19:31:20.456Z"
}
```

## 📝 Logging

### Niveles de Log por Excepción

- **Warning**: Business exceptions, validation errors, not found, unauthorized
- **Error**: Technical exceptions, infrastructure errors, generic exceptions
- **Information**: Request/response logging (via behaviors)

### Contexto de Logging

Cada log incluye:
- TraceId para correlación
- Request Path y HTTP Method
- Status Code
- User ID (si está autenticado)
- User Agent
- Stack Trace (solo para errores críticos)

## 🔧 Configuración

### Middleware Registration

El middleware está registrado en `Program.cs`:

```csharp
// Temprano en el pipeline, después de Serilog
app.UseSerilogRequestLogging();
app.UseGlobalExceptionHandler(); // ← Aquí
app.UseHttpsRedirection();
```

### Problem Details Configuration

```csharp
services.AddProblemDetails(options =>
{
    options.CustomizeProblemDetails = (context) =>
    {
        // Personalización global de Problem Details
        context.ProblemDetails.Instance = context.HttpContext.Request.Path;
        context.ProblemDetails.Extensions["traceId"] = context.HttpContext.TraceIdentifier;
        context.ProblemDetails.Extensions["timestamp"] = DateTime.UtcNow;
    };
});
```

## 📈 Próximos Pasos - FASE 3

- [ ] **Module-Specific Exceptions**: Excepciones especializadas por módulo
- [ ] **Metrics Integration**: Métricas de excepciones con Prometheus
- [ ] **Exception Enrichment**: Contexto adicional por módulo
- [ ] **Custom Problem Types**: Tipos de problema específicos del dominio

## 🛡️ Consideraciones de Seguridad

- **Information Disclosure**: Detalles técnicos solo en Development
- **Headers**: Headers de seguridad agregados automáticamente
- **Logging**: Información sensible filtrada en logs
- **Correlation**: TraceIds para debugging sin exponer información interna

---

**Estado**: ✅ **FASE 2 COMPLETADA**  
**Siguiente**: FASE 3 - Module-Specific Exceptions
