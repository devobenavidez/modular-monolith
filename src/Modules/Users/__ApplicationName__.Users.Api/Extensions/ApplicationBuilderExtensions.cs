using Microsoft.AspNetCore.Builder;

namespace __RootNamespace__.Users.Api.Extensions;

public static class ApplicationBuilderExtensions
{
    public static IApplicationBuilder UseUsersModule(this IApplicationBuilder app)
    {
        // Module-specific configurations if needed
        // Por ejemplo: middleware específico, rutas adicionales, etc.
        
        return app;
    }
}
