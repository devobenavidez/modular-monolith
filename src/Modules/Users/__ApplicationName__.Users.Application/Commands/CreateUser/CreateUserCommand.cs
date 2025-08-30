using MediatR;

namespace __RootNamespace__.Users.Application.Commands.CreateUser;

public record CreateUserCommand(
    string FirstName,
    string LastName,
    string Email
) : IRequest<Guid>;