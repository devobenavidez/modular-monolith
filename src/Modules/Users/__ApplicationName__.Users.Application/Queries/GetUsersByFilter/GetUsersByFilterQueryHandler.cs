using MediatR;
using __RootNamespace__.Users.Domain.Abstractions;
using __RootNamespace__.Users.Application.DTOs;

namespace __RootNamespace__.Users.Application.Queries.GetUsersByFilter;

public class GetUsersByFilterQueryHandler : IRequestHandler<GetUsersByFilterQuery, IEnumerable<UserDto>>
{
    private readonly IUserReadRepository _userReadRepository;

    public GetUsersByFilterQueryHandler(IUserReadRepository userReadRepository)
    {
        _userReadRepository = userReadRepository;
    }

    public async Task<IEnumerable<UserDto>> Handle(GetUsersByFilterQuery request, CancellationToken cancellationToken)
    {
        var result = await _userReadRepository.GetUsersByFilterAsync(request.Filter, cancellationToken);
        return result.Cast<UserDto>();
    }
}
