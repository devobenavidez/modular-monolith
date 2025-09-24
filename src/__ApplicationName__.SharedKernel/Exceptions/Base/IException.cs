namespace __RootNamespace__.SharedKernel.Exceptions.Base;

/// <summary>
/// Interface común para todas las excepciones personalizadas del sistema
/// </summary>
public interface IException
{
    /// <summary>
    /// Código único del error para identificación
    /// </summary>
    string ErrorCode { get; }

    /// <summary>
    /// Código de estado HTTP que debe retornarse
    /// </summary>
    int StatusCode { get; }

    /// <summary>
    /// Título del error (para Problem Details)
    /// </summary>
    string Title { get; }

    /// <summary>
    /// Extensiones adicionales para Problem Details
    /// </summary>
    IDictionary<string, object> Extensions { get; }

    /// <summary>
    /// Tipo de Problem Details URI (opcional)
    /// </summary>
    string? ProblemType { get; }
}
