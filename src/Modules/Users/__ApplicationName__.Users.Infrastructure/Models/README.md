# Models Directory

Este directorio contiene modelos específicos de la capa de infraestructura:

## Propósito
- **DTOs de APIs externas**: Modelos para consumir servicios externos
- **ViewModels**: Modelos específicos para vistas o endpoints de lectura
- **Mappers**: Objetos de transferencia de datos entre capas
- **Configuraciones EF Core**: Modelos adicionales para Entity Framework

## Ejemplos de Uso
```csharp
// DTO para API externa
public class ExternalUserApiDto
{
    public string ExternalId { get; set; }
    public string FullName { get; set; }
    public string Email { get; set; }
}

// ViewModel para consultas optimizadas
public class UserSummaryViewModel
{
    public Guid Id { get; set; }
    public string DisplayName { get; set; }
    public DateTime LastLogin { get; set; }
}
```

## Buenas Prácticas
- No referenciar modelos de Domain directamente en controllers
- Usar estos modelos como intermediarios
- Implementar mappers explícitos entre capas
- Mantener separación entre modelos de entrada/salida y entidades de dominio
