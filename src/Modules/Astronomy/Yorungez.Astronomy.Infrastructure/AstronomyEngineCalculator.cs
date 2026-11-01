using CosineKitty;
using Yorungez.Astronomy.Domain;
using Engine = CosineKitty.Astronomy;

namespace Yorungez.Astronomy.Infrastructure;

public sealed class AstronomyEngineCalculator : ISkyCalculator
{
    private static Observer Observer(SkyContext context) => new(context.Site.Coordinates.Latitude,
        context.Site.Coordinates.Longitude, context.Site.EffectiveElevationMeters);
    private static Body Body(SolarSystemBody body) => Enum.Parse<Body>(body.ToString());
    private static AstroTime Time(DateTimeOffset instant) => new(instant.UtcDateTime);

    public BodyPosition Position(SkyContext context, SolarSystemBody body)
    {
        var time = Time(context.InstantUtc);
        var observer = Observer(context);
        var equatorial = Engine.Equator(Body(body), time, observer, EquatorEpoch.OfDate, Aberration.Corrected);
        var airless = Engine.Horizon(time, observer, equatorial.ra, equatorial.dec, Refraction.None);
        var refracted = Engine.Horizon(time, observer, equatorial.ra, equatorial.dec, Refraction.Normal);
        return new(body, airless.azimuth, airless.altitude, refracted.altitude,
            equatorial.ra, equatorial.dec, airless.altitude > 0);
    }

    public CenterHorizonCrossings Crossings(SkyContext context, SolarSystemBody body)
    {
        var start = Time(context.InstantUtc);
        var observer = Observer(context);
        var end = context.InstantUtc.AddDays(1);
        DateTimeOffset? Find(Direction direction)
        {
            var result = Engine.SearchAltitude(Body(body), observer, direction, start, 1, 0);
            if (result is null) return null;
            var utc = new DateTimeOffset(DateTime.SpecifyKind(result.ToUtcDateTime(), DateTimeKind.Utc));
            return utc >= context.InstantUtc && utc < end ? utc : null;
        }
        return new(context.InstantUtc, end, Find(Direction.Rise), Find(Direction.Set));
    }

    public double TerrestrialJulianDay(DateTimeOffset instantUtc) => Time(instantUtc).tt + 2451545.0;
}
