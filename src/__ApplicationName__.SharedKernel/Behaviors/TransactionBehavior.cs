using MediatR;
using Microsoft.Extensions.Logging;
using __RootNamespace__.SharedKernel.Interfaces;

namespace __RootNamespace__.SharedKernel.Behaviors;

/// <summary>
/// Behavior de MediatR para manejo de transacciones con EF Core y Dapper
/// </summary>
public class TransactionBehavior<TRequest, TResponse> : IPipelineBehavior<TRequest, TResponse>
    where TRequest : IRequest<TResponse>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<TransactionBehavior<TRequest, TResponse>> _logger;

    public TransactionBehavior(IUnitOfWork unitOfWork, ILogger<TransactionBehavior<TRequest, TResponse>> logger)
    {
        _unitOfWork = unitOfWork;
        _logger = logger;
    }

    public async Task<TResponse> Handle(TRequest request, RequestHandlerDelegate<TResponse> next, CancellationToken cancellationToken)
    {
        var requestName = typeof(TRequest).Name;
        var isCommand = requestName.EndsWith("Command");

        // Solo manejar transacciones para comandos (operaciones de escritura)
        if (!isCommand)
        {
            return await next();
        }

        _logger.LogInformation("Iniciando transacción para: {RequestName}", requestName);

        try
        {
            await _unitOfWork.BeginTransactionAsync();
            
            var response = await next();
            
            await _unitOfWork.SaveChangesAsync(cancellationToken);
            await _unitOfWork.CommitTransactionAsync();
            
            _logger.LogInformation("Transacción completada para: {RequestName}", requestName);
            
            return response;
        }
        catch (Exception ex)
        {
            await _unitOfWork.RollbackTransactionAsync();
            _logger.LogError(ex, "Transacción fallida para: {RequestName}", requestName);
            throw;
        }
    }
}

