using MediatR;
using __RootNamespace__.Users.Application.DTOs;

namespace __RootNamespace__.Users.Application.Queries.GetUser;

public record GetUserQuery(Guid Id) : IRequest<UserDto?>;
