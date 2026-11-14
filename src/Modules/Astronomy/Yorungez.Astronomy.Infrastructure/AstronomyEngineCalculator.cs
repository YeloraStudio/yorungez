using CosineKitty;
using Yorungez.Astronomy.Domain;
using Engine = CosineKitty.Astronomy;

namespace Yorungez.Astronomy.Infrastructure;

public sealed class AstronomyEngineCalculator : ISkyCalculator, IObservationAstronomy
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

    public double LunarPhaseAngle(DateTimeOffset instant) => Engine.MoonPhase(Time(instant));

    public BodyIllumination Illumination(SkyContext context, SolarSystemBody body)
    {
        var result = Engine.Illumination(Body(body), Time(context.InstantUtc));
        return new(result.phase_fraction, result.mag);
    }

    public (double Azimuth, double Altitude) FixedPosition(SkyContext context, double j2000RaDegrees, double j2000DecDegrees)
    {
        var time = Time(context.InstantUtc);
        var j2000 = Engine.VectorFromSphere(new Spherical(j2000DecDegrees, j2000RaDegrees, 1), time);
        var equator = Engine.EquatorFromVector(Engine.RotateVector(Engine.Rotation_EQJ_EQD(time), j2000));
        var horizon = Engine.Horizon(time, Observer(context), equator.ra, equator.dec, Refraction.None);
        return (horizon.azimuth, horizon.altitude);
    }

    public IReadOnlyList<LunarEclipsePhase> LunarEclipses(DateTimeOffset start, DateTimeOffset end)
    {
        List<LunarEclipsePhase> phases = [];
        var eclipse = Engine.SearchLunarEclipse(Time(start.AddHours(-6)));
        while (true)
        {
            var peak = new DateTimeOffset(eclipse.peak.ToUtcDateTime(), TimeSpan.Zero);
            if (peak >= end.AddHours(6)) break;
            Add("penumbral", eclipse.sd_penum, peak);
            Add("partial", eclipse.sd_partial, peak);
            Add("total", eclipse.sd_total, peak);
            eclipse = Engine.NextLunarEclipse(eclipse.peak);
        }
        return phases;

        void Add(string kind, double minutes, DateTimeOffset peak)
        {
            if (minutes <= 0) return;
            var from = peak.AddMinutes(-minutes);
            var to = peak.AddMinutes(minutes);
            if (from < end && to > start) phases.Add(new(kind, from, peak, to));
        }
    }
}
