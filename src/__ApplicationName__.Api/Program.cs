using __RootNamespace__.Api.Extensions;
using __RootNamespace__.SharedKernel.Extensions;
using __RootNamespace__.Users.Api.Extensions;
using Asp.Versioning.ApiExplorer;
using Serilog;
using Prometheus;

var builder = WebApplication.CreateBuilder(args);

// Configurar Serilog
builder.Host.UseSerilog((context, configuration) =>
    configuration.ReadFrom.Configuration(context.Configuration));

// Servicios de la aplicación
builder.Services.AddApiServices();

// Módulos
builder.Services.AddSharedKernel(builder.Configuration);
builder.Services.AddUsersModule(builder.Configuration);

var app = builder.Build();

// Pipeline de middleware
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    
    // Configurar Swagger UI para múltiples versiones
    var apiVersionDescriptionProvider = app.Services.GetRequiredService<IApiVersionDescriptionProvider>();
    app.UseSwaggerUI(c =>
    {
        foreach (var description in apiVersionDescriptionProvider.ApiVersionDescriptions)
        {
            c.SwaggerEndpoint(
                $"/swagger/{description.GroupName}/swagger.json",
                $"__ApplicationName__ API {description.GroupName.ToUpperInvariant()}");
        }
        
        // Configuraciones adicionales de Swagger UI
        c.DocExpansion(Swashbuckle.AspNetCore.SwaggerUI.DocExpansion.List);
        c.DefaultModelsExpandDepth(-1); // Ocultar modelos por defecto
        c.DisplayRequestDuration();
        c.EnableFilter();
        c.EnableTryItOutByDefault();
        
        // Customize page title
        c.DocumentTitle = "__ApplicationName__ API Documentation";
        c.RoutePrefix = string.Empty; // Hacer que Swagger UI sea la página de inicio
    });
}

app.UseSerilogRequestLogging();
app.UseHttpsRedirection();
app.UseRouting();
app.UseAuthentication();
app.UseAuthorization();

// Métricas de Prometheus
app.UseMetricServer();
app.UseHttpMetrics();

// Health Checks
app.MapHealthChecks("/health");

// Controladores
app.MapControllers();

// Endpoints de módulos
app.UseUsersModule();

try
{
    Log.Information("Iniciando __ApplicationName__.Api");
    app.Run();
}
catch (Exception ex)
{
    Log.Fatal(ex, "La aplicación falló al iniciar");
}
finally
{
    Log.CloseAndFlush();
}

// Make Program class accessible to integration tests
public partial class Program { }
