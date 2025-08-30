using Microsoft.AspNetCore.Mvc;
using System.Diagnostics;
using System.IO;
using System.Linq;
using Asp.Versioning;

namespace __RootNamespace__.Api.Controllers;

[ApiController]
[Route("api/v{version:apiVersion}")]
[ApiVersion("1.0")]
public class HomeController : ControllerBase
{    /// <summary>
    /// Root endpoint that provides API information
    /// </summary>
    [HttpGet]
    public ActionResult<object> Get()
    {
        // Detectar módulos dinámicamente
        var modulesPath = Path.Combine(Directory.GetCurrentDirectory(), "src", "Modules");
        string[] modules = new string[0];
        if (Directory.Exists(modulesPath))
        {
            modules = Directory.GetDirectories(modulesPath)
                .Select(dir => Path.GetFileName(dir))
                .Where(name => !string.IsNullOrWhiteSpace(name))
                .OrderBy(name => name)
                .ToArray();
        }

        var endpoints = modules.ToDictionary(
            m => m,
            m => $"/api/v1/{m.ToLower()}"
        );

        return Ok(new
        {
            Application = "__ApplicationName__ API",
            Version = "1.0.0",
            ApiVersion = "v1.0",
            Status = "Running",
            Architecture = "Modular Monolith",
            Modules = modules,
            Endpoints = new
            {
                Health = "/health",
                Metrics = "/metrics",
                Swagger = "/swagger",
                ApiInfo = "/api/v1",
                Modules = endpoints
            },
            Documentation = "/swagger",
            Timestamp = DateTime.UtcNow
        });
    }    /// <summary>
    /// Root endpoint without versioning for compatibility
    /// </summary>
    [HttpGet("/")]
    [ApiVersionNeutral]
    public ActionResult<object> GetRoot()
    {
        return Ok(new
        {
            Message = "Welcome to __ApplicationName__ API",
            Version = "1.0.0",
            Documentation = "/swagger",
            ApiEndpoint = "/api/v1",
            Health = "/health",
            Timestamp = DateTime.UtcNow
        });    }    /// <summary>
    /// Basic health status endpoint with versioning
    /// </summary>
    [HttpGet("status")]
    public ActionResult<object> Status()
    {
        return Ok(new
        {
            Status = "Healthy",
            ApiVersion = "v1.0",
            Timestamp = DateTime.UtcNow,
            Uptime = DateTime.UtcNow - Process.GetCurrentProcess().StartTime.ToUniversalTime()
        });
    }
}
