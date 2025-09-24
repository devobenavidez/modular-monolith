using __RootNamespace__.SharedKernel.Exceptions.Base;

namespace __RootNamespace__.SharedKernel.Exceptions.Technical;

/// <summary>
/// Excepción para errores relacionados con la base de datos.
/// Se mapea a HTTP 500 Internal Server Error.
/// </summary>
public class DatabaseException : BaseException
{
    public DatabaseException(string message) : base(message)
    {
        AddExtension("domain", "database");
    }

    public DatabaseException(string message, Exception innerException) : base(message, innerException)
    {
        AddExtension("domain", "database");
    }

    public DatabaseException(string operation, string message) : base(message)
    {
        Operation = operation;
        AddExtension("domain", "database");
        AddExtension("operation", operation);
    }

    public DatabaseException(string operation, string message, Exception innerException) : base(message, innerException)
    {
        Operation = operation;
        AddExtension("domain", "database");
        AddExtension("operation", operation);
    }

    public DatabaseException(string operation, string tableName, string message) : base(message)
    {
        Operation = operation;
        TableName = tableName;
        AddExtension("domain", "database");
        AddExtension("operation", operation);
        AddExtension("tableName", tableName);
    }

    /// <summary>
    /// Operación de base de datos que falló (SELECT, INSERT, UPDATE, DELETE)
    /// </summary>
    public string? Operation { get; }

    /// <summary>
    /// Nombre de la tabla afectada (opcional)
    /// </summary>
    public string? TableName { get; }

    public override string ErrorCode => "DATABASE_ERROR";
    public override int StatusCode => 500; // Internal Server Error
    public override string Title => "Database Operation Failed";
    public override string? ProblemType => "https://tools.ietf.org/html/rfc7231#section-6.6.1";
}
