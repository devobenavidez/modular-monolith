# 🚀 Guía de Versionado y Mejores Prácticas de API

## 📋 Configuración del Versionado

### ✅ Características Implementadas

El template incluye un sistema completo de versionado de API con las siguientes características:

- **Versionado por URL**: `api/v1/users`, `api/v2/users`
- **Versionado por Query String**: `api/users?version=1.0`
- **Versionado por Header**: `X-Version: 1.0`
- **Swagger con múltiples versiones**: Documentación separada por versión
- **Nomenclatura en minúsculas**: Rutas RESTful estándar

### 🎯 Estructura de URLs

```
GET  /api/v1/users           # Obtener lista de usuarios
GET  /api/v1/users/{id}      # Obtener usuario por ID
POST /api/v1/users           # Crear nuevo usuario
PUT  /api/v1/users/{id}      # Actualizar usuario completo
PATCH /api/v1/users/{id}     # Actualizar usuario parcial
DELETE /api/v1/users/{id}    # Eliminar usuario

GET  /api/v1/users/health    # Health check del módulo
```

## 🏗️ Configuración Automática

### 1. ServiceCollectionExtensions

Los servicios incluyen:
- **API Versioning**: Configuración automática de versiones
- **Swagger con Versioning**: Documentación por versión
- **camelCase**: Serialización JSON estándar
- **Kebab Case Routes**: URLs en minúsculas con guiones

### 2. Transformación de Rutas

```csharp
// PascalCase Controller -> kebab-case URL
UsersController -> /api/v1/users
ProductsController -> /api/v1/products
OrderItemsController -> /api/v1/order-items
```

### 3. Swagger UI Mejorado

- Selector de versiones en la interfaz
- Documentación XML incluida
- Esquemas en camelCase
- Try it out habilitado por defecto
- Filtros y búsqueda habilitados

## 📝 Creación de Nuevos Módulos

### Script Automático

```powershell
.\scripts\smart-create-module.ps1 -ModuleName Products
```

**Genera automáticamente:**
- Controller con rutas versionadas: `/api/v1/products`
- Endpoints RESTful estándar
- Health check con información de versión
- CQRS structure (Commands + Queries)
- Documentación Swagger completa

### Ejemplo de Controller Generado

```csharp
[ApiController]
[Route("api/v{version:apiVersion}/products")]
public class ProductsController : ControllerBase
{
    [HttpPost]                                    // POST /api/v1/products
    [HttpGet]                                     // GET /api/v1/products
    [HttpGet("{id:guid}")]                        // GET /api/v1/products/{id}
    [HttpGet("health")]                           // GET /api/v1/products/health
}
```

## 🔄 Migración de Versiones

### Para Crear Nueva Versión

1. **Duplicar Controller** con nueva versión:
   ```csharp
   [Route("api/v{version:apiVersion}/users")]
   [ApiVersion("2.0")]
   public class UsersV2Controller : ControllerBase
   ```

2. **Mantener Versión Anterior**:
   ```csharp
   [Route("api/v{version:apiVersion}/users")]
   [ApiVersion("1.0", Deprecated = true)]
   public class UsersController : ControllerBase
   ```

3. **Swagger Automático**: Las versiones aparecen automáticamente en la UI

### Estrategias de Versionado

1. **URL Versioning** (Recomendado)
   - Claro y explícito
   - Fácil de testear
   - Compatible con herramientas

2. **Header Versioning**
   ```bash
   curl -H "X-Version: 2.0" http://localhost:5000/api/users
   ```

3. **Query String Versioning**
   ```bash
   curl http://localhost:5000/api/users?version=2.0
   ```

## 🎨 Personalización de Swagger

### Configuración Avanzada

La configuración permite:
- Múltiples versiones simultáneas
- Documentación XML automática
- Esquemas camelCase
- Operaciones con nombres legibles
- Información de contacto y licencia

### Ejemplo de Salida JSON

```json
{
  "id": "123e4567-e89b-12d3-a456-426614174000",
  "name": "Product Name",
  "description": "Product Description",
  "createdAt": "2024-01-01T00:00:00Z",
  "updatedAt": null
}
```

## 🔍 Testing de APIs

### Ejemplos de Peticiones

```bash
# Health Check
curl http://localhost:5000/api/v1/users/health

# Crear Usuario
curl -X POST http://localhost:5000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"name": "John Doe", "email": "john@example.com"}'

# Obtener Usuarios
curl http://localhost:5000/api/v1/users

# Obtener Usuario por ID
curl http://localhost:5000/api/v1/users/123e4567-e89b-12d3-a456-426614174000

# Con versión específica
curl -H "X-Version: 2.0" http://localhost:5000/api/users
```

## 📊 Monitoreo y Logs

### Health Checks

Cada módulo incluye endpoints de health check:
```json
{
  "module": "Users",
  "status": "Healthy",
  "timestamp": "2024-01-01T00:00:00Z",
  "version": "1.0"
}
```

### Métricas Automáticas

- Prometheus metrics incluidas
- Request/Response logging con Serilog
- Tiempo de respuesta por endpoint
- Contadores de éxito/error por versión

---

**Resultado:** APIs modernas, versionadas y con excelente DX (Developer Experience) 🚀
