using Xunit;
using Moq;
using FluentAssertions;
using __RootNamespace__.Users.Application.Commands.CreateUser;
using __RootNamespace__.Users.Domain.Entities;
using __RootNamespace__.Users.Domain.Abstractions;
using __RootNamespace__.SharedKernel.Interfaces;

namespace __RootNamespace__.Users.Application.Tests.Commands.CreateUser;

public class CreateUserCommandHandlerTests
{
    private readonly Mock<IUserRepository> _userRepositoryMock;
    private readonly Mock<IUnitOfWork> _unitOfWorkMock;
    private readonly CreateUserCommandHandler _handler;

    public CreateUserCommandHandlerTests()
    {
        _userRepositoryMock = new Mock<IUserRepository>();
        _unitOfWorkMock = new Mock<IUnitOfWork>();
        _handler = new CreateUserCommandHandler(_userRepositoryMock.Object, _unitOfWorkMock.Object);
    }

    [Fact]
    public async Task Handle_WithValidCommand_ShouldCreateUser()
    {
        // Arrange
        var command = new CreateUserCommand("John", "Doe", "john.doe@example.com");
        _userRepositoryMock
            .Setup(x => x.GetByEmailAsync(command.Email, It.IsAny<CancellationToken>()))
            .ReturnsAsync((User?)null);

        // Act
        var result = await _handler.Handle(command, CancellationToken.None);

        // Assert
        result.Should().NotBeEmpty();
        _userRepositoryMock.Verify(x => x.AddAsync(It.IsAny<User>(), It.IsAny<CancellationToken>()), Times.Once);
        _unitOfWorkMock.Verify(x => x.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task Handle_WithExistingEmail_ShouldThrowException()
    {
        // Arrange
        var command = new CreateUserCommand("John", "Doe", "john.doe@example.com");
        var existingUser = User.Create("Jane", "Doe", "john.doe@example.com");
        
        _userRepositoryMock
            .Setup(x => x.GetByEmailAsync(command.Email, It.IsAny<CancellationToken>()))
            .ReturnsAsync(existingUser);

        // Act & Assert
        var exception = await Assert.ThrowsAsync<InvalidOperationException>(
            () => _handler.Handle(command, CancellationToken.None));
        
        exception.Message.Should().Contain("already exists");
        _userRepositoryMock.Verify(x => x.AddAsync(It.IsAny<User>(), It.IsAny<CancellationToken>()), Times.Never);
        _unitOfWorkMock.Verify(x => x.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Never);
    }
}
