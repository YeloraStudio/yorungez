namespace Yorungez.Identity.Application;

public sealed record ReminderEmailContent(string Title, DateTimeOffset InstantUtc, string TimeZoneId, string SourceUrl);
public interface IAccountReminderEmail
{
    // Resolve an existing, currently verified recipient inside Identity, never through another module's database.
    Task<bool> SendAsync(Guid userId, ReminderEmailContent content, CancellationToken ct);
}
