namespace __RootNamespace__.Users.Infrastructure.Persistence.Queries;

/// <summary>
/// Consultas SQL para operaciones de lectura de usuarios usando Dapper
/// </summary>
public static class UserQueries
{
    public const string GetById = @"
        SELECT 
            Id,
            FirstName,
            LastName,
            Email,
            PhoneNumber,
            IsActive,
            LastLoginAt,
            CreatedAt,
            UpdatedAt,
            CreatedBy,
            UpdatedBy
        FROM users.Users 
        WHERE Id = @Id AND IsDeleted = false";

    public const string GetByEmail = @"
        SELECT 
            Id,
            FirstName,
            LastName,
            Email,
            PhoneNumber,
            IsActive,
            LastLoginAt,
            CreatedAt,
            UpdatedAt,
            CreatedBy,
            UpdatedBy
        FROM users.Users 
        WHERE Email = @Email AND IsDeleted = false";

    public const string GetAll = @"
        SELECT 
            Id,
            FirstName,
            LastName,
            Email,
            PhoneNumber,
            IsActive,
            LastLoginAt,
            CreatedAt,
            UpdatedAt,
            CreatedBy,
            UpdatedBy
        FROM users.Users 
        WHERE IsDeleted = false
        ORDER BY FirstName, LastName";

    public const string GetActiveUsers = @"
        SELECT 
            Id,
            FirstName,
            LastName,
            Email,
            PhoneNumber,
            IsActive,
            LastLoginAt,
            CreatedAt,
            UpdatedAt,
            CreatedBy,
            UpdatedBy
        FROM users.Users 
        WHERE IsActive = true AND IsDeleted = false
        ORDER BY FirstName, LastName";

    public const string GetUsersByFilter = @"
        SELECT 
            Id,
            FirstName,
            LastName,
            Email,
            PhoneNumber,
            IsActive,
            LastLoginAt,
            CreatedAt,
            UpdatedAt,
            CreatedBy,
            UpdatedBy
        FROM users.Users 
        WHERE IsDeleted = false
        AND (@SearchTerm IS NULL OR 
             FirstName ILIKE @SearchTerm OR 
             LastName ILIKE @SearchTerm OR 
             Email ILIKE @SearchTerm)
        AND (@IsActive IS NULL OR IsActive = @IsActive)
        AND (@CreatedFrom IS NULL OR CreatedAt >= @CreatedFrom)
        AND (@CreatedTo IS NULL OR CreatedAt <= @CreatedTo)
        AND (@LastLoginFrom IS NULL OR LastLoginAt >= @LastLoginFrom)
        AND (@LastLoginTo IS NULL OR LastLoginAt <= @LastLoginTo)
        ORDER BY 
            CASE 
                WHEN @SortBy = 'FirstName' AND @SortDescending = false THEN FirstName
                WHEN @SortBy = 'FirstName' AND @SortDescending = true THEN FirstName
                WHEN @SortBy = 'LastName' AND @SortDescending = false THEN LastName
                WHEN @SortBy = 'LastName' AND @SortDescending = true THEN LastName
                WHEN @SortBy = 'Email' AND @SortDescending = false THEN Email
                WHEN @SortBy = 'Email' AND @SortDescending = true THEN Email
                WHEN @SortBy = 'CreatedAt' AND @SortDescending = false THEN CreatedAt::text
                WHEN @SortBy = 'CreatedAt' AND @SortDescending = true THEN CreatedAt::text
                ELSE FirstName
            END
        LIMIT @PageSize OFFSET @Offset";

    public const string ExistsByEmail = @"
        SELECT COUNT(1) 
        FROM users.Users 
        WHERE Email = @Email AND IsDeleted = false";

    public const string Count = @"
        SELECT COUNT(1) 
        FROM users.Users 
        WHERE IsDeleted = false";

    public const string CountActive = @"
        SELECT COUNT(1) 
        FROM users.Users 
        WHERE IsActive = true AND IsDeleted = false";
}
