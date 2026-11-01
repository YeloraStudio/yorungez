using Yorungez.Core.Geo;

namespace Yorungez.Astronomy.Domain;

public enum SolarSystemBody { Sun, Moon, Mercury, Venus, Mars, Jupiter, Saturn, Uranus, Neptune }

public sealed record ObserverSite
{
    public ObserverCoordinates Coordinates { get; }
    public double? SuppliedElevationMeters { get; }
    public double EffectiveElevationMeters => SuppliedElevationMeters ?? 0;

    public ObserverSite(ObserverCoordinates coordinates, double? elevationMeters)
    {
        if (elevationMeters is { } height && (!double.IsFinite(height) || height is < -500 or > 10000))
            throw new ArgumentOutOfRangeException(nameof(elevationMeters));
        Coordinates = coordinates;
        SuppliedElevationMeters = elevationMeters;
    }
}

public static class CalculationScope
{
    // Initial delivery boundary, not a claim of uniform accuracy for every date.
    public static readonly DateTimeOffset StartUtc = new(2000, 1, 1, 0, 0, 0, TimeSpan.Zero);
    public static readonly DateTimeOffset EndExclusiveUtc = new(2036, 1, 1, 0, 0, 0, TimeSpan.Zero);
    // Conservative delivery guard after the +/-89.9 degree JPL cases exceeded
    // the directional target. This is not a physical singularity at 89 degrees.
    public static bool CanPublishAzimuth(double latitude) => Math.Abs(latitude) < 89;
}

public sealed record SkyContext(ObserverSite Site, DateTimeOffset InstantUtc);
public sealed record BodyPosition(SolarSystemBody Body, double AzimuthDegrees,
    double AirlessAltitudeDegrees, double StandardRefractionAltitudeDegrees,
    double RightAscensionHoursOfDate, double DeclinationDegreesOfDate,
    bool CenterAboveMathematicalHorizon);
public sealed record CenterHorizonCrossings(DateTimeOffset StartUtc, DateTimeOffset EndExclusiveUtc,
    DateTimeOffset? RisingUtc, DateTimeOffset? SettingUtc);

public interface ISkyCalculator
{
    BodyPosition Position(SkyContext context, SolarSystemBody body);
    CenterHorizonCrossings Crossings(SkyContext context, SolarSystemBody body);
    double TerrestrialJulianDay(DateTimeOffset instantUtc);
}
