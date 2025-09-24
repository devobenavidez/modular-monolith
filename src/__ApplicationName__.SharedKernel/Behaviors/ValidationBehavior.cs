using FluentValidation;
using MediatR;
using __RootNamespace__.SharedKernel.Exceptions.Business;

namespace __RootNamespace__.SharedKernel.Behaviors;

/// <summary>
/// Behavior de MediatR para validación automática usando FluentValidation.
/// Convierte errores de FluentValidation en ValidationException personalizada para Problem Details.
/// </summary>
public class ValidationBehavior<TRequest, TResponse> : IPipelineBehavior<TRequest, TResponse>
    where TRequest : IRequest<TResponse>
{
    private readonly IEnumerable<IValidator<TRequest>> _validators;

    public ValidationBehavior(IEnumerable<IValidator<TRequest>> validators)
    {
        _validators = validators;
    }

    public async Task<TResponse> Handle(TRequest request, RequestHandlerDelegate<TResponse> next, CancellationToken cancellationToken)
    {
        if (_validators.Any())
        {
            var context = new ValidationContext<TRequest>(request);

            var validationResults = await Task.WhenAll(
                _validators.Select(v => v.ValidateAsync(context, cancellationToken)));

            var failures = validationResults
                .Where(r => r.Errors.Any())
                .SelectMany(r => r.Errors)
                .ToList();            if (failures.Any())
            {
                // Usar nuestra ValidationException personalizada que se convierte en Problem Details
                throw new Exceptions.Business.ValidationException($"Validation failed for {typeof(TRequest).Name}", failures);
            }
        }

        return await next();
    }
}
