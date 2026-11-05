using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Npgsql;
using Yorungez.Application;
using Yorungez.Notebook.Application;
using Yorungez.Notebook.Domain;

namespace Yorungez.Notebook.Infrastructure;

public sealed class ReminderStore(NotebookDatabase db, TimeProvider clock) : IReminderStore
{
    public async Task<IReadOnlyList<ReminderView>> ListAsync(Guid userId, CancellationToken ct) =>
        (await db.Reminders.AsNoTracking().Where(r => r.UserId == userId)
            .OrderBy(r => r.Status == "scheduled" || r.Status == "sending" ? 0 : 1).ThenByDescending(r => r.InstantUtc).Take(500).ToListAsync(ct)).Select(View).ToArray();

    public async Task<ReminderView> SaveAsync(Guid userId, ReminderInput input, ReminderFact? fact, CancellationToken ct)
    {
        // Serialize per-account capacity/duplicate checks across API instances without touching Identity tables.
        await using var transaction = await db.Database.BeginTransactionAsync(ct);
        await db.Database.ExecuteSqlInterpolatedAsync($"SELECT pg_advisory_xact_lock(hashtextextended({userId.ToString()}, 55))", ct);
        var row = await db.Reminders.SingleOrDefaultAsync(r => r.UserId == userId && r.Id == input.Id, ct);
        if ((row?.Revision ?? 0) != input.ExpectedRevision || (input.Cancelled && row is null)) throw Conflict();
        if (row?.Status == "sending") throw Conflict(); // A claimed delivery cannot be recalled reliably.
        if (input.Cancelled)
        {
            row!.Status = "cancelled"; row.Revision++; row.LeaseId = null; row.LeaseUntilUtc = null;
        }
        else
        {
            if (row?.Status == "sent") throw Conflict();
            if (await db.Reminders.CountAsync(r => r.UserId == userId && (r.Status == "scheduled" || r.Status == "sending") && r.Id != input.Id, ct) >= 100)
                throw new AppFailure("Reminders.Limit", FailureKind.Validation);
            var now = clock.GetUtcNow();
            row ??= new EventReminder { UserId = userId, Id = input.Id, CreatedAtUtc = now,
                TargetId = "", Title = "", SourceUrl = "", EventKey = "", TimeZoneId = "UTC", Channel = "email", Status = "scheduled" };
            if (row.Revision == 0) db.Add(row);
            row.Revision++; row.EventId = fact!.EventId; row.TargetId = fact.TargetId;
            row.Title = fact.Title; row.SourceUrl = fact.SourceUrl; row.InstantUtc = fact.InstantUtc.ToUniversalTime();
            row.EventKey = fact.EventId ?? $"observing:{fact.TargetId}:{fact.InstantUtc.ToUnixTimeSeconds()}";
            row.TimeZoneId = input.TimeZoneId; row.LeadMinutes = input.LeadMinutes;
            row.DueAtUtc = row.InstantUtc.AddMinutes(-input.LeadMinutes); row.NextAttemptAtUtc = row.DueAtUtc;
            row.ExpiresAtUtc = row.InstantUtc.AddMinutes(input.LeadMinutes == 0 ? 5 : 0);
            row.Status = "scheduled"; row.Attempts = 0; row.LeaseId = null; row.LeaseUntilUtc = null;
        }
        try { await db.SaveChangesAsync(ct); await transaction.CommitAsync(ct); }
        catch (DbUpdateConcurrencyException) { throw Conflict(); }
        catch (DbUpdateException ex) when (ex.InnerException is PostgresException { SqlState: PostgresErrorCodes.UniqueViolation }) { throw Conflict(); }
        return View(row);
    }
    private static AppFailure Conflict() => new("Reminders.Conflict", FailureKind.Conflict);
    public static ReminderView View(EventReminder r) => new(r.Id, r.Revision, r.EventId, r.TargetId, r.Title,
        r.InstantUtc, r.TimeZoneId, r.LeadMinutes, r.Channel, r.Status, r.DueAtUtc, r.SentAtUtc);
}

