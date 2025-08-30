using __RootNamespace__.SharedKernel.Common;

namespace __RootNamespace__.Users.Domain.Events;

public record UserLoggedInEvent(Guid UserId, string Email, DateTime LoginTime) : IDomainEvent
{
    public DateTime OccurredOn { get; } = DateTime.UtcNow;
}

public record UserActivatedEvent(Guid UserId, string Email) : IDomainEvent
{
    public DateTime OccurredOn { get; } = DateTime.UtcNow;
}

public record UserDeactivatedEvent(Guid UserId, string Email) : IDomainEvent
{
    public DateTime OccurredOn { get; } = DateTime.UtcNow;
}

public record UserCreatedEvent(Guid UserId, string Email, string FullName) : IDomainEvent
{
    public DateTime OccurredOn { get; } = DateTime.UtcNow;
}
