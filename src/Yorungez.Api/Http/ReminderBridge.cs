using Yorungez.Application;
using Yorungez.Astronomy.Application;
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
        // A local ISS prediction supplies the user's chosen time only. The API
        // does not receive an observer location or assert local visibility.
        if (targetId == "sat-25544" && instantUtc is not null)
            return new(null, targetId, "International Space Station · Observing time",
                instantUtc.Value.ToUniversalTime(), "https://spotthestation.nasa.gov/", TimeSpan.FromHours(72));
        if (targetId is null || targetId == "sun" || !Targets.TryGetValue(targetId, out var target) || instantUtc is null
            || instantUtc.Value.Year is < 2000 or > 2035) throw Invalid();
        return new(null, targetId, target + " · Observing time", instantUtc.Value.ToUniversalTime(), "https://github.com/cosinekitty/astronomy");
    }
    public ReminderFact ResolveWeather(ReminderInput input)
    {
        if (input.EventId is not null || input.InstantUtc is not { } instant || input.WeatherSite is not { } site ||
            !ObservingPlanner.Supported(input.TargetId) || input.LeadMinutes is not (10 or 30)) throw Invalid();
        SkyValidation.Context(site.Latitude, site.Longitude, instant.ToString("O"), site.ElevationMeters);
        var id = input.TargetId!;
        var name = Targets.GetValueOrDefault(id) ?? id switch
        {
            "penumbral-lunar" => "Penumbral lunar eclipse",
            "partial-lunar" => "Partial phase of the lunar eclipse",
            "total-lunar" => "Total phase of the lunar eclipse",
            "geminids" => "Geminids meteor shower",
            "quadrantids" => "Quadrantids meteor shower",
            "perseids" => "Perseids meteor shower",
            _ => throw Invalid()
        };
        // Thirty local dates including today can span more than thirty UTC days at a zone transition.
        return new(null, id, name, instant, ObservingPlanner.Source(id), TimeSpan.FromDays(31));
    }

    private static AppFailure Invalid() => new("Reminders.InvalidEvent", FailureKind.Validation);
}
public sealed class EmailReminderChannel(IAccountReminderEmail email, ObservingPlanner planner) : IReminderChannel
{
    public string Channel => "email";
    public async Task<bool> DeliverAsync(Guid userId, ReminderDeliveryContent content, CancellationToken ct)
    {
        var message = new ReminderEmailContent(content.Title, content.InstantUtc, content.TimeZoneId, content.SourceUrl);
        if (content.WeatherSite is { } site)
        {
            var instant = content.InstantUtc;
            var plan = await planner.PlanAsync(new(site.Latitude, site.Longitude, site.ElevationMeters,
                instant.ToString("O"), instant.AddMinutes(5).ToString("O"), content.TargetId), ct);
            var window = plan.Windows.SingleOrDefault(w => w.Conditions == "good" && w.StartUtc == instant);
            if (window is null) return false;
            message = message with { WeatherDependent = true, AzimuthDegrees = window.AzimuthDegrees,
                AltitudeDegrees = window.AltitudeDegrees, Radiant = window.Target == "radiant" };
        }
        return await email.SendAsync(userId, message, ct);
    }
}
