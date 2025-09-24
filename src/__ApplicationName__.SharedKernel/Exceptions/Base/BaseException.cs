namespace __RootNamespace__.SharedKernel.Exceptions.Base;

/// <summary>
/// Excepción base abstracta para todas las excepciones personalizadas del sistema.
/// Implementa IException y proporciona funcionalidad común para Problem Details.
/// </summary>
public abstract class BaseException : Exception, IException
{
    protected BaseException(string message) : base(message)
    {
        Extensions = new Dictionary<string, object>();
        InitializeDefaults();
    }

    protected BaseException(string message, Exception innerException) : base(message, innerException)
    {
        Extensions = new Dictionary<string, object>();
        InitializeDefaults();
    }

    /// <summary>
    /// Código único del error para identificación
    /// </summary>
    public abstract string ErrorCode { get; }

    /// <summary>
    /// Código de estado HTTP que debe retornarse
    /// </summary>
    public abstract int StatusCode { get; }

    /// <summary>
    /// Título del error (para Problem Details)
    /// </summary>
    public abstract string Title { get; }

    /// <summary>
    /// Tipo de Problem Details URI (opcional)
    /// </summary>
    public virtual string? ProblemType => null;

    /// <summary>
    /// Extensiones adicionales para Problem Details
    /// </summary>
    public IDictionary<string, object> Extensions { get; }

    /// <summary>
    /// Inicializa valores por defecto en la excepción
    /// </summary>
    private void InitializeDefaults()
    {
        Extensions["errorCode"] = ErrorCode;
        Extensions["timestamp"] = DateTime.UtcNow;
        
        if (!string.IsNullOrEmpty(ProblemType))
        {
            Extensions["type"] = ProblemType;
        }
    }

    /// <summary>
    /// Agrega información adicional a las extensiones
    /// </summary>
    protected void AddExtension(string key, object value)
    {
        Extensions[key] = value;
    }

    /// <summary>
    /// Agrega múltiples extensiones de una vez
    /// </summary>
    protected void AddExtensions(IDictionary<string, object> extensions)
    {
        foreach (var kvp in extensions)
        {
            Extensions[kvp.Key] = kvp.Value;
        }
    }
}
