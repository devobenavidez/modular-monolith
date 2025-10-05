using Microsoft.EntityFrameworkCore;

namespace __RootNamespace__.SharedKernel.Database;

/// <summary>
/// Analizador centralizado para identificar tipos de violaciones de constraints de base de datos
/// Evita duplicación de código en command handlers
/// </summary>
public static class DatabaseConstraintAnalyzer
{
    /// <summary>
    /// Identifica si una DbUpdateException es causada por violación de constraint único
    /// </summary>
    public static bool IsUniqueConstraintViolation(DbUpdateException ex)
    {
        if (ex.InnerException?.Message == null) return false;
        
        var message = ex.InnerException.Message;
        return message.Contains("UNIQUE", StringComparison.OrdinalIgnoreCase) ||
               message.Contains("duplicate", StringComparison.OrdinalIgnoreCase) ||
               message.Contains("IX_", StringComparison.OrdinalIgnoreCase) || // SQL Server unique indexes
               message.Contains("UQ_", StringComparison.OrdinalIgnoreCase);   // SQL Server unique constraints
    }

    /// <summary>
    /// Identifica si una DbUpdateException es causada por violación de foreign key
    /// </summary>
    public static bool IsForeignKeyConstraintViolation(DbUpdateException ex)
    {
        if (ex.InnerException?.Message == null) return false;
        
        var message = ex.InnerException.Message;
        return message.Contains("FOREIGN KEY", StringComparison.OrdinalIgnoreCase) ||
               message.Contains("violates foreign key", StringComparison.OrdinalIgnoreCase) ||
               message.Contains("FK_", StringComparison.OrdinalIgnoreCase) ||
               message.Contains("REFERENCE constraint", StringComparison.OrdinalIgnoreCase);
    }

    /// <summary>
    /// Identifica si una DbUpdateException es causada por violación de check constraint
    /// </summary>
    public static bool IsCheckConstraintViolation(DbUpdateException ex)
    {
        if (ex.InnerException?.Message == null) return false;
        
        var message = ex.InnerException.Message;
        return message.Contains("CHECK constraint", StringComparison.OrdinalIgnoreCase) ||
               message.Contains("CK_", StringComparison.OrdinalIgnoreCase);
    }

    /// <summary>
    /// Obtiene el tipo de constraint violado para manejo específico
    /// </summary>
    public static DatabaseConstraintType GetConstraintType(DbUpdateException ex)
    {
        if (IsUniqueConstraintViolation(ex))
            return DatabaseConstraintType.UniqueConstraint;
        
        if (IsForeignKeyConstraintViolation(ex))
            return DatabaseConstraintType.ForeignKeyConstraint;
        
        if (IsCheckConstraintViolation(ex))
            return DatabaseConstraintType.CheckConstraint;
        
        return DatabaseConstraintType.Unknown;
    }

    /// <summary>
    /// Extrae el nombre del constraint de la excepción (cuando sea posible)
    /// </summary>
    public static string? ExtractConstraintName(DbUpdateException ex)
    {
        if (ex.InnerException?.Message == null) return null;

        var message = ex.InnerException.Message;
        
        // Patrón común: constraint "nombre_constraint"
        var constraintMatch = System.Text.RegularExpressions.Regex.Match(
            message, @"constraint ['""](\w+)['""]", 
            System.Text.RegularExpressions.RegexOptions.IgnoreCase);
        
        if (constraintMatch.Success)
            return constraintMatch.Groups[1].Value;

        // Patrón para índices únicos: index "nombre_index"
        var indexMatch = System.Text.RegularExpressions.Regex.Match(
            message, @"index ['""](\w+)['""]", 
            System.Text.RegularExpressions.RegexOptions.IgnoreCase);
        
        if (indexMatch.Success)
            return indexMatch.Groups[1].Value;

        return null;
    }
}

/// <summary>
/// Tipos de constraints de base de datos
/// </summary>
public enum DatabaseConstraintType
{
    /// <summary>
    /// Tipo de constraint no identificado
    /// </summary>
    Unknown,
    
    /// <summary>
    /// Violación de constraint único (UNIQUE, índices únicos)
    /// </summary>
    UniqueConstraint,
    
    /// <summary>
    /// Violación de foreign key (referencia a tabla relacionada)
    /// </summary>
    ForeignKeyConstraint,
    
    /// <summary>
    /// Violación de check constraint (validación de datos)
    /// </summary>
    CheckConstraint
}
