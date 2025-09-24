# Ejemplos de Respuestas Problem Details

## ValidationException Response

**Request:** `POST /api/v1/exception-test/validation-error`

**Response:** `400 Bad Request`
```json
{
  "type": "https://tools.ietf.org/html/rfc7231#section-6.5.1",
  "title": "Validation Failed",
  "status": 400,
  "detail": "Los datos proporcionados no son válidos",
  "instance": "/api/v1/exception-test/validation-error",
  "errors": {
    "email": [
      "El email es requerido",
      "El formato del email es inválido"
    ],
    "password": [
      "La contraseña debe tener al menos 8 caracteres",
      "La contraseña debe contener al menos un número"
    ]
  },
  "traceId": "0HN7GCPL5L4R2:00000001",
  "timestamp": "2025-09-23T19:30:45.123Z"
}
```

## BusinessRuleException Response

**Request:** `POST /api/v1/exception-test/business-rule-error`

**Response:** `422 Unprocessable Entity`
```json
{
  "type": "https://datatracker.ietf.org/doc/html/rfc4918#section-11.2",
  "title": "Business Rule Violation",
  "status": 422,
  "detail": "No se puede procesar la orden porque el inventario es insuficiente",
  "instance": "/api/v1/exception-test/business-rule-error",
  "errorCode": "BR001",
  "domain": "business_rule",
  "traceId": "0HN7GCPL5L4R2:00000002",
  "timestamp": "2025-09-23T19:31:20.456Z"
}
```

## NotFoundException Response

**Request:** `GET /api/v1/exception-test/not-found-error/123`

**Response:** `404 Not Found`
```json
{
  "type": "https://tools.ietf.org/html/rfc7231#section-6.5.4",
  "title": "Not Found",
  "status": 404,
  "detail": "Usuario con ID 123 no fue encontrado",
  "instance": "/api/v1/exception-test/not-found-error/123",
  "traceId": "0HN7GCPL5L4R2:00000003",
  "timestamp": "2025-09-23T19:32:15.789Z"
}
```

## UnauthorizedException Response

**Request:** `POST /api/v1/exception-test/unauthorized-error`

**Response:** `401 Unauthorized`
```json
{
  "type": "https://tools.ietf.org/html/rfc7235#section-3.1",
  "title": "Unauthorized",
  "status": 401,
  "detail": "Token de autenticación inválido o expirado",
  "instance": "/api/v1/exception-test/unauthorized-error",
  "traceId": "0HN7GCPL5L4R2:00000004",
  "timestamp": "2025-09-23T19:33:45.012Z"
}
```

## Generic Exception Response (Development)

**Request:** `POST /api/v1/exception-test/generic-error`

**Response:** `500 Internal Server Error`
```json
{
  "type": "https://tools.ietf.org/html/rfc7231#section-6.6.1",
  "title": "Internal Server Error",
  "status": 500,
  "detail": "Esta es una excepción genérica del sistema",
  "instance": "/api/v1/exception-test/generic-error",
  "exceptionType": "InvalidOperationException",
  "stackTrace": "   at __ApplicationName__.Api.Controllers.ExceptionTestController.ThrowGenericException()...",
  "traceId": "0HN7GCPL5L4R2:00000005",
  "timestamp": "2025-09-23T19:34:30.345Z"
}
```

## Generic Exception Response (Production)

**Request:** `POST /api/v1/exception-test/generic-error`

**Response:** `500 Internal Server Error`
```json
{
  "type": "https://tools.ietf.org/html/rfc7231#section-6.6.1",
  "title": "Internal Server Error",
  "status": 500,
  "detail": "An error occurred while processing your request",
  "instance": "/api/v1/exception-test/generic-error",
  "traceId": "0HN7GCPL5L4R2:00000005",
  "timestamp": "2025-09-23T19:34:30.345Z"
}
```

## Response Headers

Todas las respuestas incluyen headers adicionales:

```http
Content-Type: application/problem+json
X-Correlation-ID: 0HN7GCPL5L4R2:00000001
X-Timestamp: 2025-09-23T19:30:45.123Z
X-Content-Type-Options: nosniff

# Solo en Development:
X-Exception-Type: ValidationException
```

## Logging Output

### Business Exception (Warning Level)
```
[19:30:45 WRN] Excepción no controlada en POST /api/v1/exception-test/validation-error. Status: 400, TraceId: 0HN7GCPL5L4R2:00000001, Exception: ValidationException, Message: Los datos proporcionados no son válidos
```

### Technical Exception (Error Level)
```
[19:34:30 ERR] Excepción no controlada en POST /api/v1/exception-test/generic-error. Status: 500, TraceId: 0HN7GCPL5L4R2:00000005, Exception: InvalidOperationException, Message: Esta es una excepción genérica del sistema
[19:34:30 ERR] Stack Trace:    at __ApplicationName__.Api.Controllers.ExceptionTestController.ThrowGenericException() in C:\...\ExceptionTestController.cs:line 78
   at Microsoft.AspNetCore.Mvc.Infrastructure.ActionMethodExecutor...
```
