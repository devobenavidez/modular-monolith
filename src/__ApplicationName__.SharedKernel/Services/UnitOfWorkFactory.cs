using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using __RootNamespace__.SharedKernel.Interfaces;
using __RootNamespace__.SharedKernel.Attributes;

namespace __RootNamespace__.SharedKernel.Services;

/// <summary>
/// Factory que auto-descubre y resuelve automáticamente el IUnitOfWork correcto
/// basándose en el namespace del tipo de repositorio y atributos de módulo
/// </summary>
public class UnitOfWorkFactory : IUnitOfWorkFactory
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<UnitOfWorkFactory> _logger;
    private readonly Dictionary<string, Type> _moduleContextMap;

    public UnitOfWorkFactory(IServiceProvider serviceProvider, ILogger<UnitOfWorkFactory> logger)
    {
        _serviceProvider = serviceProvider ?? throw new ArgumentNullException(nameof(serviceProvider));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        
        // Auto-descubrir contextos marcados con ModuleContextAttribute
        _moduleContextMap = DiscoverModuleContexts();
        
        _logger.LogInformation("UnitOfWorkFactory inicializado con {Count} módulos: {Modules}", 
            _moduleContextMap.Count, 
            string.Join(", ", _moduleContextMap.Keys));
    }

    public IUnitOfWork GetUnitOfWork<TRepository>() where TRepository : class
    {
        var repositoryType = typeof(TRepository);
        var repositoryNamespace = repositoryType.Namespace ?? string.Empty;

        _logger.LogDebug("Resolviendo UnitOfWork para repositorio: {RepositoryType} en namespace: {Namespace}", 
            repositoryType.Name, repositoryNamespace);

        // Buscar el contexto apropiado basado en el namespace del repositorio
        var contextType = FindContextForNamespace(repositoryNamespace);
        
        if (contextType == null)
        {
            var availableModules = string.Join(", ", _moduleContextMap.Keys);
            throw new InvalidOperationException(
                $"No se encontró un contexto registrado para el namespace: {repositoryNamespace}. " +
                $"Asegúrate de que el DbContext tenga el atributo [ModuleContext]. " +
                $"Módulos disponibles: {availableModules}");
        }
        
        _logger.LogDebug("Contexto encontrado: {ContextType} para repositorio {Repository}", 
            contextType.Name, repositoryType.Name);
        
        // Resolver el contexto específico que implementa IUnitOfWork
        var context = _serviceProvider.GetRequiredService(contextType);
        
        if (context is not IUnitOfWork unitOfWork)
        {
            throw new InvalidOperationException($"El contexto {contextType.Name} no implementa IUnitOfWork");
        }
        
        return unitOfWork;
    }
    
    /// <summary>
    /// Auto-descubre todos los contextos de módulos marcados con ModuleContextAttribute
    /// </summary>
    private Dictionary<string, Type> DiscoverModuleContexts()
    {
        var contextMap = new Dictionary<string, Type>();
        
        try
        {
            // Obtener todos los assemblies cargados relacionados con la aplicación
            var assemblies = AppDomain.CurrentDomain.GetAssemblies()
                .Where(a => !a.IsDynamic && 
                           !string.IsNullOrEmpty(a.FullName) &&
                           !a.FullName.StartsWith("System") &&
                           !a.FullName.StartsWith("Microsoft") &&
                           a.FullName.Contains("__ApplicationName__"))
                .ToList();
            
            _logger.LogDebug("Escaneando {Count} assemblies para contextos de módulos", assemblies.Count);
            
            foreach (var assembly in assemblies)
            {
                try
                {
                    var contextTypes = assembly.GetTypes()
                        .Where(t => t.IsClass && 
                                   !t.IsAbstract &&
                                   typeof(IUnitOfWork).IsAssignableFrom(t) &&
                                   t.GetCustomAttribute<ModuleContextAttribute>() != null)
                        .ToList();
                    
                    foreach (var contextType in contextTypes)
                    {
                        var attribute = contextType.GetCustomAttribute<ModuleContextAttribute>();
                        if (attribute == null) continue;
                        
                        _logger.LogDebug("Registrando contexto {ContextType} para módulo {ModuleName} con namespaces: {Namespaces}", 
                            contextType.Name, 
                            attribute.ModuleName, 
                            string.Join(", ", attribute.Namespaces));
                        
                        foreach (var nameSpace in attribute.Namespaces)
                        {
                            if (contextMap.ContainsKey(nameSpace))
                            {
                                _logger.LogWarning("Namespace duplicado {Namespace} encontrado en contextos {Existing} y {New}", 
                                    nameSpace, contextMap[nameSpace].Name, contextType.Name);
                            }
                            
                            contextMap[nameSpace] = contextType;
                        }
                    }
                }
                catch (ReflectionTypeLoadException ex)
                {
                    _logger.LogDebug("No se pudo cargar completamente el assembly {AssemblyName}: {Error}", 
                        assembly.FullName, ex.Message);
                    continue;
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Error al escanear assembly {AssemblyName}", assembly.FullName);
                    continue;
                }
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error crítico al auto-descubrir contextos de módulos");
            throw new InvalidOperationException("Error al auto-descubrir contextos de módulos", ex);
        }
        
        if (contextMap.Count == 0)
        {
            _logger.LogWarning("No se encontraron contextos marcados con [ModuleContext]. Usando fallback a configuración manual");
            return GetFallbackContextMap();
        }
        
        return contextMap;
    }
    
    /// <summary>
    /// Configuración manual como fallback si no se encuentran atributos
    /// </summary>
    private Dictionary<string, Type> GetFallbackContextMap()
    {
        // NOTA: Este es un fallback temporal. Se recomienda usar [ModuleContext]
        _logger.LogInformation("Usando mapeo manual como fallback");
        
        var fallbackMap = new Dictionary<string, Type>();
        
        // Intentar resolver los tipos dinámicamente
        try
        {
            var productsContextType = Type.GetType("__RootNamespace__.Products.Infrastructure.Persistence.ProductsExtendedDbContext, __ApplicationName__.Products.Infrastructure");
            if (productsContextType != null)
            {
                fallbackMap["__RootNamespace__.Products"] = productsContextType;
            }
            
            var usersContextType = Type.GetType("__RootNamespace__.Users.Infrastructure.Persistence.UsersExtendedDbContext, __ApplicationName__.Users.Infrastructure");
            if (usersContextType != null)
            {
                fallbackMap["__RootNamespace__.Users"] = usersContextType;
            }
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Error al configurar mapeo de fallback");
        }
        
        return fallbackMap;
    }
    
    /// <summary>
    /// Encuentra el contexto más específico para el namespace dado
    /// </summary>
    private Type? FindContextForNamespace(string repositoryNamespace)
    {
        // Buscar coincidencia exacta o más específica
        var matchingModule = _moduleContextMap
            .Where(kvp => repositoryNamespace.StartsWith(kvp.Key, StringComparison.OrdinalIgnoreCase))
            .OrderByDescending(kvp => kvp.Key.Length) // Preferir coincidencias más específicas
            .FirstOrDefault();
            
        return matchingModule.Key != null ? matchingModule.Value : null;
    }
}
