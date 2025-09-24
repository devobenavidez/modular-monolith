using Microsoft.AspNetCore.Mvc;
using Asp.Versioning;
using __RootNamespace__.SharedKernel.Exceptions.Business;
using __RootNamespace__.SharedKernel.Exceptions.Application;

namespace __RootNamespace__.Api.Controllers;

/// <summary>
/// Controlador para demostrar y probar el manejo de excepciones
/// </summary>
[ApiController]
[Route("api/v{version:apiVersion}/[controller]")]
[ApiVersion("1.0")]
public class ExceptionTestController : ControllerBase
{
    private readonly ILogger<ExceptionTestController> _logger;

    public ExceptionTestController(ILogger<ExceptionTestController> logger)
    {
        _logger = logger;
    }

    /// <summary>
    /// Lanza una ValidationException para probar Problem Details
    /// </summary>
    [HttpPost("validation-error")]
    public IActionResult ThrowValidationException()
    {
        var validationErrors = new Dictionary<string, string[]>
        {
            ["Email"] = new[] { "El email es requerido", "El formato del email es inválido" },
            ["Password"] = new[] { "La contraseña debe tener al menos 8 caracteres", "La contraseña debe contener al menos un número" }
        };

        throw new ValidationException("Los datos proporcionados no son válidos", validationErrors);
    }

    /// <summary>
    /// Lanza una BusinessRuleException para probar Problem Details
    /// </summary>
    [HttpPost("business-rule-error")]
    public IActionResult ThrowBusinessRuleException()
    {
        throw new BusinessRuleException("BR001", "No se puede procesar la orden porque el inventario es insuficiente");
    }

    /// <summary>
    /// Lanza una DomainException para probar Problem Details
    /// </summary>
    [HttpPost("domain-error")]
    public IActionResult ThrowDomainException()
    {
        throw new DomainException("DOM001", "El usuario no puede realizar esta acción en el estado actual");
    }

    /// <summary>
    /// Lanza una NotFoundException para probar Problem Details
    /// </summary>
    [HttpGet("not-found-error/{id}")]
    public IActionResult ThrowNotFoundException(int id)
    {
        throw new NotFoundException($"Usuario con ID {id} no fue encontrado");
    }

    /// <summary>
    /// Lanza una UnauthorizedException para probar Problem Details
    /// </summary>
    [HttpPost("unauthorized-error")]
    public IActionResult ThrowUnauthorizedException()
    {
        throw new UnauthorizedException("Token de autenticación inválido o expirado");
    }

    /// <summary>
    /// Lanza una ForbiddenException para probar Problem Details
    /// </summary>
    [HttpPost("forbidden-error")]
    public IActionResult ThrowForbiddenException()
    {
        throw new ForbiddenException("No tiene permisos para realizar esta acción");
    }

    /// <summary>
    /// Lanza una excepción genérica para probar Problem Details
    /// </summary>
    [HttpPost("generic-error")]
    public IActionResult ThrowGenericException()
    {
        throw new InvalidOperationException("Esta es una excepción genérica del sistema");
    }

    /// <summary>
    /// Lanza una excepción crítica para probar Problem Details
    /// </summary>
    [HttpPost("critical-error")]
    public IActionResult ThrowCriticalException()
    {
        throw new Exception("Esta es una excepción crítica no controlada");
    }

    /// <summary>
    /// Endpoint exitoso para contrastar con los errores
    /// </summary>
    [HttpGet("success")]
    public IActionResult Success()
    {
        return Ok(new
        {
            message = "Operación exitosa",
            timestamp = DateTime.UtcNow,
            version = "1.0"
        });
    }
}
