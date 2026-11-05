namespace Yorungez.Notebook.Domain;

// Private, server-owned planning record; no coordinates or arbitrary recipient/payload.
public sealed class EventReminder
{
    public Guid UserId { get; set; }
    public Guid Id { get; set; }
    public long Revision { get; set; }
    public string? EventId { get; set; }
    public required string TargetId { get; set; }
    public required string Title { get; set; }
    public required string SourceUrl { get; set; }
    public required string EventKey { get; set; }
    public DateTimeOffset InstantUtc { get; set; }
    public required string TimeZoneId { get; set; }
    public int LeadMinutes { get; set; }
    public required string Channel { get; set; }
    public required string Status { get; set; }
    public DateTimeOffset CreatedAtUtc { get; set; }
    public DateTimeOffset DueAtUtc { get; set; }
    public DateTimeOffset ExpiresAtUtc { get; set; }
    public DateTimeOffset NextAttemptAtUtc { get; set; }
    public DateTimeOffset? SentAtUtc { get; set; }
    public DateTimeOffset? LeaseUntilUtc { get; set; }
    public Guid? LeaseId { get; set; }
    public int Attempts { get; set; }
}
