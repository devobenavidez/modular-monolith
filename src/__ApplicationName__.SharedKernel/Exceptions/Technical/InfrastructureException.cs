using __RootNamespace__.SharedKernel.Exceptions.Base;

namespace __RootNamespace__.SharedKernel.Exceptions.Technical;

/// <summary>
/// Excepción para errores de infraestructura (servicios externos, configuración, etc.).
/// Se mapea a HTTP 503 Service Unavailable.
/// </summary>
public class InfrastructureException : BaseException
{
    public InfrastructureException(string message) : base(message)
    {
        AddExtension("domain", "infrastructure");
    }

    public InfrastructureException(string message, Exception innerException) : base(message, innerException)
    {
        AddExtension("domain", "infrastructure");
    }

    public InfrastructureException(string serviceName, string message) : base(message)
    {
        ServiceName = serviceName;
        AddExtension("domain", "infrastructure");
        AddExtension("serviceName", serviceName);
    }

    public InfrastructureException(string serviceName, string message, Exception innerException) : base(message, innerException)
    {
        ServiceName = serviceName;
        AddExtension("domain", "infrastructure");
        AddExtension("serviceName", serviceName);
    }

    /// <summary>
    /// Nombre del servicio o componente de infraestructura que falló
    /// </summary>
    public string? ServiceName { get; }

    public override string ErrorCode => "INFRASTRUCTURE_ERROR";
    public override int StatusCode => 503; // Service Unavailable
    public override string Title => "Infrastructure Service Unavailable";
    public override string? ProblemType => "https://tools.ietf.org/html/rfc7231#section-6.6.4";
}
