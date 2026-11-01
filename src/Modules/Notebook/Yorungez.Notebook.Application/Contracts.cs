using MediatR;
using Yorungez.Application;

namespace Yorungez.Notebook.Application;

public sealed record NotebookTarget(string Id, string Name);
public sealed record NotebookLocation(double Latitude, double Longitude, double? ElevationMeters, string? PlaceName);
public sealed record EntryInput(string Id, string Kind, long ExpectedRevision, string? Body,
    NotebookTarget? Target, DateTimeOffset? InstantUtc, NotebookLocation? Location, bool Deleted = false,
    DateTimeOffset? ObservedAtUtc = null, bool ObservationConfirmed = false);
public sealed record EntryView(string Id, string Kind, long Revision, DateTimeOffset CreatedAtUtc,
    DateTimeOffset UpdatedAtUtc, DateTimeOffset? DeletedAtUtc, string? Body, NotebookTarget? Target,
    DateTimeOffset? InstantUtc, NotebookLocation? Location, DateTimeOffset? ObservedAtUtc, bool ObservationConfirmed);
public sealed record ListNotebookQuery(Guid UserId) : IQuery<IReadOnlyList<EntryView>>;
public sealed record SaveNotebookCommand(Guid UserId, EntryInput Entry) : ICommand<EntryView>;
public interface INotebookStore
{
    Task<IReadOnlyList<EntryView>> ListAsync(Guid userId, CancellationToken ct);
    Task<EntryView> SaveAsync(Guid userId, EntryInput entry, CancellationToken ct);
}
public sealed class ListNotebookHandler(INotebookStore store) : IRequestHandler<ListNotebookQuery, IReadOnlyList<EntryView>>
{
    public Task<IReadOnlyList<EntryView>> Handle(ListNotebookQuery request, CancellationToken ct) => store.ListAsync(request.UserId, ct);
}
public sealed class SaveNotebookHandler(INotebookStore store, TimeProvider clock) : IRequestHandler<SaveNotebookCommand, EntryView>
{
    public Task<EntryView> Handle(SaveNotebookCommand request, CancellationToken ct)
    {
        var e = request.Entry;
        if (request.UserId == Guid.Empty || e.ExpectedRevision < 0 || e.ExpectedRevision == long.MaxValue
            || string.IsNullOrWhiteSpace(e.Id) || e.Id.Length > 160 || e.Kind is not ("note" or "favorite" or "observation" or "place")
            || (e.Kind != "favorite" && !Guid.TryParse(e.Id, out _))
            || e.Body?.Length > 8000
            || (e.Kind is "note" or "observation" && string.IsNullOrWhiteSpace(e.Body))
            || (e.Kind == "favorite" && (e.Target is null || e.Id != $"favorite:{e.Target.Id}" || e.Body is not null))
            || (e.Kind == "observation" && (!e.ObservationConfirmed || e.InstantUtc is not null))
            || (e.Kind != "observation" && (e.ObservationConfirmed || e.ObservedAtUtc is not null))
            || (e.Kind == "place" && (e.Location is null || e.Target is not null || e.InstantUtc is not null))
            || (e.Target is { } t && (string.IsNullOrWhiteSpace(t.Id) || t.Id.Length > 128 || string.IsNullOrWhiteSpace(t.Name) || t.Name.Length > 200))
            || (e.Location is { } l && (!double.IsFinite(l.Latitude) || Math.Abs(l.Latitude) > 90
                || !double.IsFinite(l.Longitude) || Math.Abs(l.Longitude) > 180
                || (l.ElevationMeters is { } h && (!double.IsFinite(h) || h is < -500 or > 10000))
                || l.PlaceName?.Length > 200)))
            throw new AppFailure("Notebook.InvalidInput", FailureKind.Validation);
        if (e.ObservedAtUtc > clock.GetUtcNow())
            throw new AppFailure("Notebook.FutureObservation", FailureKind.Validation);
        return store.SaveAsync(request.UserId, e with { Body = e.Body?.Trim(), InstantUtc = e.InstantUtc?.ToUniversalTime(),
            ObservedAtUtc = e.ObservedAtUtc?.ToUniversalTime(),
            Location = e.Location is null ? null : e.Location with { PlaceName = string.IsNullOrWhiteSpace(e.Location.PlaceName) ? null : e.Location.PlaceName.Trim() } }, ct);
    }
}
