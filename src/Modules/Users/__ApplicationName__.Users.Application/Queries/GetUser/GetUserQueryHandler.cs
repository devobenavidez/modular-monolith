using MediatR;
using __RootNamespace__.Users.Domain.Abstractions;
using __RootNamespace__.Users.Application.DTOs;

namespace __RootNamespace__.Users.Application.Queries.GetUser;

public class GetUserQueryHandler : IRequestHandler<GetUserQuery, UserDto?>
{
    private readonly IUserReadRepository _userReadRepository;

    public GetUserQueryHandler(IUserReadRepository userReadRepository)
    {
        _userReadRepository = userReadRepository;
    }

    public async Task<UserDto?> Handle(GetUserQuery request, CancellationToken cancellationToken)
    {
        var result = await _userReadRepository.GetByIdAsync(request.Id, cancellationToken);
        return result as UserDto;
    }
}
