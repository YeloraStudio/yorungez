using MediatR;
using Yorungez.Application;
using Yorungez.Astronomy.Domain;

namespace Yorungez.Astronomy.Application;

public sealed record ObservingInput(double? Latitude, double? Longitude, double? ElevationMeters,
    string? StartUtc, string? EndUtc, string? Target, bool IncludeMoonPhase = false, bool FutureOnly = false);
public sealed record ForecastHour(DateTimeOffset InstantUtc, double CloudPercent, double? FogPercent,
    double? LowCloudPercent = null, double? MiddleCloudPercent = null, double? HighCloudPercent = null);
public sealed record CloudForecast(DateTimeOffset UpdatedAtUtc, IReadOnlyList<ForecastHour> Hours);
public interface ICloudForecast
{
    Task<CloudForecast?> GetAsync(ObserverSite site, CancellationToken ct);
}

public sealed record ObservingWindow(string Id, string Target, DateTimeOffset StartUtc, DateTimeOffset EndUtc,
    DateTimeOffset BestUtc, double? AzimuthDegrees, double AltitudeDegrees, string Light, string Conditions,
    double? CloudPercent, double? FogPercent, double? MoonIlluminatedFraction,
    double? LowCloudPercent = null, double? MiddleCloudPercent = null, double? HighCloudPercent = null);
public sealed record ObservingForecastView(DateTimeOffset StartUtc, DateTimeOffset EndUtc,
    DateTimeOffset? WeatherUpdatedUtc, string WeatherStatus, IReadOnlyList<ObservingWindow> Windows,
    DateTimeOffset WeatherThroughUtc, ObservingMoonPhase? MoonPhase);
public sealed record ObservingMoonPhase(DateTimeOffset InstantUtc, string Phase, double IlluminatedFraction);
public sealed record ObservingForecastQuery(ObservingInput Input) : IQuery<ObservingForecastView>;
public sealed record ObservingCalendarEvent(string Id, DateTimeOffset PeakUtc, string SourceUrl);

public sealed class ObservingForecastHandler(ObservingPlanner planner)
    : IRequestHandler<ObservingForecastQuery, ObservingForecastView>
{
    public Task<ObservingForecastView> Handle(ObservingForecastQuery query, CancellationToken ct) =>
        planner.PlanAsync(query.Input, ct);
}

public sealed class ObservingPlanner(ISkyCalculator sky, IObservationAstronomy astronomy, ICloudForecast clouds, TimeProvider clock)
{
    public const string WeatherSource = "https://docs.api.met.no/doc/locationforecast/datamodel.html";
    public const string MeteorSource = "https://www.imo.net/calendar/";
    public const string EclipseSource = "https://eclipse.gsfc.nasa.gov/lunar.html";
    public const string PlanetSource = "https://science.nasa.gov/solar-system/skywatching/planetary-alignments-and-planet-parades/";
    public const string MoonSource = "https://aa.usno.navy.mil/faq/crescent";
    private static readonly TimeSpan Step = TimeSpan.FromMinutes(5);
    private static readonly SolarSystemBody[] Bodies = [SolarSystemBody.Moon, SolarSystemBody.Mercury, SolarSystemBody.Venus,
        SolarSystemBody.Mars, SolarSystemBody.Jupiter, SolarSystemBody.Saturn];

    // Selected peaks from the IMO 2026/2027 calendars. Coordinates describe the radiant near maximum.
    private static readonly Meteor[] Meteors =
    [
        new("geminids", new(2026, 12, 14, 14, 0, 0, TimeSpan.Zero), 112, 33),
        new("quadrantids", new(2027, 1, 4, 3, 25, 0, TimeSpan.Zero), 230, 49),
        new("perseids", new(2027, 8, 13, 9, 0, 0, TimeSpan.Zero), 48, 58),
        new("geminids", new(2027, 12, 14, 20, 0, 0, TimeSpan.Zero), 112, 33)
    ];

    public static bool Supported(string? id) => id is "moon" or "mercury" or "venus" or "mars" or "jupiter" or "saturn" or
        "penumbral-lunar" or "partial-lunar" or "total-lunar" or "geminids" or "quadrantids" or "perseids";

