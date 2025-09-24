using __RootNamespace__.SharedKernel.Exceptions.Base;

namespace __RootNamespace__.SharedKernel.Exceptions.Business;

/// <summary>
/// Excepción para errores de dominio y reglas de negocio.
/// Se mapea a HTTP 422 Unprocessable Entity.
/// </summary>
public class DomainException : BaseException
{
    public DomainException(string message) : base(message)
    {
        AddExtension("domain", "business_logic");
    }

    public DomainException(string message, Exception innerException) : base(message, innerException)
    {
        AddExtension("domain", "business_logic");
    }

    public DomainException(string message, string entityName) : base(message)
    {
        AddExtension("domain", "business_logic");
        AddExtension("entityName", entityName);
    }

    public DomainException(string message, string entityName, object entityId) : base(message)
    {
        AddExtension("domain", "business_logic");
        AddExtension("entityName", entityName);
        AddExtension("entityId", entityId);
    }

    public override string ErrorCode => "DOMAIN_ERROR";
    public override int StatusCode => 422; // Unprocessable Entity
    public override string Title => "Domain Rule Violation";
    public override string? ProblemType => "https://datatracker.ietf.org/doc/html/rfc4918#section-11.2";
}
