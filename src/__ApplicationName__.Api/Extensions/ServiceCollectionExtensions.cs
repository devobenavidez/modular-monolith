using Microsoft.OpenApi.Models;
using Asp.Versioning;
using Asp.Versioning.ApiExplorer;
using Microsoft.AspNetCore.Routing;
using Microsoft.AspNetCore.Mvc.ApplicationModels;
using System.Reflection;
using System.Text.Json;
using __RootNamespace__.Api.Infrastructure;

namespace __RootNamespace__.Api.Extensions;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddApiServices(this IServiceCollection services)
    {
        // Configurar controladores con opciones JSON mejoradas
        services.AddControllers(options =>
        {
            // Configurar nombrado de rutas en minúsculas
            options.Conventions.Add(new RouteTokenTransformerConvention(new KebabCaseParameterTransformer()));
        })
        .AddJsonOptions(options =>
        {
            // Configurar JSON para usar camelCase
            options.JsonSerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.CamelCase;
            options.JsonSerializerOptions.WriteIndented = true;
        });

        services.AddEndpointsApiExplorer();
        
        // Configurar versionado de API
        services.AddApiVersioning(options =>
        {
            options.DefaultApiVersion = new ApiVersion(1, 0);
            options.AssumeDefaultVersionWhenUnspecified = true;
            options.ApiVersionReader = ApiVersionReader.Combine(
                new UrlSegmentApiVersionReader(),
                new QueryStringApiVersionReader("version"),
                new HeaderApiVersionReader("X-Version")
            );
        })
        .AddMvc()
        .AddApiExplorer(setup =>
        {
            setup.GroupNameFormat = "'v'VVV";
            setup.SubstituteApiVersionInUrl = true;
        });

        // Configurar Swagger con versionado
        services.ConfigureOptions<ConfigureSwaggerOptions>();
        services.AddSwaggerGen(c =>
        {
            var xmlFile = $"{Assembly.GetExecutingAssembly().GetName().Name}.xml";
            var xmlPath = Path.Combine(AppContext.BaseDirectory, xmlFile);
            if (File.Exists(xmlPath))
            {
                c.IncludeXmlComments(xmlPath);
            }

            // Configurar esquemas para usar camelCase
            c.DescribeAllParametersInCamelCase();
            
            // Personalizar nombres de operaciones para que sean más legibles
            c.CustomOperationIds(apiDesc =>
            {
                var controllerName = apiDesc.ActionDescriptor.RouteValues["controller"];
                var actionName = apiDesc.ActionDescriptor.RouteValues["action"];
                var httpMethod = apiDesc.HttpMethod?.ToLowerInvariant();
                
                return $"{httpMethod}_{controllerName?.ToLowerInvariant()}_{actionName?.ToLowerInvariant()}";
            });
            
            // Configurar filtros de esquema para camelCase
            c.SchemaFilter<CamelCaseSchemaFilter>();
        });

        services.AddHealthChecks();

        services.AddCors(options =>
        {
            options.AddDefaultPolicy(builder =>
            {
                builder.AllowAnyOrigin()
                       .AllowAnyMethod()
                       .AllowAnyHeader();
            });
        });

        return services;
    }
}
