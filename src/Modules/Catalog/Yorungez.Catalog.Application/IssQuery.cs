using MediatR;
using Yorungez.Application;
using Yorungez.Catalog.Domain;

namespace Yorungez.Catalog.Application;

public interface IIssElementsRepository { Task<IssElements?> ReadAsync(CancellationToken ct); }
public sealed record GetIssElementsQuery : IQuery<IssElements?>;
public sealed class GetIssElementsHandler(IIssElementsRepository repository) : IRequestHandler<GetIssElementsQuery, IssElements?>
{
    public Task<IssElements?> Handle(GetIssElementsQuery request, CancellationToken ct) => repository.ReadAsync(ct);
}
