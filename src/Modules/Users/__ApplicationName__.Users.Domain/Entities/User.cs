using __RootNamespace__.SharedKernel.Common;
using __RootNamespace__.Users.Domain.Events;

namespace __RootNamespace__.Users.Domain.Entities;

public class User : BaseEntity
{
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime? LastLoginAt { get; set; }

    public string FullName => $"{FirstName} {LastName}";

    public static User Create(string firstName, string lastName, string email, string? phoneNumber = null)
    {
        var user = new User
        {
            Id = Guid.NewGuid(),
            FirstName = firstName,
            LastName = lastName,
            Email = email,
            PhoneNumber = phoneNumber,
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };

        user.AddDomainEvent(new UserCreatedEvent(user.Id, user.Email, user.FullName));
        return user;
    }

    public void UpdateLastLogin()
    {
        LastLoginAt = DateTime.UtcNow;
        AddDomainEvent(new UserLoggedInEvent(Id, Email, LastLoginAt.Value));
    }

    public void Activate()
    {
        IsActive = true;
        AddDomainEvent(new UserActivatedEvent(Id, Email));
    }

    public void Deactivate()
    {
        IsActive = false;
        AddDomainEvent(new UserDeactivatedEvent(Id, Email));
    }
}
