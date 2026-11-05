using MediatR;
using Yorungez.Application;

namespace Yorungez.Notebook.Application;

public sealed record ReminderInput(Guid Id, long ExpectedRevision, string? EventId, string? TargetId,
    DateTimeOffset? InstantUtc, string TimeZoneId, int LeadMinutes, bool Cancelled = false);
public sealed record ReminderView(Guid Id, long Revision, string? EventId, string TargetId, string Title,
    DateTimeOffset InstantUtc, string TimeZoneId, int LeadMinutes, string Channel, string Status,
    DateTimeOffset DueAtUtc, DateTimeOffset? SentAtUtc);
public sealed record ReminderFact(string? EventId, string TargetId, string Title, DateTimeOffset InstantUtc, string SourceUrl);
public sealed record ReminderDeliveryContent(Guid ReminderId, string Title, string TargetId,
    DateTimeOffset InstantUtc, string TimeZoneId, string SourceUrl);
public sealed record ListRemindersQuery(Guid UserId) : IQuery<IReadOnlyList<ReminderView>>;
public sealed record SaveReminderCommand(Guid UserId, ReminderInput Input) : ICommand<ReminderView>;
public interface IReminderFacts
{
    ReminderFact Resolve(string? eventId, string? targetId, DateTimeOffset? instantUtc);
}
public interface IReminderStore
{
    Task<IReadOnlyList<ReminderView>> ListAsync(Guid userId, CancellationToken ct);
    Task<ReminderView> SaveAsync(Guid userId, ReminderInput input, ReminderFact? fact, CancellationToken ct);
}
// Channel-neutral seam. Only email is enabled; APNs/FCM registration/consent is a later feature.
public interface IReminderChannel
{
    string Channel { get; }
    Task<bool> DeliverAsync(Guid userId, ReminderDeliveryContent content, CancellationToken ct);
}
public sealed class ListRemindersHandler(IReminderStore store) : IRequestHandler<ListRemindersQuery, IReadOnlyList<ReminderView>>
{
    public Task<IReadOnlyList<ReminderView>> Handle(ListRemindersQuery q, CancellationToken ct) => store.ListAsync(q.UserId, ct);
}
public sealed class SaveReminderHandler(IReminderStore store, IReminderFacts facts, TimeProvider clock)
    : IRequestHandler<SaveReminderCommand, ReminderView>
{
    public Task<ReminderView> Handle(SaveReminderCommand q, CancellationToken ct)
    {
        var i = q.Input;
        if (q.UserId == Guid.Empty || i.Id == Guid.Empty || i.ExpectedRevision is < 0 or long.MaxValue)
            throw new AppFailure("Reminders.InvalidInput", FailureKind.Validation);
        if (i.Cancelled) return store.SaveAsync(q.UserId, i, null, ct);
        if (i.TimeZoneId is null || i.TimeZoneId.Length > 100 ||
            !(i.TimeZoneId == "UTC" || i.TimeZoneId.Contains('/')) ||
            i.TimeZoneId.Any(char.IsControl) || !TimeZoneInfo.TryFindSystemTimeZoneById(i.TimeZoneId, out _) ||
            i.LeadMinutes is not (0 or 10 or 30 or 60 or 180 or 1440) ||
            i.EventId?.Length > 160 || i.TargetId?.Length > 128)
            throw new AppFailure("Reminders.InvalidInput", FailureKind.Validation);
        var fact = facts.Resolve(i.EventId, i.TargetId, i.InstantUtc);
        var now = clock.GetUtcNow();
        if (fact.InstantUtc.AddMinutes(-i.LeadMinutes) < now.AddMinutes(2) || fact.InstantUtc > now.AddDays(366))
            throw new AppFailure("Reminders.InvalidTime", FailureKind.Validation);
        return store.SaveAsync(q.UserId, i, fact, ct);
    }
}
