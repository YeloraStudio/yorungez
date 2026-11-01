using MediatR;
using System.Globalization;
using System.Text.RegularExpressions;
using Yorungez.Application;
using Yorungez.Astronomy.Domain;
using Yorungez.Core.Geo;

namespace Yorungez.Astronomy.Application;

public sealed record SkyInput(double? Latitude, double? Longitude, string? Instant,
    double? ElevationMeters, string[]? Bodies);
public sealed record CrossingsInput(double? Latitude, double? Longitude, string? Instant,
    double? ElevationMeters, string? Body);
public sealed record CalculationMetadata(string Engine, string Version, string Frame, string TimeModel,
    string RefractionModel, DateTimeOffset CalculatedAtUtc, double TerrestrialJulianDay,
    bool ElevationAssumed, double EffectiveElevationMeters, string Assumptions,
    string ConditionsStatus, string ConditionsDescription, string[] Sources, string[] GlossaryTermIds);
public sealed record PositionCoordinates(double? AzimuthDegrees, double AirlessAltitudeDegrees,
    double StandardRefractionAltitudeDegrees, double RightAscensionHoursOfDate,
    double DeclinationDegreesOfDate, bool CenterAboveMathematicalHorizon);
public sealed record LocalizedPosition(string Id, string Name, PositionCoordinates Coordinates,
    string AzimuthStatus, string AzimuthDescription);
public sealed record SkyPositionsView(DateTimeOffset InstantUtc, string Language,
    CalculationMetadata Calculation, IReadOnlyList<LocalizedPosition> Bodies);
public sealed record HorizonCrossingsView(string Id, string Name, string Language,
    CenterHorizonCrossings Crossings, string RisingStatus, string SettingStatus,
    string Definition, CalculationMetadata Calculation);
public sealed record CalculateSkyQuery(SkyInput Input, string Language) : IQuery<SkyPositionsView>;
public sealed record CalculateCrossingsQuery(CrossingsInput Input, string Language) : IQuery<HorizonCrossingsView>;

public static partial class SkyValidation
{
    [GeneratedRegex(@"(Z|[+-]\d{2}:\d{2})$", RegexOptions.CultureInvariant | RegexOptions.IgnoreCase)]
    private static partial Regex ExplicitOffset();

    public static SkyContext Context(double? latitude, double? longitude, string? instant, double? elevation)
    {
        ObserverCoordinates coordinates;
        try
        {
            if (latitude is null || longitude is null) throw new ArgumentOutOfRangeException(nameof(latitude));
            coordinates = ObserverCoordinates.Create(latitude.Value, longitude.Value);
        }
        catch (ArgumentOutOfRangeException) { throw new AppFailure("Sky.InvalidCoordinates", FailureKind.Validation); }
        if (instant is null || instant.Length > 64 || !instant.Contains('T') || !ExplicitOffset().IsMatch(instant)
            || !DateTimeOffset.TryParse(instant, CultureInfo.InvariantCulture, DateTimeStyles.None, out var time))
            throw new AppFailure("Sky.InvalidInstant", FailureKind.Validation);
        time = time.ToUniversalTime();
        if (time < CalculationScope.StartUtc || time >= CalculationScope.EndExclusiveUtc)
            throw new AppFailure("Sky.UnsupportedDate", FailureKind.Validation);
        try { return new(new ObserverSite(coordinates, elevation), time); }
        catch (ArgumentOutOfRangeException) { throw new AppFailure("Sky.InvalidElevation", FailureKind.Validation); }
    }

    public static SolarSystemBody Body(string? id)
    {
        // Never accept numeric enum values supplied by a caller.
        return Enum.GetValues<SolarSystemBody>().Cast<SolarSystemBody?>().FirstOrDefault(b =>
            string.Equals(b!.Value.ToString(), id, StringComparison.OrdinalIgnoreCase))
            ?? throw new AppFailure("Sky.UnsupportedBody", FailureKind.Validation);
    }

