using MediatR;
using __RootNamespace__.Users.Application.DTOs;

namespace __RootNamespace__.Users.Application.Queries.GetUsersByFilter;

public record GetUsersByFilterQuery(UserFilterDto Filter) : IRequest<IEnumerable<UserDto>>;

