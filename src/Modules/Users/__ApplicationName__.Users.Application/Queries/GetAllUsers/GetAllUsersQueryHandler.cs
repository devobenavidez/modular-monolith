using MediatR;
using __RootNamespace__.Users.Domain.Abstractions;
using __RootNamespace__.Users.Application.DTOs;

namespace __RootNamespace__.Users.Application.Queries.GetAllUsers;

public class GetAllUsersQueryHandler : IRequestHandler<GetAllUsersQuery, IEnumerable<UserDto>>
{
    private readonly IUserReadRepository _userReadRepository;

    public GetAllUsersQueryHandler(IUserReadRepository userReadRepository)
    {
        _userReadRepository = userReadRepository;
    }

    public async Task<IEnumerable<UserDto>> Handle(GetAllUsersQuery request, CancellationToken cancellationToken)
    {
        var result = await _userReadRepository.GetAllAsync(cancellationToken);
        return result.Cast<UserDto>();
    }
}
