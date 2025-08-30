using MediatR;
using __RootNamespace__.SharedKernel.Interfaces;
using __RootNamespace__.Users.Domain.Entities;
using __RootNamespace__.Users.Domain.Abstractions;

namespace __RootNamespace__.Users.Application.Commands.CreateUser;

public class CreateUserCommandHandler : IRequestHandler<CreateUserCommand, Guid>
{
    private readonly IUserRepository _userRepository;
    private readonly IUnitOfWork _unitOfWork;

    public CreateUserCommandHandler(IUserRepository userRepository, IUnitOfWork unitOfWork)
    {
        _userRepository = userRepository;
        _unitOfWork = unitOfWork;
    }

    public async Task<Guid> Handle(CreateUserCommand request, CancellationToken cancellationToken)
    {
        // Check if user with email already exists
        var existingUser = await _userRepository.GetByEmailAsync(request.Email, cancellationToken);
        if (existingUser != null)
        {
            throw new InvalidOperationException($"User with email '{request.Email}' already exists.");
        }        // Create new user
        var user = User.Create(
            request.FirstName,
            request.LastName,
            request.Email);

        // Add to repository
        await _userRepository.AddAsync(user, cancellationToken);

        // Save changes
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return user.Id;
    }
}