    public static CalculationMetadata Metadata(SkyContext context, string language, ISkyCalculator calculator,
        ITextCatalog texts, TimeProvider clock) => new("Astronomy Engine", "2.1.19",
        "topocentric-apparent-equator-of-date; azimuth north=0 east=90; degrees except RA hours",
        "UTC input treated as engine UT; TT via Espenak-Meeus DeltaT; no live IERS EOP",
        "airless primary; standard-atmosphere refraction separate",
        clock.GetUtcNow(), calculator.TerrestrialJulianDay(context.InstantUtc),
        context.Site.SuppliedElevationMeters is null, context.Site.EffectiveElevationMeters,
        texts.Get("Sky.Assumptions", language), "unknown", texts.Get("Sky.ConditionsUnknown", language),
        ["https://github.com/cosinekitty/astronomy/tree/v2.1.19", "https://ssd.jpl.nasa.gov/horizons/manual.html"],
        ["azimuth", "altitude", "topocentric", "refraction", "right-ascension", "declination", "arcminute", "utc"]);
}

public sealed class CalculateSkyHandler(ISkyCalculator calculator, ITextCatalog texts, TimeProvider clock)
    : IRequestHandler<CalculateSkyQuery, SkyPositionsView>
{
    public Task<SkyPositionsView> Handle(CalculateSkyQuery query, CancellationToken ct)
    {
        var input = query.Input;
        var context = SkyValidation.Context(input.Latitude, input.Longitude, input.Instant, input.ElevationMeters);
        if (input.Bodies is { Length: < 1 or > 9 }) throw new AppFailure("Sky.UnsupportedBody", FailureKind.Validation);
        var bodies = input.Bodies?.Select(SkyValidation.Body).ToArray() ?? Enum.GetValues<SolarSystemBody>();
        if (bodies.Distinct().Count() != bodies.Length) throw new AppFailure("Sky.UnsupportedBody", FailureKind.Validation);
        var positions = bodies.Select(body =>
        {
            ct.ThrowIfCancellationRequested();
            var result = calculator.Position(context, body);
            var publishAzimuth = CalculationScope.CanPublishAzimuth(context.Site.Coordinates.Latitude);
            return new LocalizedPosition(body.ToString().ToLowerInvariant(), texts.Get("Body." + body, query.Language),
                new(publishAzimuth ? result.AzimuthDegrees : null, result.AirlessAltitudeDegrees,
                    result.StandardRefractionAltitudeDegrees, result.RightAscensionHoursOfDate,
                    result.DeclinationDegreesOfDate, result.CenterAboveMathematicalHorizon),
                publishAzimuth ? "calculated" : "unsupported_near_pole",
                texts.Get(publishAzimuth ? "Sky.AzimuthCalculated" : "Sky.PolarAzimuthUnavailable", query.Language));
        }).ToArray();
        return Task.FromResult(new SkyPositionsView(context.InstantUtc, query.Language,
            SkyValidation.Metadata(context, query.Language, calculator, texts, clock), positions));
    }
}

public sealed class CalculateCrossingsHandler(ISkyCalculator calculator, ITextCatalog texts, TimeProvider clock)
    : IRequestHandler<CalculateCrossingsQuery, HorizonCrossingsView>
{
    public Task<HorizonCrossingsView> Handle(CalculateCrossingsQuery query, CancellationToken ct)
    {
        var input = query.Input;
        var context = SkyValidation.Context(input.Latitude, input.Longitude, input.Instant, input.ElevationMeters);
        if (context.InstantUtc.AddDays(1) > CalculationScope.EndExclusiveUtc)
            throw new AppFailure("Sky.UnsupportedDate", FailureKind.Validation);
        var body = SkyValidation.Body(input.Body);
        ct.ThrowIfCancellationRequested();
        var result = calculator.Crossings(context, body);
        return Task.FromResult(new HorizonCrossingsView(body.ToString().ToLowerInvariant(),
            texts.Get("Body." + body, query.Language), query.Language, result,
            texts.Get(result.RisingUtc is null ? "Sky.CrossingNotFound" : "Sky.CrossingFound", query.Language),
            texts.Get(result.SettingUtc is null ? "Sky.CrossingNotFound" : "Sky.CrossingFound", query.Language),
            texts.Get("Sky.CrossingDefinition", query.Language),
            SkyValidation.Metadata(context, query.Language, calculator, texts, clock)));
    }
}
