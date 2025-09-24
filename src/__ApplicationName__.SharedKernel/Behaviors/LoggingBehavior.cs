using MediatR;
using Microsoft.Extensions.Logging;
using System.Diagnostics;

namespace __RootNamespace__.SharedKernel.Behaviors;

/// <summary>
/// Behavior de MediatR para logging automático de comandos, queries y excepciones.
/// Incluye logging estructurado compatible con Problem Details.
/// </summary>
public class LoggingBehavior<TRequest, TResponse> : IPipelineBehavior<TRequest, TResponse>
    where TRequest : IRequest<TResponse>
{
    private readonly ILogger<LoggingBehavior<TRequest, TResponse>> _logger;

    public LoggingBehavior(ILogger<LoggingBehavior<TRequest, TResponse>> logger)
    {
        _logger = logger;
    }

    public async Task<TResponse> Handle(TRequest request, RequestHandlerDelegate<TResponse> next, CancellationToken cancellationToken)
    {
        var requestName = typeof(TRequest).Name;
        var stopwatch = Stopwatch.StartNew();
        
        _logger.LogInformation("Ejecutando {RequestType}: {RequestName} {@Request}", 
            GetRequestType(requestName), requestName, request);

        try
        {
            var response = await next();
            stopwatch.Stop();

            _logger.LogInformation("{RequestType} ejecutado exitosamente: {RequestName} en {ElapsedMs}ms", 
                GetRequestType(requestName), requestName, stopwatch.ElapsedMilliseconds);

            return response;
        }        catch (Exception ex)
        {
            stopwatch.Stop();
            var logLevel = GetLogLevel(ex);

            _logger.Log(logLevel, ex, 
                "{RequestType} falló: {RequestName} después de {ElapsedMs}ms. Error: {ErrorCode} - {ErrorMessage}", 
                GetRequestType(requestName), 
                requestName, 
                stopwatch.ElapsedMilliseconds,
                ex is Exceptions.Base.IException customEx ? customEx.ErrorCode : ex.GetType().Name,
                ex.Message);

            throw; // Re-throw para que el middleware global maneje el Problem Details
        }
    }    /// <summary>
    /// Determina si es un comando o query basado en el nombre
    /// </summary>
    private static string GetRequestType(string requestName)
    {
        return requestName.EndsWith("Command") ? "Comando" :
               requestName.EndsWith("Query") ? "Query" :
               "Request";
    }

    /// <summary>
    /// Obtiene el nivel de log apropiado para una excepción
    /// </summary>
    private static LogLevel GetLogLevel(Exception exception)
    {
        return exception switch
        {
            Exceptions.Business.ValidationException => LogLevel.Warning,
            Exceptions.Application.NotFoundException => LogLevel.Warning,
            Exceptions.Business.BusinessRuleException => LogLevel.Warning,
            Exceptions.Business.DomainException => LogLevel.Warning,
            Exceptions.Application.UnauthorizedException => LogLevel.Warning,
            Exceptions.Application.ForbiddenException => LogLevel.Warning,
            _ when IsBusinessException(exception) => LogLevel.Warning,
            _ when IsTechnicalException(exception) => LogLevel.Error,
            _ => LogLevel.Error
        };
    }

    /// <summary>
    /// Verifica si una excepción es de tipo business/domain
    /// </summary>
    private static bool IsBusinessException(Exception exception)
    {
        return exception is Exceptions.Base.IException customException && 
               customException.Extensions.ContainsKey("domain") && 
               (customException.Extensions["domain"].ToString() == "business_logic" ||
                customException.Extensions["domain"].ToString() == "business_rule" ||
                customException.Extensions["domain"].ToString() == "validation");
    }

    /// <summary>
    /// Verifica si una excepción es técnica/de infraestructura
    /// </summary>
    private static bool IsTechnicalException(Exception exception)
    {
        return exception is Exceptions.Base.IException customException && 
               customException.Extensions.ContainsKey("domain") && 
               (customException.Extensions["domain"].ToString() == "infrastructure" ||
                customException.Extensions["domain"].ToString() == "database");
    }
}
