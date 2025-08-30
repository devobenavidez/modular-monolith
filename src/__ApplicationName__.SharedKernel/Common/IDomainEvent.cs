using MediatR;

namespace __RootNamespace__.SharedKernel.Common;

/// <summary>
/// Interfaz base para eventos de dominio que pueden ser manejados por todos los módulos
/// </summary>
public interface IDomainEvent : INotification
{
    DateTime OccurredOn { get; }
}
