using MediatR;
using Microsoft.Extensions.Logging;

namespace __RootNamespace__.SharedKernel.Behaviors;

/// <summary>
/// Behavior de MediatR para logging de consultas Dapper
/// </summary>
public class DapperQueryBehavior<TRequest, TResponse> : IPipelineBehavior<TRequest, TResponse>
    where TRequest : IRequest<TResponse>
{
    private readonly ILogger<DapperQueryBehavior<TRequest, TResponse>> _logger;

    public DapperQueryBehavior(ILogger<DapperQueryBehavior<TRequest, TResponse>> logger)
    {
        _logger = logger;
    }

    public async Task<TResponse> Handle(TRequest request, RequestHandlerDelegate<TResponse> next, CancellationToken cancellationToken)
    {
        var requestName = typeof(TRequest).Name;
        var startTime = DateTime.UtcNow;

        _logger.LogInformation("Iniciando consulta Dapper: {RequestName}", requestName);

        try
        {
            var response = await next();
            
            var duration = DateTime.UtcNow - startTime;
            _logger.LogInformation("Consulta Dapper completada: {RequestName} en {Duration}ms", requestName, duration.TotalMilliseconds);
            
            return response;
        }
        catch (Exception ex)
        {
            var duration = DateTime.UtcNow - startTime;
            _logger.LogError(ex, "Error en consulta Dapper: {RequestName} después de {Duration}ms", requestName, duration.TotalMilliseconds);
            throw;
        }
    }
}

