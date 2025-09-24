using Microsoft.AspNetCore.Mvc;
using System.Net;
using System.Text.Json;
using __RootNamespace__.SharedKernel.Exceptions.Base;
using __RootNamespace__.SharedKernel.Exceptions.Business;
using __RootNamespace__.SharedKernel.ProblemDetails;

namespace __RootNamespace__.Api.Middleware;

/// <summary>
/// Middleware global para capturar y manejar todas las excepciones no controladas
/// Convierte excepciones a Problem Details siguiendo RFC 7807
/// </summary>
public class GlobalExceptionHandlerMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<GlobalExceptionHandlerMiddleware> _logger;
    private readonly IWebHostEnvironment _environment;

    public GlobalExceptionHandlerMiddleware(
        RequestDelegate next,
        ILogger<GlobalExceptionHandlerMiddleware> logger,
        IWebHostEnvironment environment)
    {
        _next = next;
        _logger = logger;
        _environment = environment;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            await HandleExceptionAsync(context, ex);
        }
    }

    private async Task HandleExceptionAsync(HttpContext context, Exception exception)
    {
        // Determinar si incluir detalles de la excepción (solo en desarrollo)
        var includeExceptionDetails = _environment.IsDevelopment();

        // Crear Problem Details apropiado según el tipo de excepción
        object problemDetails = exception switch
        {
            ValidationException validationEx => validationEx.ToValidationProblemDetails(context, includeExceptionDetails),
            _ => exception.ToProblemDetails(context, includeExceptionDetails)
        };

        // Obtener status code del Problem Details
        var statusCode = GetStatusCodeFromProblemDetails(problemDetails);

        // Log de la excepción con nivel apropiado
        LogException(exception, context, statusCode);

        // Configurar respuesta HTTP
        context.Response.Clear();
        context.Response.StatusCode = statusCode;
        context.Response.ContentType = "application/problem+json";

        // Agregar headers adicionales
        AddResponseHeaders(context, exception);

        // Serializar y escribir la respuesta
        var jsonOptions = new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
            WriteIndented = includeExceptionDetails
        };

        var jsonResponse = JsonSerializer.Serialize(problemDetails, jsonOptions);
        await context.Response.WriteAsync(jsonResponse);
    }

    /// <summary>
    /// Obtiene el status code del Problem Details
    /// </summary>
    private static int GetStatusCodeFromProblemDetails(object problemDetails)
    {
        return problemDetails switch
        {
            ValidationProblemDetails vpd => vpd.Status ?? 400,
            Microsoft.AspNetCore.Mvc.ProblemDetails pd => pd.Status ?? 500,
            _ => 500
        };
    }

    /// <summary>
    /// Log de la excepción con el nivel apropiado
    /// </summary>
    private void LogException(Exception exception, HttpContext context, int statusCode)
    {
        var logLevel = exception.GetLogLevel();
        var requestPath = context.Request.Path;
        var method = context.Request.Method;
        var traceId = context.TraceIdentifier;

        using var scope = _logger.BeginScope(new Dictionary<string, object>
        {
            ["TraceId"] = traceId,
            ["RequestPath"] = requestPath.ToString(),
            ["HttpMethod"] = method ?? "UNKNOWN",
            ["StatusCode"] = statusCode,
            ["UserId"] = GetUserId(context),
            ["UserAgent"] = context.Request.Headers.UserAgent.ToString() ?? "unknown"
        });

        _logger.Log(logLevel, exception,
            "Excepción no controlada en {HttpMethod} {RequestPath}. " +
            "Status: {StatusCode}, TraceId: {TraceId}, " +
            "Exception: {ExceptionType}, Message: {ExceptionMessage}",
            method, requestPath, statusCode, traceId,
            exception.GetType().Name, exception.Message);

        // Log adicional para excepciones críticas
        if (logLevel == LogLevel.Error || logLevel == LogLevel.Critical)
        {
            _logger.LogError("Stack Trace: {StackTrace}", exception.StackTrace);
        }
    }

    /// <summary>
    /// Agrega headers adicionales a la respuesta
    /// </summary>
    private static void AddResponseHeaders(HttpContext context, Exception exception)
    {
        // Agregar correlation ID si no existe
        if (!context.Response.Headers.ContainsKey("X-Correlation-ID"))
        {
            context.Response.Headers["X-Correlation-ID"] = context.TraceIdentifier;
        }

        // Agregar timestamp
        context.Response.Headers["X-Timestamp"] = DateTimeOffset.UtcNow.ToString("O");

        // Agregar información del error para debugging en desarrollo
        if (context.RequestServices.GetService<IWebHostEnvironment>()?.IsDevelopment() == true)
        {
            context.Response.Headers["X-Exception-Type"] = exception.GetType().Name;
        }

        // Headers de seguridad
        context.Response.Headers["X-Content-Type-Options"] = "nosniff";
    }

    /// <summary>
    /// Obtiene el ID del usuario desde el contexto (si está autenticado)
    /// </summary>
    private static string GetUserId(HttpContext context)
    {
        return context.User?.Identity?.IsAuthenticated == true
            ? context.User.FindFirst("sub")?.Value ?? context.User.FindFirst("id")?.Value ?? "unknown"
            : "anonymous";
    }
}
