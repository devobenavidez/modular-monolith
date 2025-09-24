using __RootNamespace__.SharedKernel.Exceptions.Base;

namespace __RootNamespace__.SharedKernel.Exceptions.Application;

/// <summary>
/// Excepción para recursos no encontrados.
/// Se mapea a HTTP 404 Not Found.
/// </summary>
public class NotFoundException : BaseException
{
    public NotFoundException(string message) : base(message)
    {
        AddExtension("domain", "application");
    }

    public NotFoundException(string resourceType, object resourceId) 
        : base($"{resourceType} with ID '{resourceId}' was not found")
    {
        ResourceType = resourceType;
        ResourceId = resourceId;
        AddExtension("domain", "application");
        AddExtension("resourceType", resourceType);
        AddExtension("resourceId", resourceId);
    }    public NotFoundException(string resourceType, string propertyName, object propertyValue) 
        : base($"{resourceType} with {propertyName} '{propertyValue}' was not found")
    {
        ResourceType = resourceType;
        AddExtension("domain", "application");
        AddExtension("resourceType", resourceType);
        AddExtension("searchCriteria", new Dictionary<string, object> { { propertyName, propertyValue } });
    }

    /// <summary>
    /// Tipo de recurso que no fue encontrado
    /// </summary>
    public string? ResourceType { get; }

    /// <summary>
    /// ID del recurso que no fue encontrado
    /// </summary>
    public object? ResourceId { get; }

    public override string ErrorCode => "RESOURCE_NOT_FOUND";
    public override int StatusCode => 404; // Not Found
    public override string Title => "Resource Not Found";
    public override string? ProblemType => "https://tools.ietf.org/html/rfc7231#section-6.5.4";
}
