using __RootNamespace__.SharedKernel.Exceptions.Base;

namespace __RootNamespace__.SharedKernel.Exceptions.Business;

/// <summary>
/// Excepción para violaciones de reglas de negocio específicas.
/// Se mapea a HTTP 409 Conflict.
/// </summary>
public class BusinessRuleException : BaseException
{
    public BusinessRuleException(string message) : base(message)
    {
        AddExtension("domain", "business_rule");
    }

    public BusinessRuleException(string message, Exception innerException) : base(message, innerException)
    {
        AddExtension("domain", "business_rule");
    }

    public BusinessRuleException(string ruleName, string message) : base(message)
    {
        RuleName = ruleName;
        AddExtension("domain", "business_rule");
        AddExtension("ruleName", ruleName);
    }

    public BusinessRuleException(string ruleName, string message, object context) : base(message)
    {
        RuleName = ruleName;
        AddExtension("domain", "business_rule");
        AddExtension("ruleName", ruleName);
        AddExtension("context", context);
    }

    /// <summary>
    /// Nombre de la regla de negocio que fue violada
    /// </summary>
    public string? RuleName { get; }

    public override string ErrorCode => "BUSINESS_RULE_VIOLATION";
    public override int StatusCode => 409; // Conflict
    public override string Title => "Business Rule Violation";
    public override string? ProblemType => "https://tools.ietf.org/html/rfc7231#section-6.5.8";
}
