using Microsoft.AspNetCore.Mvc;
using MediatR;
using __RootNamespace__.Users.Application.Commands.CreateUser;
using __RootNamespace__.Users.Application.Queries.GetUser;
using __RootNamespace__.Users.Application.Queries.GetAllUsers;
using __RootNamespace__.Users.Application.Queries.GetUsersByFilter;
using __RootNamespace__.Users.Application.DTOs;

namespace __RootNamespace__.Users.Api.Controllers;

[ApiController]
[Route("api/v{version:apiVersion}/users")]
public class UsersController : ControllerBase
{
    private readonly IMediator _mediator;

    public UsersController(IMediator mediator)
    {
        _mediator = mediator;
    }

    /// <summary>
    /// Create a new user
    /// </summary>
    /// <param name="command">User data to create</param>
    /// <param name="cancellationToken">Cancellation token</param>
    /// <returns>Created user ID</returns>
    [HttpPost]
    [ProducesResponseType(typeof(Guid), 201)]
    [ProducesResponseType(400)]
    public async Task<ActionResult<Guid>> CreateUser(
        [FromBody] CreateUserCommand command,
        CancellationToken cancellationToken)
    {
        try
        {
            var userId = await _mediator.Send(command, cancellationToken);
            return CreatedAtAction(nameof(GetUser), new { id = userId }, userId);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Get a user by ID
    /// </summary>
    /// <param name="id">User ID</param>
    /// <param name="cancellationToken">Cancellation token</param>
    /// <returns>User data</returns>
    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(__RootNamespace__.Users.Application.DTOs.UserDto), 200)]
    [ProducesResponseType(404)]
    public async Task<ActionResult<__RootNamespace__.Users.Application.DTOs.UserDto>> GetUser(
        [FromRoute] Guid id,
        CancellationToken cancellationToken)
    {
        var user = await _mediator.Send(new GetUserQuery(id), cancellationToken);
        
        if (user == null)
            return NotFound(new { message = $"User with ID {id} not found" });

        return Ok(user);
    }

    /// <summary>
    /// Get all users
    /// </summary>
    /// <param name="cancellationToken">Cancellation token</param>
    /// <returns>List of users</returns>
    [HttpGet]
    [ProducesResponseType(typeof(IEnumerable<__RootNamespace__.Users.Application.DTOs.UserDto>), 200)]
    public async Task<ActionResult<IEnumerable<__RootNamespace__.Users.Application.DTOs.UserDto>>> GetAllUsers(CancellationToken cancellationToken)
    {
        var users = await _mediator.Send(new GetAllUsersQuery(), cancellationToken);
        return Ok(users);
    }

    /// <summary>
    /// Get users by filter
    /// </summary>
    /// <param name="filter">Filter criteria</param>
    /// <param name="cancellationToken">Cancellation token</param>
    /// <returns>Filtered list of users</returns>
    [HttpGet("filter")]
    [ProducesResponseType(typeof(IEnumerable<__RootNamespace__.Users.Application.DTOs.UserDto>), 200)]
    public async Task<ActionResult<IEnumerable<__RootNamespace__.Users.Application.DTOs.UserDto>>> GetUsersByFilter(
        [FromQuery] UserFilterDto filter,
        CancellationToken cancellationToken)
    {
        var users = await _mediator.Send(new GetUsersByFilterQuery(filter), cancellationToken);
        return Ok(users);
    }

    /// <summary>
    /// Users module health check
    /// </summary>
    /// <returns>Module status</returns>
    [HttpGet("health")]
    [ProducesResponseType(200)]
    public ActionResult GetHealth()
    {
        return Ok(new { 
            module = "Users", 
            status = "Healthy", 
            timestamp = DateTime.UtcNow 
        });
    }
}