    public static string Source(string id) => id switch
    {
        "moon" => MoonSource,
        "geminids" or "quadrantids" or "perseids" => MeteorSource,
        "penumbral-lunar" or "partial-lunar" or "total-lunar" => EclipseSource,
        _ => PlanetSource
    };

    public IReadOnlyList<ObservingCalendarEvent> Calendar(int year, int month)
    {
        if (year is < 2000 or > 2035 || month is < 1 or > 12)
            throw new AppFailure("Sky.InvalidObservationWindow", FailureKind.Validation);
        var start = new DateTimeOffset(year, month, 1, 0, 0, 0, TimeSpan.Zero);
        // Include events near a UTC month edge for local time zones on either side.
        var from = start.AddDays(-1);
        var to = start.AddMonths(1).AddDays(1);
        return astronomy.LunarEclipses(from, to).GroupBy(e => e.PeakUtc)
            .Select(g => new ObservingCalendarEvent(g.Last().Kind + "-lunar", g.Key, EclipseSource))
            .Concat(Meteors.Where(e => e.Peak >= from && e.Peak < to)
                .Select(e => new ObservingCalendarEvent(e.Id, e.Peak, MeteorSource)))
            .OrderBy(e => e.PeakUtc).ToArray();
    }

    public async Task<ObservingForecastView> PlanAsync(ObservingInput input, CancellationToken ct)
    {
        var now = clock.GetUtcNow();
        var weatherThrough = now.AddHours(48);
        var start = SkyValidation.Context(input.Latitude, input.Longitude, input.StartUtc ?? now.ToString("O"), input.ElevationMeters);
        var end = input.EndUtc is null ? start.InstantUtc.AddHours(48) :
            SkyValidation.Context(input.Latitude, input.Longitude, input.EndUtc, input.ElevationMeters).InstantUtc;
        if (end <= start.InstantUtc || end > start.InstantUtc.AddHours(48) || end > CalculationScope.EndExclusiveUtc ||
            (input.Target is not null and not "lunar-eclipse" && !Supported(input.Target)))
            throw new AppFailure("Sky.InvalidObservationWindow", FailureKind.Validation);

        var hasForecastHorizon = end > now && start.InstantUtc < weatherThrough;
        var forecast = hasForecastHorizon ? await clouds.GetAsync(start.Site, ct) : null;
        var weather = forecast is { Hours.Count: > 0 } && forecast.UpdatedAtUtc >= now.AddHours(-12) && forecast.UpdatedAtUtc <= now.AddMinutes(10)
            ? forecast : null;
        var hours = weather?.Hours.ToDictionary(h => h.InstantUtc);
        var weatherStatus = weather is not null ? "available" : hasForecastHorizon ? "unavailable" : "outside_range";
        Dictionary<DateTimeOffset, Frame> frames = [];
        List<ObservingWindow> windows = [];

        Frame At(DateTimeOffset instant)
        {
            if (frames.TryGetValue(instant, out var found)) return found;
            ct.ThrowIfCancellationRequested();
            var context = new SkyContext(start.Site, instant);
            var frame = new Frame(context, sky.Position(context, SolarSystemBody.Sun),
                sky.Position(context, SolarSystemBody.Moon), astronomy.Illumination(context, SolarSystemBody.Moon));
            frames.Add(instant, frame);
            return frame;
        }

        ForecastHour? WeatherAt(DateTimeOffset instant)
        {
            if (hours is null || instant < now || instant >= weatherThrough) return null;
            var hour = new DateTimeOffset(instant.Year, instant.Month, instant.Day, instant.Hour, 0, 0, TimeSpan.Zero);
            return hours.GetValueOrDefault(instant.Minute >= 30 ? hour.AddHours(1) : hour);
        }

        bool Includes(string id) => input.Target is null || input.Target == id;

        foreach (var body in Bodies)
        {
            var id = body.ToString().ToLowerInvariant();
            if (!Includes(id)) continue;
            AddWindows(id, id, start.InstantUtc, end, instant =>
            {
                var f = At(instant);
                var moon = body == SolarSystemBody.Moon;
                var p = moon ? f.Moon : sky.Position(f.Context, body);
                var illumination = moon ? f.MoonLight : astronomy.Illumination(f.Context, body);
                var a = p.AirlessAltitudeDegrees;
                var daylight = f.Sun.AirlessAltitudeDegrees;
                var elongation = Separation(p, f.Sun);
                // Conservative planning cutoffs. These are neither detection probabilities nor horizon contacts.
                if (moon)
                {
                    if (a < 5 || elongation < 12 || illumination.Fraction < .01) return null;
                    if (daylight > 0 && (a < 12 || elongation < 35 || illumination.Fraction < .10)) return null;
                    if (daylight > -6 && illumination.Fraction < .06) return null;
                }
                else
                {
                    var sunLimit = illumination.Magnitude <= -.5 ? -4 : -8;
                    if (a < 7 || daylight > sunLimit || elongation < 12) return null;
                }
                var demanding = a < 12 || (moon ? illumination.Fraction < .08 : illumination.Magnitude > 1);
                var merit = a - Math.Max(0, daylight + 12) * (moon ? 1 : 2);
                return new Sample(p.AzimuthDegrees, a, daylight, merit, demanding, moon ? illumination.Fraction : null);
            });
        }

        if (input.Target is null or "lunar-eclipse" or "penumbral-lunar" or "partial-lunar" or "total-lunar")
        {
            foreach (var group in astronomy.LunarEclipses(start.InstantUtc, end).GroupBy(phase => phase.PeakUtc))
            {
                var phases = group.ToArray();
                foreach (var phase in phases)
                {
                    var id = phase.Kind + "-lunar";
                    if (!Includes(id) && input.Target != "lunar-eclipse") continue;
                    var deeper = phases.FirstOrDefault(candidate => candidate.StartUtc > phase.StartUtc);
                    if (deeper is null)
                        AddPhase(phase.StartUtc, phase.EndUtc);
                    else
                    {
                        AddPhase(phase.StartUtc, deeper.StartUtc);
                        AddPhase(deeper.EndUtc, phase.EndUtc);
                    }

                    void AddPhase(DateTimeOffset from, DateTimeOffset to) =>
                        AddWindows(id, "moon", Later(start.InstantUtc, from), Earlier(end, to), instant =>
                        {
                            var f = At(instant);
                            var a = f.Moon.AirlessAltitudeDegrees;
                            if (a <= 0) return null;
                            return new Sample(f.Moon.AzimuthDegrees, a, f.Sun.AirlessAltitudeDegrees,
                                90 - Math.Abs((instant - phase.PeakUtc).TotalMinutes) / 10 + a / 4,
                                a < 8 || phase.Kind == "penumbral", f.MoonLight.Fraction);
                        });
                }
            }
        }

        foreach (var meteor in Meteors)
        {
            if (!Includes(meteor.Id)) continue;
            AddWindows(meteor.Id, "radiant", Later(start.InstantUtc, meteor.Peak.AddHours(-18)),
                Earlier(end, meteor.Peak.AddHours(18)), instant =>
            {
                var f = At(instant);
                if (f.Sun.AirlessAltitudeDegrees > -18) return null;
                var (azimuth, altitude) = astronomy.FixedPosition(f.Context, meteor.Ra, meteor.Dec);
                if (altitude < 15) return null;
                var moonlight = f.Moon.AirlessAltitudeDegrees > 0 ? f.MoonLight.Fraction : 0;
                return new Sample(azimuth, altitude, f.Sun.AirlessAltitudeDegrees,
                    altitude - 70 * moonlight - Math.Abs((instant - meteor.Peak).TotalHours), moonlight >= .5 || altitude < 22, null);
            });
        }

        ObservingMoonPhase? moonPhase = null;
        if (input.IncludeMoonPhase)
        {
            var midpoint = start.InstantUtc.AddTicks((end - start.InstantUtc).Ticks / 2);
            var phaseAngle = astronomy.LunarPhaseAngle(midpoint);
            var sector = (int)Math.Floor((phaseAngle + 22.5) / 45) % 8;
            string[] names = ["new-moon", "waxing-crescent", "first-quarter", "waxing-gibbous",
                "full-moon", "waning-gibbous", "last-quarter", "waning-crescent"];
            moonPhase = new(midpoint, names[sector], At(midpoint).MoonLight.Fraction);
        }
        return new(start.InstantUtc, end, weather?.UpdatedAtUtc, weatherStatus,
            windows.OrderBy(w => w.StartUtc).ThenBy(w => w.Id, StringComparer.Ordinal).ToArray(), weatherThrough, moonPhase);

        void AddWindows(string id, string target, DateTimeOffset from, DateTimeOffset to, Func<DateTimeOffset, Sample?> sample)
        {
            if (input.FutureOnly) from = Later(from, now);
            ObservingWindow? current = null;
            double best = double.NegativeInfinity;
            for (var instant = from; instant < to;)
            {
                var next = Earlier(instant + Step, to);
                var s = sample(instant);
                if (s is not null)
                {
                    var hourly = WeatherAt(instant);
                    var condition = hourly is null ? "unknown" :
                        hourly.CloudPercent >= 75 || hourly.FogPercent >= 35 || hourly.LowCloudPercent >= 65 ? "poor" :
                        hourly.CloudPercent <= 30 && !(hourly.FogPercent >= 10) &&
                        !(hourly.LowCloudPercent >= 25) && !s.Demanding ? "good" : "uncertain";
                    var light = s.SunAltitude >= 0 ? "daylight" : s.SunAltitude > -18 ? "twilight" : "night";
                    if (current is null || current.Conditions != condition || current.Light != light)
                    {
                        Finish();
                        current = new(id, target, instant, next, instant, null, 0, light, condition, null, null, null);
                    }

                    var merit = s.Merit - (hourly?.CloudPercent ?? 0) / 3 - (hourly?.FogPercent ?? 0) / 2;
                    current = current with { EndUtc = next };
                    if (merit > best)
                    {
                        best = merit;
                        current = current with { BestUtc = instant,
                            AzimuthDegrees = CalculationScope.CanPublishAzimuth(start.Site.Coordinates.Latitude) ? s.Azimuth : null,
                            AltitudeDegrees = s.Altitude, CloudPercent = hourly?.CloudPercent,
                            FogPercent = hourly?.FogPercent, MoonIlluminatedFraction = s.MoonFraction,
                            LowCloudPercent = hourly?.LowCloudPercent, MiddleCloudPercent = hourly?.MiddleCloudPercent,
                            HighCloudPercent = hourly?.HighCloudPercent };
                    }
                }
                else Finish();
                instant = next;
            }
            Finish();

            void Finish()
            {
                if (current is not null) windows.Add(current);
                current = null;
                best = double.NegativeInfinity;
            }
        }
    }

    private static double Separation(BodyPosition first, BodyPosition second)
    {
        const double radians = Math.PI / 180;
        var d1 = first.DeclinationDegreesOfDate * radians;
        var d2 = second.DeclinationDegreesOfDate * radians;
        var ra = (first.RightAscensionHoursOfDate - second.RightAscensionHoursOfDate) * 15 * radians;
        var cosine = Math.Sin(d1) * Math.Sin(d2) + Math.Cos(d1) * Math.Cos(d2) * Math.Cos(ra);
        return Math.Acos(Math.Clamp(cosine, -1, 1)) / radians;
    }

    private static DateTimeOffset Earlier(DateTimeOffset a, DateTimeOffset b) => a < b ? a : b;
    private static DateTimeOffset Later(DateTimeOffset a, DateTimeOffset b) => a > b ? a : b;
    private sealed record Meteor(string Id, DateTimeOffset Peak, double Ra, double Dec);
    private sealed record Frame(SkyContext Context, BodyPosition Sun, BodyPosition Moon, BodyIllumination MoonLight);
    private sealed record Sample(double Azimuth, double Altitude, double SunAltitude, double Merit, bool Demanding, double? MoonFraction);
}
