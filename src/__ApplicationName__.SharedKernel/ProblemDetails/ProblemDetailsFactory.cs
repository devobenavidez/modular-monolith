using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using __RootNamespace__.SharedKernel.Exceptions.Base;
using __RootNamespace__.SharedKernel.Exceptions.Business;

namespace __RootNamespace__.SharedKernel.ProblemDetails;

/// <summary>
/// Factory para crear instancias de ProblemDetails a partir de excepciones
/// </summary>
public static class ProblemDetailsFactory
{
    /// <summary>
    /// Crea un ProblemDetails estándar a partir de una excepción
    /// </summary>
    public static Microsoft.AspNetCore.Mvc.ProblemDetails CreateFromException(
        Exception exception,
        HttpContext httpContext,
        bool includeExceptionDetails = false)
    {
        var problemDetails = exception switch
        {
            IException customException => CreateFromCustomException(customException, httpContext, includeExceptionDetails),
            _ => CreateFromGenericException(exception, httpContext, includeExceptionDetails)
        };

        // Agregar información común
        problemDetails.Instance = httpContext.Request.Path;
        problemDetails.Extensions["traceId"] = httpContext.TraceIdentifier;
        problemDetails.Extensions["timestamp"] = DateTime.UtcNow;

        return problemDetails;
    }

    /// <summary>
    /// Crea un ValidationProblemDetails para errores de validación
    /// </summary>
    public static ValidationProblemDetails CreateValidationProblemDetails(
        ValidationException validationException,
        HttpContext httpContext,
        bool includeExceptionDetails = false)
    {
        var problemDetails = new ValidationProblemDetails(validationException.ValidationErrors)
        {
            Type = validationException.ProblemType ?? "https://tools.ietf.org/html/rfc7231#section-6.5.1",
            Title = validationException.Title,
            Status = validationException.StatusCode,
            Detail = validationException.Message,
            Instance = httpContext.Request.Path
        };

        // Agregar extensiones custom
        foreach (var extension in validationException.Extensions)
        {
            if (!problemDetails.Extensions.ContainsKey(extension.Key))
            {
                problemDetails.Extensions[extension.Key] = extension.Value;
            }
        }

        // Agregar información común
        problemDetails.Extensions["traceId"] = httpContext.TraceIdentifier;
        problemDetails.Extensions["timestamp"] = DateTime.UtcNow;

        if (includeExceptionDetails)
        {
            problemDetails.Extensions["exceptionType"] = validationException.GetType().Name;
            problemDetails.Extensions["stackTrace"] = validationException.StackTrace;
        }

        return problemDetails;
    }

    /// <summary>
    /// Crea ProblemDetails desde una excepción custom que implementa IException
    /// </summary>
    private static Microsoft.AspNetCore.Mvc.ProblemDetails CreateFromCustomException(
        IException customException,
        HttpContext httpContext,
        bool includeExceptionDetails)
    {
        var exception = (Exception)customException;

        var problemDetails = new Microsoft.AspNetCore.Mvc.ProblemDetails
        {
            Type = customException.ProblemType ?? GetDefaultProblemTypeForStatusCode(customException.StatusCode),
            Title = customException.Title,
            Status = customException.StatusCode,
            Detail = exception.Message
        };

        // Agregar extensiones custom
        foreach (var extension in customException.Extensions)
        {
            if (!problemDetails.Extensions.ContainsKey(extension.Key))
            {
                problemDetails.Extensions[extension.Key] = extension.Value;
            }
        }

        if (includeExceptionDetails)
        {
            problemDetails.Extensions["exceptionType"] = exception.GetType().Name;
            problemDetails.Extensions["stackTrace"] = exception.StackTrace;

            if (exception.InnerException != null)
            {
                problemDetails.Extensions["innerException"] = new
                {
                    Type = exception.InnerException.GetType().Name,
                    Message = exception.InnerException.Message
                };
            }
        }

        return problemDetails;
    }

    /// <summary>
    /// Crea ProblemDetails desde una excepción genérica
    /// </summary>
    private static Microsoft.AspNetCore.Mvc.ProblemDetails CreateFromGenericException(
        Exception exception,
        HttpContext httpContext,
        bool includeExceptionDetails)
    {
        var (statusCode, title, type) = GetStatusCodeForException(exception);

        var problemDetails = new Microsoft.AspNetCore.Mvc.ProblemDetails
        {
            Type = type,
            Title = title,
            Status = statusCode,
            Detail = includeExceptionDetails ? exception.Message : "An error occurred while processing your request."
        };

        problemDetails.Extensions["errorCode"] = exception.GetType().Name.Replace("Exception", "").ToUpperInvariant();

        if (includeExceptionDetails)
        {
            problemDetails.Extensions["exceptionType"] = exception.GetType().Name;
            problemDetails.Extensions["stackTrace"] = exception.StackTrace;

            if (exception.InnerException != null)
            {
                problemDetails.Extensions["innerException"] = new
                {
                    Type = exception.InnerException.GetType().Name,
                    Message = exception.InnerException.Message
                };
            }
        }

        return problemDetails;
    }    /// <summary>
         /// Obtiene información de status code para una excepción genérica
         /// </summary>
    private static (int statusCode, string title, string type) GetStatusCodeForException(Exception exception)
    {
        return exception switch
        {
            ArgumentNullException => (400, "Bad Request", "https://tools.ietf.org/html/rfc7231#section-6.5.1"),
            ArgumentException => (400, "Bad Request", "https://tools.ietf.org/html/rfc7231#section-6.5.1"),
            InvalidOperationException => (400, "Bad Request", "https://tools.ietf.org/html/rfc7231#section-6.5.1"),
            NotImplementedException => (501, "Not Implemented", "https://tools.ietf.org/html/rfc7231#section-6.6.2"),
            TimeoutException => (408, "Request Timeout", "https://tools.ietf.org/html/rfc7231#section-6.5.7"),
            _ => (500, "Internal Server Error", "https://tools.ietf.org/html/rfc7231#section-6.6.1")
        };
    }

    /// <summary>
    /// Obtiene el tipo de Problem Details por defecto para un código de estado HTTP
    /// </summary>
    private static string GetDefaultProblemTypeForStatusCode(int statusCode) => statusCode switch
    {
        400 => "https://tools.ietf.org/html/rfc7231#section-6.5.1",
        401 => "https://tools.ietf.org/html/rfc7235#section-3.1",
        403 => "https://tools.ietf.org/html/rfc7231#section-6.5.3",
        404 => "https://tools.ietf.org/html/rfc7231#section-6.5.4",
        408 => "https://tools.ietf.org/html/rfc7231#section-6.5.7",
        409 => "https://tools.ietf.org/html/rfc7231#section-6.5.8",
        422 => "https://datatracker.ietf.org/doc/html/rfc4918#section-11.2",
        500 => "https://tools.ietf.org/html/rfc7231#section-6.6.1",
        501 => "https://tools.ietf.org/html/rfc7231#section-6.6.2",
        503 => "https://tools.ietf.org/html/rfc7231#section-6.6.4",
        _ => "https://tools.ietf.org/html/rfc7231#section-6.6.1"
    };
}
