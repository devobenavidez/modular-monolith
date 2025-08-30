namespace __RootNamespace__.Users.Application.DTOs;

/// <summary>
/// DTO para filtros de consulta de usuarios
/// </summary>
public class UserFilterDto
{
    public string? SearchTerm { get; set; }
    public bool? IsActive { get; set; }
    public DateTime? CreatedFrom { get; set; }
    public DateTime? CreatedTo { get; set; }
    public DateTime? LastLoginFrom { get; set; }
    public DateTime? LastLoginTo { get; set; }
    public int? Page { get; set; } = 1;
    public int? PageSize { get; set; } = 10;
    public string? SortBy { get; set; } = "FirstName";
    public bool SortDescending { get; set; } = false;
}

