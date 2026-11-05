using MediatR;
using Yorungez.Application;

namespace Yorungez.Identity.Application;

public sealed record ExplorationPreferences(bool MusicEnabled, IReadOnlyList<string> SkyLayers, long Revision);
public sealed record GetExplorationPreferences(Guid UserId) : IQuery<ExplorationPreferences>;
public sealed record SaveExplorationPreferences(Guid UserId, bool MusicEnabled, string[]? SkyLayers, long ExpectedRevision) : ICommand<ExplorationPreferences>;
public interface IExplorationPreferenceStore
{
    Task<ExplorationPreferences> ReadAsync(Guid userId, CancellationToken ct);
    Task<ExplorationPreferences> SaveAsync(SaveExplorationPreferences command, CancellationToken ct);
}
public sealed class GetExplorationPreferencesHandler(IExplorationPreferenceStore store) : IRequestHandler<GetExplorationPreferences, ExplorationPreferences>
{
    public Task<ExplorationPreferences> Handle(GetExplorationPreferences request, CancellationToken ct) => store.ReadAsync(request.UserId, ct);
}
public sealed class SaveExplorationPreferencesHandler(IExplorationPreferenceStore store) : IRequestHandler<SaveExplorationPreferences, ExplorationPreferences>
{
    public static readonly string[] AllowedLayers = ["stars", "solar", "deepSky", "constellations", "figures", "cosmic", "grid", "horizon", "atmosphere"];
    public async Task<ExplorationPreferences> Handle(SaveExplorationPreferences request, CancellationToken ct)
    {
        if (request.SkyLayers is null || request.SkyLayers.Length > AllowedLayers.Length || request.ExpectedRevision is < 0 or long.MaxValue
            || request.SkyLayers.Distinct(StringComparer.Ordinal).Count() != request.SkyLayers.Length
            || request.SkyLayers.Any(layer => !AllowedLayers.Contains(layer, StringComparer.Ordinal)))
            throw new AppFailure("Common.InvalidInput", FailureKind.Validation);
        return await store.SaveAsync(request, ct);
    }
}
