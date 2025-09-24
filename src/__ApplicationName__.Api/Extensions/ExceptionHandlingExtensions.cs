using __RootNamespace__.Api.Middleware;

namespace __RootNamespace__.Api.Extensions;

/// <summary>
/// Extensiones para configurar el middleware de manejo de excepciones
/// </summary>
public static class ExceptionHandlingExtensions
{
    /// <summary>
    /// Agrega el middleware global de manejo de excepciones
    /// </summary>
    /// <param name="app">Application builder</param>
    /// <returns>Application builder para encadenamiento</returns>
    public static IApplicationBuilder UseGlobalExceptionHandler(this IApplicationBuilder app)
    {
        return app.UseMiddleware<GlobalExceptionHandlerMiddleware>();
    }
}
