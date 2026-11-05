using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Npgsql;
using Yorungez.Application;
using Yorungez.Identity.Application;
using Yorungez.Identity.Infrastructure.Persistence;

namespace Yorungez.Identity.Infrastructure;

public sealed class ExplorationPreferenceStore(IdentityStore store) : IExplorationPreferenceStore
{
    private static readonly string[] Defaults = ["stars", "solar", "deepSky", "horizon", "constellations", "figures", "cosmic"];
    public async Task<ExplorationPreferences> ReadAsync(Guid userId, CancellationToken ct)
    {
        var row = await store.ExplorationPreferences.AsNoTracking().SingleOrDefaultAsync(p => p.UserId == userId, ct);
        return row is null ? new(true, Defaults, 0) : View(row);
    }
    public async Task<ExplorationPreferences> SaveAsync(SaveExplorationPreferences command, CancellationToken ct)
    {
        var row = await store.ExplorationPreferences.SingleOrDefaultAsync(p => p.UserId == command.UserId, ct);
        if ((row?.Revision ?? 0) != command.ExpectedRevision) throw Conflict();
        if (row is null)
        {
            row = new() { UserId = command.UserId };
            store.ExplorationPreferences.Add(row);
        }
        row.MusicEnabled = command.MusicEnabled;
        row.SkyLayersJson = JsonSerializer.Serialize(command.SkyLayers);
        row.Revision++;
        try { await store.SaveChangesAsync(ct); }
        catch (DbUpdateConcurrencyException) { throw Conflict(); }
        catch (DbUpdateException ex) when (ex.InnerException is PostgresException { SqlState: "23505" }) { throw Conflict(); }
        return View(row);
    }
    private static ExplorationPreferences View(AccountExplorationPreferences row) =>
        new(row.MusicEnabled, JsonSerializer.Deserialize<string[]>(row.SkyLayersJson)!, row.Revision);
    private static AppFailure Conflict() => new("Identity.PreferencesConflict", FailureKind.Conflict);
}
