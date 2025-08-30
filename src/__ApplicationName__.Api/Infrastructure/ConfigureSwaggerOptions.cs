using Asp.Versioning.ApiExplorer;
using Microsoft.Extensions.Options;
using Microsoft.OpenApi.Models;
using Swashbuckle.AspNetCore.SwaggerGen;

namespace __RootNamespace__.Api.Infrastructure;

/// <summary>
/// Configuración de Swagger para múltiples versiones de API
/// </summary>
public class ConfigureSwaggerOptions : IConfigureNamedOptions<SwaggerGenOptions>
{
    private readonly IApiVersionDescriptionProvider _provider;

    public ConfigureSwaggerOptions(IApiVersionDescriptionProvider provider)
    {
        _provider = provider;
    }

    public void Configure(SwaggerGenOptions options)
    {
        // Agregar un documento para cada versión de API descubierta
        foreach (var description in _provider.ApiVersionDescriptions)
        {
            options.SwaggerDoc(description.GroupName, CreateVersionInfo(description));
        }
    }

    public void Configure(string? name, SwaggerGenOptions options)
    {
        Configure(options);
    }

    private static OpenApiInfo CreateVersionInfo(ApiVersionDescription description)
    {
        var info = new OpenApiInfo
        {
            Title = "__ApplicationName__ API",
            Version = description.ApiVersion.ToString(),
            Description = "__ApplicationName__ API system - Modular Architecture with versioning",
            Contact = new OpenApiContact
            {
                Name = "Celuweb",
                Email = "info@celuweb.com",
                Url = new Uri("https://celuweb.com")
            },
            License = new OpenApiLicense
            {
                Name = "MIT",
                Url = new Uri("https://opensource.org/licenses/MIT")
            }
        };

        if (description.IsDeprecated)
        {
            info.Description += " (DEPRECADA - Esta versión será removida en futuras releases)";
        }

        return info;
    }
}
