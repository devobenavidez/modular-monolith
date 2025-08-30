using MediatR;
using Microsoft.Extensions.Logging;

namespace __RootNamespace__.SharedKernel.Behaviors;

/// <summary>
/// Behavior de MediatR para logging automático de comandos y queries
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
        
        _logger.LogInformation("Ejecutando comando/query: {RequestName} {@Request}", requestName, request);

        var response = await next();

        _logger.LogInformation("Comando/query ejecutado: {RequestName}", requestName);

        return response;
    }
}
