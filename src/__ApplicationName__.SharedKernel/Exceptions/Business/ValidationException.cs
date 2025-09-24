using __RootNamespace__.SharedKernel.Exceptions.Base;
using FluentValidation.Results;

namespace __RootNamespace__.SharedKernel.Exceptions.Business;

/// <summary>
/// Excepción para errores de validación de datos.
/// Se mapea a HTTP 400 Bad Request con ValidationProblemDetails.
/// </summary>
public class ValidationException : BaseException
{
    public ValidationException(string message) : base(message)
    {
        ValidationErrors = new Dictionary<string, string[]>();
        AddExtension("domain", "validation");
    }

    public ValidationException(string message, IEnumerable<ValidationFailure> failures) : base(message)
    {
        ValidationErrors = failures
            .GroupBy(e => e.PropertyName, e => e.ErrorMessage)
            .ToDictionary(failureGroup => failureGroup.Key, failureGroup => failureGroup.ToArray());

        AddExtension("domain", "validation");
        AddExtension("validationErrors", ValidationErrors);
    }

    public ValidationException(string message, IDictionary<string, string[]> validationErrors) : base(message)
    {
        ValidationErrors = validationErrors;
        AddExtension("domain", "validation");
        AddExtension("validationErrors", ValidationErrors);
    }

    public ValidationException(string propertyName, string errorMessage) : base($"Validation failed for {propertyName}")
    {
        ValidationErrors = new Dictionary<string, string[]>
        {
            { propertyName, new[] { errorMessage } }
        };
        AddExtension("domain", "validation");
        AddExtension("validationErrors", ValidationErrors);
    }

    /// <summary>
    /// Errores de validación agrupados por campo
    /// </summary>
    public IDictionary<string, string[]> ValidationErrors { get; }

    public override string ErrorCode => "VALIDATION_ERROR";
    public override int StatusCode => 400; // Bad Request
    public override string Title => "Validation Failed";
    public override string? ProblemType => "https://tools.ietf.org/html/rfc7231#section-6.5.1";
}
