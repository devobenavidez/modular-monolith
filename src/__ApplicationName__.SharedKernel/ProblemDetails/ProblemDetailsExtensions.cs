using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using __RootNamespace__.SharedKernel.Exceptions.Base;
using __RootNamespace__.SharedKernel.Exceptions.Business;
using __RootNamespace__.SharedKernel.Exceptions.Application;

namespace __RootNamespace__.SharedKernel.ProblemDetails;

/// <summary>
/// Extensiones para facilitar el trabajo con Problem Details
/// </summary>
public static class ProblemDetailsExtensions
{    /// <summary>
    /// Convierte una excepción en ProblemDetails
    /// </summary>
    public static Microsoft.AspNetCore.Mvc.ProblemDetails ToProblemDetails(
        this Exception exception, 
        HttpContext httpContext, 
        bool includeExceptionDetails = false)
    {
        return ProblemDetailsFactory.CreateFromException(exception, httpContext, includeExceptionDetails);
    }

    /// <summary>
    /// Convierte una ValidationException en ValidationProblemDetails
    /// </summary>
    public static ValidationProblemDetails ToValidationProblemDetails(
        this ValidationException validationException, 
        HttpContext httpContext, 
        bool includeExceptionDetails = false)
    {
        return ProblemDetailsFactory.CreateValidationProblemDetails(validationException, httpContext, includeExceptionDetails);
    }

    /// <summary>
    /// Determina si una excepción debe incluir detalles técnicos
    /// </summary>
    public static bool ShouldIncludeExceptionDetails(this HttpContext httpContext)
    {
        // Incluir detalles solo en desarrollo
        var environment = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT");
        return string.Equals(environment, "Development", StringComparison.OrdinalIgnoreCase);
    }

    /// <summary>
    /// Agrega información del módulo al Problem Details
    /// </summary>
    public static T WithModule<T>(this T problemDetails, string moduleName) where T : Microsoft.AspNetCore.Mvc.ProblemDetails
    {
        problemDetails.Extensions["module"] = moduleName;
        return problemDetails;
    }

    /// <summary>
    /// Agrega correlation ID al Problem Details
    /// </summary>
    public static T WithCorrelationId<T>(this T problemDetails, string correlationId) where T : Microsoft.AspNetCore.Mvc.ProblemDetails
    {
        problemDetails.Extensions["correlationId"] = correlationId;
        return problemDetails;
    }

    /// <summary>
    /// Agrega información adicional al Problem Details
    /// </summary>
    public static T WithExtension<T>(this T problemDetails, string key, object value) where T : Microsoft.AspNetCore.Mvc.ProblemDetails
    {
        problemDetails.Extensions[key] = value;
        return problemDetails;
    }

    /// <summary>
    /// Agrega múltiples extensiones al Problem Details
    /// </summary>
    public static T WithExtensions<T>(this T problemDetails, IDictionary<string, object> extensions) where T : Microsoft.AspNetCore.Mvc.ProblemDetails
    {
        foreach (var extension in extensions)
        {
            problemDetails.Extensions[extension.Key] = extension.Value;
        }
        return problemDetails;
    }

    /// <summary>
    /// Verifica si una excepción es de tipo business/domain
    /// </summary>
    public static bool IsBusinessException(this Exception exception)
    {
        return exception is IException customException && 
               customException.Extensions.ContainsKey("domain") && 
               (customException.Extensions["domain"].ToString() == "business_logic" ||
                customException.Extensions["domain"].ToString() == "business_rule" ||
                customException.Extensions["domain"].ToString() == "validation");
    }

    /// <summary>
    /// Verifica si una excepción es técnica/de infraestructura
    /// </summary>
    public static bool IsTechnicalException(this Exception exception)
    {
        return exception is IException customException && 
               customException.Extensions.ContainsKey("domain") && 
               (customException.Extensions["domain"].ToString() == "infrastructure" ||
                customException.Extensions["domain"].ToString() == "database");
    }

    /// <summary>
    /// Obtiene el nivel de log apropiado para una excepción
    /// </summary>
    public static Microsoft.Extensions.Logging.LogLevel GetLogLevel(this Exception exception)
    {
        return exception switch
        {
            ValidationException => Microsoft.Extensions.Logging.LogLevel.Warning,
            NotFoundException => Microsoft.Extensions.Logging.LogLevel.Warning,
            BusinessRuleException => Microsoft.Extensions.Logging.LogLevel.Warning,
            DomainException => Microsoft.Extensions.Logging.LogLevel.Warning,
            UnauthorizedException => Microsoft.Extensions.Logging.LogLevel.Warning,
            ForbiddenException => Microsoft.Extensions.Logging.LogLevel.Warning,
            _ when exception.IsBusinessException() => Microsoft.Extensions.Logging.LogLevel.Warning,
            _ when exception.IsTechnicalException() => Microsoft.Extensions.Logging.LogLevel.Error,
            _ => Microsoft.Extensions.Logging.LogLevel.Error
        };
    }
}
