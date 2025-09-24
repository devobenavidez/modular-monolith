using __RootNamespace__.SharedKernel.Exceptions.Base;

namespace __RootNamespace__.SharedKernel.Exceptions.Application;

/// <summary>
/// Excepción para errores de autorización (usuario no autenticado).
/// Se mapea a HTTP 401 Unauthorized.
/// </summary>
public class UnauthorizedException : BaseException
{
    public UnauthorizedException(string message = "Authentication is required") : base(message)
    {
        AddExtension("domain", "security");
    }

    public UnauthorizedException(string message, Exception innerException) : base(message, innerException)
    {
        AddExtension("domain", "security");
    }

    public UnauthorizedException(string resource, string action) 
        : base($"Authentication is required to {action} {resource}")
    {
        Resource = resource;
        Action = action;
        AddExtension("domain", "security");
        AddExtension("resource", resource);
        AddExtension("action", action);
    }

    /// <summary>
    /// Recurso que se intentó acceder
    /// </summary>
    public string? Resource { get; }

    /// <summary>
    /// Acción que se intentó realizar
    /// </summary>
    public string? Action { get; }

    public override string ErrorCode => "UNAUTHORIZED";
    public override int StatusCode => 401; // Unauthorized
    public override string Title => "Authentication Required";
    public override string? ProblemType => "https://tools.ietf.org/html/rfc7235#section-3.1";
}
