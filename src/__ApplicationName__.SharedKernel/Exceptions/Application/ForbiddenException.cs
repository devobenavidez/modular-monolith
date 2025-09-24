using __RootNamespace__.SharedKernel.Exceptions.Base;

namespace __RootNamespace__.SharedKernel.Exceptions.Application;

/// <summary>
/// Excepción para errores de autorización (usuario autenticado pero sin permisos).
/// Se mapea a HTTP 403 Forbidden.
/// </summary>
public class ForbiddenException : BaseException
{
    public ForbiddenException(string message = "Access to this resource is forbidden") : base(message)
    {
        AddExtension("domain", "security");
    }

    public ForbiddenException(string message, Exception innerException) : base(message, innerException)
    {
        AddExtension("domain", "security");
    }

    public ForbiddenException(string resource, string action) 
        : base($"Access forbidden: insufficient permissions to {action} {resource}")
    {
        Resource = resource;
        Action = action;
        AddExtension("domain", "security");
        AddExtension("resource", resource);
        AddExtension("action", action);
    }

    public ForbiddenException(string resource, string action, string requiredPermission) 
        : base($"Access forbidden: '{requiredPermission}' permission required to {action} {resource}")
    {
        Resource = resource;
        Action = action;
        RequiredPermission = requiredPermission;
        AddExtension("domain", "security");
        AddExtension("resource", resource);
        AddExtension("action", action);
        AddExtension("requiredPermission", requiredPermission);
    }

    /// <summary>
    /// Recurso que se intentó acceder
    /// </summary>
    public string? Resource { get; }

    /// <summary>
    /// Acción que se intentó realizar
    /// </summary>
    public string? Action { get; }

    /// <summary>
    /// Permiso requerido para la acción
    /// </summary>
    public string? RequiredPermission { get; }

    public override string ErrorCode => "FORBIDDEN";
    public override int StatusCode => 403; // Forbidden
    public override string Title => "Access Forbidden";
    public override string? ProblemType => "https://tools.ietf.org/html/rfc7231#section-6.5.3";
}