public sealed class ReminderDispatcher(NotebookDatabase db, IEnumerable<IReminderChannel> channels,
    TimeProvider clock, ILogger<ReminderDispatcher> logger)
{
    public async Task<int> DispatchOnceAsync(CancellationToken ct)
    {
        var now = clock.GetUtcNow();
        // Terminal outcomes are retained for the account UI; never send stale event mail after downtime.
        await db.Reminders.Where(r => (r.Status == "scheduled" || r.Status == "sending") && r.ExpiresAtUtc <= now
            && (r.LeaseUntilUtc == null || r.LeaseUntilUtc < now)).ExecuteUpdateAsync(s => s
                .SetProperty(r => r.Status, "expired").SetProperty(r => r.Revision, r => r.Revision + 1), ct);
        var ids = await db.Reminders.AsNoTracking().Where(r => (r.Status == "scheduled" || r.Status == "sending")
            && r.NextAttemptAtUtc <= now && r.ExpiresAtUtc > now && r.Attempts < 8
            && (r.LeaseUntilUtc == null || r.LeaseUntilUtc < now))
            .OrderBy(r => r.NextAttemptAtUtc).Select(r => new { r.UserId, r.Id }).Take(20).ToArrayAsync(ct);
        var sent = 0;
        foreach (var id in ids)
        {
            var lease = Guid.NewGuid();
            var claimedAt = clock.GetUtcNow();
            var claimed = await db.Reminders.Where(r => r.UserId == id.UserId && r.Id == id.Id
                && (r.Status == "scheduled" || r.Status == "sending") && r.NextAttemptAtUtc <= claimedAt
                && r.ExpiresAtUtc > claimedAt && r.Attempts < 8 && (r.LeaseUntilUtc == null || r.LeaseUntilUtc < claimedAt))
                .ExecuteUpdateAsync(s => s.SetProperty(r => r.Status, "sending").SetProperty(r => r.LeaseId, lease)
                    .SetProperty(r => r.LeaseUntilUtc, claimedAt.AddMinutes(2)).SetProperty(r => r.Attempts, r => r.Attempts + 1)
                    .SetProperty(r => r.Revision, r => r.Revision + 1), ct);
            if (claimed == 0) continue;
            var row = await db.Reminders.AsNoTracking().SingleAsync(r => r.UserId == id.UserId && r.Id == id.Id, ct);
            var status = "scheduled";
            DateTimeOffset? accepted = null;
            try
            {
                var channel = channels.SingleOrDefault(c => c.Channel == row.Channel)
                    ?? throw new InvalidOperationException("Reminder channel unavailable.");
                // Bound I/O well below the lease duration; do not overlap a live SMTP attempt.
                using var timeout = CancellationTokenSource.CreateLinkedTokenSource(ct);
                timeout.CancelAfter(TimeSpan.FromSeconds(30));
                var delivered = await channel.DeliverAsync(row.UserId, new(row.Id, row.Title, row.TargetId,
                    row.InstantUtc, row.TimeZoneId, row.SourceUrl), timeout.Token);
                status = delivered ? "sent" : "suppressed";
                if (delivered) { accepted = clock.GetUtcNow(); sent++; }
            }
            catch (OperationCanceledException) when (ct.IsCancellationRequested) { throw; }
            catch (Exception ex)
            {
                status = row.Attempts >= 8 ? "failed" : "scheduled";
                logger.LogWarning("Reminder delivery failed ({ExceptionType}); recipient, event and payload omitted.", ex.GetType().Name);
            }
            var next = clock.GetUtcNow().AddSeconds(Math.Min(1800, 15 * Math.Pow(2, row.Attempts)));
            await db.Reminders.Where(r => r.UserId == id.UserId && r.Id == id.Id && r.LeaseId == lease)
                .ExecuteUpdateAsync(s => s.SetProperty(r => r.Status, status).SetProperty(r => r.SentAtUtc, accepted)
                    .SetProperty(r => r.NextAttemptAtUtc, next).SetProperty(r => r.LeaseId, (Guid?)null)
                    .SetProperty(r => r.LeaseUntilUtc, (DateTimeOffset?)null).SetProperty(r => r.Revision, r => r.Revision + 1), ct);
        }
        return sent;
    }
}

public sealed class ReminderWorker(IServiceScopeFactory scopes, IHostEnvironment environment, ILogger<ReminderWorker> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        if (environment.IsEnvironment("Testing")) return;
        using var timer = new PeriodicTimer(TimeSpan.FromSeconds(15));
        while (await timer.WaitForNextTickAsync(stoppingToken))
        {
            try
            {
                await using var scope = scopes.CreateAsyncScope();
                await scope.ServiceProvider.GetRequiredService<ReminderDispatcher>().DispatchOnceAsync(stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested) { break; }
            catch (Exception ex) { logger.LogWarning("Reminder worker unavailable ({ExceptionType}).", ex.GetType().Name); }
        }
    }
}
