using Microsoft.OpenApi.Models;
using Swashbuckle.AspNetCore.SwaggerGen;
using System.Globalization;

namespace __RootNamespace__.Api.Infrastructure;

/// <summary>
/// Filtro de Swagger para asegurar que los esquemas usen camelCase
/// </summary>
public class CamelCaseSchemaFilter : ISchemaFilter
{
    public void Apply(OpenApiSchema schema, SchemaFilterContext context)
    {
        if (schema.Properties == null) return;

        var newProperties = new Dictionary<string, OpenApiSchema>();
        
        foreach (var property in schema.Properties)
        {
            var camelCaseKey = ToCamelCase(property.Key);
            newProperties[camelCaseKey] = property.Value;
        }

        schema.Properties.Clear();
        foreach (var property in newProperties)
        {
            schema.Properties.Add(property.Key, property.Value);
        }
    }

    private static string ToCamelCase(string input)
    {
        if (string.IsNullOrEmpty(input) || char.IsLower(input[0]))
            return input;

        return char.ToLowerInvariant(input[0]) + input[1..];
    }
}
