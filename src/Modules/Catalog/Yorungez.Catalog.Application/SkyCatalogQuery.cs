using MediatR;
using Yorungez.Application;
using Yorungez.Catalog.Domain;

namespace Yorungez.Catalog.Application;

public interface ISkyCatalogRepository { SkyCatalogSnapshot Read(); SkyOverlaySnapshot ReadOverlays(); }
public sealed record GetSkyCatalogQuery : IQuery<SkyCatalogSnapshot>;
public sealed class GetSkyCatalogHandler(ISkyCatalogRepository repository)
    : IRequestHandler<GetSkyCatalogQuery, SkyCatalogSnapshot>
{
    public Task<SkyCatalogSnapshot> Handle(GetSkyCatalogQuery request, CancellationToken ct)
    {
        ct.ThrowIfCancellationRequested();
        return Task.FromResult(repository.Read());
    }
}
public sealed record GetSkyOverlaysQuery : IQuery<SkyOverlaySnapshot>;
public sealed class GetSkyOverlaysHandler(ISkyCatalogRepository repository)
    : IRequestHandler<GetSkyOverlaysQuery, SkyOverlaySnapshot>
{
    public Task<SkyOverlaySnapshot> Handle(GetSkyOverlaysQuery request, CancellationToken ct)
    {
        ct.ThrowIfCancellationRequested();
        return Task.FromResult(repository.ReadOverlays());
    }
}
