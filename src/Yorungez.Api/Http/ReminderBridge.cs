using Yorungez.Application;
using Yorungez.Catalog.Application;
using Yorungez.Identity.Application;
using Yorungez.Notebook.Application;

namespace Yorungez.Api.Http;

// Host composition connects public module contracts; no cross-module table access.
public sealed class ReminderFacts(IPlanningCatalog catalog) : IReminderFacts
{
    public static readonly IReadOnlyDictionary<string, string> Targets = new Dictionary<string, string>
    {
        ["sun"] = "Sun", ["moon"] = "Moon", ["mercury"] = "Mercury", ["venus"] = "Venus", ["mars"] = "Mars",
        ["jupiter"] = "Jupiter", ["saturn"] = "Saturn", ["uranus"] = "Uranus", ["neptune"] = "Neptune"
    };
    private static readonly IReadOnlyDictionary<string, string> Kinds = new Dictionary<string, string>
    {
        ["new-moon"] = "New Moon", ["first-quarter"] = "First Quarter Moon", ["full-moon"] = "Full Moon", ["last-quarter"] = "Last Quarter Moon",
        ["march-equinox"] = "March Equinox", ["june-solstice"] = "June Solstice", ["september-equinox"] = "September Equinox", ["december-solstice"] = "December Solstice",
        ["opposition"] = "Opposition", ["greatest-elongation"] = "Greatest Elongation",
        ["inferior-conjunction"] = "Inferior Conjunction", ["superior-conjunction"] = "Superior Conjunction"
    };
    public ReminderFact Resolve(string? eventId, string? targetId, DateTimeOffset? instantUtc)
    {
        if (!string.IsNullOrEmpty(eventId))
        {
            // The request carries the event's UTC month only as a bounded lookup hint; all facts remain server-owned.
            if (instantUtc is null || instantUtc.Value.Year is < 2000 or > 2035) throw Invalid();
            var month = catalog.ReadMonth(instantUtc.Value.UtcDateTime.Year, instantUtc.Value.UtcDateTime.Month);
            var fact = month.Events.SingleOrDefault(e => e.Id == eventId);
            if (fact is null || fact.InstantUtc != instantUtc || !Kinds.TryGetValue(fact.Kind, out var kind) || !Targets.TryGetValue(fact.TargetId, out var name)) throw Invalid();
            var title = fact.Kind is "opposition" or "greatest-elongation" or "inferior-conjunction" or "superior-conjunction" ? name + " · " + kind : kind;
            var source = month.Provenance.Sources.Single(s => s.Id == fact.SourceId).Url;
            return new(fact.Id, fact.TargetId, title, fact.InstantUtc, source);
        }
        if (targetId is null || targetId == "sun" || !Targets.TryGetValue(targetId, out var target) || instantUtc is null
            || instantUtc.Value.Year is < 2000 or > 2035) throw Invalid();
        return new(null, targetId, target + " · Observing time", instantUtc.Value.ToUniversalTime(), "https://github.com/cosinekitty/astronomy");
    }
    private static AppFailure Invalid() => new("Reminders.InvalidEvent", FailureKind.Validation);
}
public sealed class EmailReminderChannel(IAccountReminderEmail email) : IReminderChannel
{
    public string Channel => "email";
    public Task<bool> DeliverAsync(Guid userId, ReminderDeliveryContent content, CancellationToken ct) =>
        email.SendAsync(userId, new(content.Title, content.InstantUtc, content.TimeZoneId, content.SourceUrl), ct);
}
