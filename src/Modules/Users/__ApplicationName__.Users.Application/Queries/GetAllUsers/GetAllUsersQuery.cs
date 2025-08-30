using MediatR;
using __RootNamespace__.Users.Application.DTOs;

namespace __RootNamespace__.Users.Application.Queries.GetAllUsers;

public record GetAllUsersQuery : IRequest<IEnumerable<UserDto>>;
