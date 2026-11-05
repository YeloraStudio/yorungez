using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Npgsql;
using Yorungez.Application;
using Yorungez.Notebook.Application;
using Yorungez.Notebook.Domain;

namespace Yorungez.Notebook.Infrastructure;

public sealed class NotebookDatabase(DbContextOptions<NotebookDatabase> options) : DbContext(options)
{
    public DbSet<NotebookEntry> Entries => Set<NotebookEntry>();
    public DbSet<EventReminder> Reminders => Set<EventReminder>();
    protected override void OnModelCreating(ModelBuilder model)
    {
        model.HasDefaultSchema("notebook");
        model.Entity<EventReminder>(b =>
        {
            b.ToTable("Reminders"); b.HasKey(e => new { e.UserId, e.Id });
            b.Property(e => e.Revision).IsConcurrencyToken();
            b.Property(e => e.EventId).HasMaxLength(160);
            b.Property(e => e.TargetId).HasMaxLength(128);
            b.Property(e => e.Title).HasMaxLength(200);
            b.Property(e => e.SourceUrl).HasMaxLength(300);
            b.Property(e => e.EventKey).HasMaxLength(200);
            b.Property(e => e.TimeZoneId).HasMaxLength(100);
            b.Property(e => e.Channel).HasMaxLength(16);
            b.Property(e => e.Status).HasMaxLength(16);
            b.HasIndex(e => new { e.UserId, e.EventKey, e.LeadMinutes, e.Channel }).IsUnique()
                .HasFilter("\"Status\" IN ('scheduled', 'sending')");
            b.HasIndex(e => new { e.Status, e.NextAttemptAtUtc });
        });
        model.Entity<NotebookEntry>(b =>
        {
            b.ToTable("Entries"); b.HasKey(e => new { e.UserId, e.Id });
            b.Property(e => e.Id).HasMaxLength(160);
            b.Property(e => e.Kind).HasMaxLength(16);
            b.Property(e => e.Body).HasMaxLength(8000);
            b.Property(e => e.TargetId).HasMaxLength(128);
            b.Property(e => e.TargetName).HasMaxLength(200);
            b.Property(e => e.PlaceName).HasMaxLength(200);
            b.Property(e => e.Revision).IsConcurrencyToken();
            b.HasIndex(e => new { e.UserId, e.UpdatedAtUtc });
        });
    }
}
public sealed class NotebookStore(NotebookDatabase db, TimeProvider clock) : INotebookStore
{
    public async Task<IReadOnlyList<EntryView>> ListAsync(Guid userId, CancellationToken ct) =>
        (await db.Entries.AsNoTracking().Where(e => e.UserId == userId).OrderByDescending(e => e.UpdatedAtUtc).ToListAsync(ct)).Select(View).ToArray();

    public async Task<EntryView> SaveAsync(Guid userId, EntryInput input, CancellationToken ct)
    {
        var entry = await db.Entries.SingleOrDefaultAsync(e => e.UserId == userId && e.Id == input.Id, ct);
        if ((entry?.Revision ?? 0) != input.ExpectedRevision || (entry is not null && entry.Kind != input.Kind))
            throw Conflict();
        var now = clock.GetUtcNow();
        if (entry is null)
        {
            entry = new NotebookEntry { UserId = userId, Id = input.Id, Kind = input.Kind, CreatedAtUtc = now };
            db.Add(entry);
        }
        entry.Revision++; entry.UpdatedAtUtc = now;
        entry.DeletedAtUtc = input.Deleted ? entry.DeletedAtUtc ?? now : null;
        entry.Body = input.Body; entry.TargetId = input.Target?.Id; entry.TargetName = input.Target?.Name;
        entry.InstantUtc = input.InstantUtc;
        entry.ObservedAtUtc = input.ObservedAtUtc;
        entry.ObservationConfirmed = input.ObservationConfirmed;
        entry.Latitude = input.Location?.Latitude; entry.Longitude = input.Location?.Longitude;
        entry.ElevationMeters = input.Location?.ElevationMeters; entry.PlaceName = input.Location?.PlaceName;
        try { await db.SaveChangesAsync(ct); }
        catch (DbUpdateConcurrencyException) { throw Conflict(); }
        catch (DbUpdateException ex) when (ex.InnerException is PostgresException { SqlState: PostgresErrorCodes.UniqueViolation }) { throw Conflict(); }
        return View(entry);
    }
    private static AppFailure Conflict() => new("Notebook.Conflict", FailureKind.Conflict);
    private static EntryView View(NotebookEntry e) => new(e.Id, e.Kind, e.Revision, e.CreatedAtUtc, e.UpdatedAtUtc,
        e.DeletedAtUtc, e.Body, e.TargetId is null ? null : new(e.TargetId, e.TargetName!), e.InstantUtc,
        e.Latitude is null ? null : new(e.Latitude.Value, e.Longitude!.Value, e.ElevationMeters, e.PlaceName), e.ObservedAtUtc, e.ObservationConfirmed);
}
public static class NotebookModule
{
    public static IServiceCollection AddNotebookModule(this IServiceCollection services)
    {
        services.AddDbContext<NotebookDatabase>((provider, options) => options.UseNpgsql(
            provider.GetRequiredService<IConfiguration>().GetConnectionString("Identity"),
            o => o.MigrationsHistoryTable("__EFMigrationsHistory", "notebook")));
        services.AddScoped<IReminderStore, ReminderStore>();
        services.AddScoped<ReminderDispatcher>();
        services.AddHostedService<ReminderWorker>();
        return services.AddScoped<INotebookStore, NotebookStore>();
    }
}
public sealed class DesignTimeNotebookFactory : IDesignTimeDbContextFactory<NotebookDatabase>
{
    public NotebookDatabase CreateDbContext(string[] args) => new(new DbContextOptionsBuilder<NotebookDatabase>()
        .UseNpgsql("Host=localhost;Database=yorungez_design", o => o.MigrationsHistoryTable("__EFMigrationsHistory", "notebook")).Options);
}
