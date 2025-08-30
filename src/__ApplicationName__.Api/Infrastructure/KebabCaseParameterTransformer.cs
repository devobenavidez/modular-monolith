using System.Text.RegularExpressions;

namespace __RootNamespace__.Api.Infrastructure;

/// <summary>
/// Transforma los nombres de rutas a kebab-case (minúsculas con guiones)
/// </summary>
public class KebabCaseParameterTransformer : IOutboundParameterTransformer
{
    public string? TransformOutbound(object? value)
    {
        if (value == null) return null;

        var stringValue = value.ToString();
        if (string.IsNullOrEmpty(stringValue)) return stringValue;

        // Convertir PascalCase a kebab-case
        return Regex.Replace(stringValue, "([a-z])([A-Z])", "$1-$2").ToLowerInvariant();
    }
}
