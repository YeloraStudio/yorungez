using System.Security.Cryptography;
using System.Text.Json;
using Yorungez.Astronomy.Application;
using Yorungez.Astronomy.Domain;
using Yorungez.Astronomy.Infrastructure;

namespace Yorungez.Astronomy.Tests;

public sealed class ReferenceTests
{
    private static readonly string DirectoryPath = Path.Combine(AppContext.BaseDirectory, "ReferenceData", "Horizons");
    private static readonly JsonElement Data = JsonDocument.Parse(File.ReadAllText(Path.Combine(DirectoryPath, "references.json"))).RootElement;
    private readonly AstronomyEngineCalculator _calculator = new();
    public static IEnumerable<object[]> Positions => Data.GetProperty("positions").EnumerateArray().Select(c => new object[] { c.GetProperty("id").GetString()! });
    public static IEnumerable<object[]> Events => Data.GetProperty("events").EnumerateArray().Select(c => new object[] { c.GetProperty("id").GetString()! });
    private static JsonElement Case(string collection, string id) => Data.GetProperty(collection).EnumerateArray().Single(c => c.GetProperty("id").GetString() == id);
    private static SkyContext Context(JsonElement c, string? time = null) => SkyValidation.Context(
        c.GetProperty("latitude").GetDouble(), c.GetProperty("longitude").GetDouble(),
        time ?? c.GetProperty("instantUtc").GetString(), c.GetProperty("elevationMeters").GetDouble());

    private void AssertPosition(JsonElement c, JsonElement row)
    {
        var actual = _calculator.Position(Context(c, row.GetProperty("instantUtc").GetString()), SkyValidation.Body(c.GetProperty("body").GetString()));
        var az = row.GetProperty("azimuthDegrees").GetDouble() * Math.PI / 180;
        var alt = row.GetProperty("altitudeDegrees").GetDouble() * Math.PI / 180;
        var actualAz = actual.AzimuthDegrees * Math.PI / 180;
        var actualAlt = actual.AirlessAltitudeDegrees * Math.PI / 180;
        // Compare directions on the sphere; raw azimuth subtraction is invalid at 0/360 and near zenith.
        var dot = Math.Sin(alt) * Math.Sin(actualAlt) + Math.Cos(alt) * Math.Cos(actualAlt) * Math.Cos(az - actualAz);
        var arcminutes = Math.Acos(Math.Clamp(dot, -1, 1)) * 180 / Math.PI * 60;
        var tolerance = Data.GetProperty("positionToleranceArcminutes").GetDouble();
        Assert.InRange(Math.Abs(actual.AirlessAltitudeDegrees - row.GetProperty("altitudeDegrees").GetDouble()) * 60, 0, tolerance);
        if (CalculationScope.CanPublishAzimuth(c.GetProperty("latitude").GetDouble()))
            Assert.True(arcminutes <= tolerance,
                $"{c.GetProperty("id").GetString()} {row.GetProperty("instantUtc").GetString()}: separation {arcminutes:F6} arcmin");
        // Raw polar directional residuals remain in the probe report as failures
        // of the original 1-arcminute target. Product API must withhold azimuth.
        Assert.Equal(actual.AirlessAltitudeDegrees > 0, actual.CenterAboveMathematicalHorizon);
    }

    [Theory, MemberData(nameof(Positions))]
    public void Airless_topocentric_direction_matches_saved_JPL_reference(string id)
    {
        var c = Case("positions", id);
        AssertPosition(c, c.GetProperty("rows")[0]);
    }

    [Theory, MemberData(nameof(Events))]
    public void Full_day_directions_and_center_horizon_crossings_match_independent_JPL_series(string id)
    {
        var c = Case("events", id);
        var rows = c.GetProperty("rows").EnumerateArray().ToArray();
        foreach (var row in rows) AssertPosition(c, row);
        var result = _calculator.Crossings(Context(c), SkyValidation.Body(c.GetProperty("body").GetString()));
        foreach (var rising in new[] { true, false })
        {
            DateTimeOffset? expected = null;
            for (var i = 1; i < rows.Length; i++)
            {
                var a = rows[i - 1].GetProperty("altitudeDegrees").GetDouble();
                var b = rows[i].GetProperty("altitudeDegrees").GetDouble();
                if (rising ? a <= 0 && b > 0 : a >= 0 && b < 0)
                {
                    var first = rows[i - 1].GetProperty("instantUtc").GetDateTimeOffset();
                    var last = rows[i].GetProperty("instantUtc").GetDateTimeOffset();
                    expected = first.AddSeconds((last - first).TotalSeconds * -a / (b - a));
                    break;
                }
            }
            var actual = rising ? result.RisingUtc : result.SettingUtc;
            if (expected is null) Assert.Null(actual);
            else
            {
                Assert.NotNull(actual);
                Assert.InRange(Math.Abs((actual!.Value - expected.Value).TotalSeconds), 0,
                    Data.GetProperty("crossingToleranceSeconds").GetDouble());
            }
        }
    }

    [Fact]
    public void Source_snapshots_are_complete_and_match_recorded_hashes()
    {
        foreach (var c in Data.GetProperty("positions").EnumerateArray().Concat(Data.GetProperty("events").EnumerateArray()))
        {
            var bytes = File.ReadAllBytes(Path.Combine(DirectoryPath, "raw", c.GetProperty("id").GetString() + ".json"));
            Assert.Equal(c.GetProperty("rawSha256").GetString(), Convert.ToHexStringLower(SHA256.HashData(bytes)));
            var source = JsonDocument.Parse(bytes).RootElement;
            Assert.Contains("NASA/JPL", source.GetProperty("signature").GetProperty("source").GetString());
            Assert.Contains("$$SOE", source.GetProperty("result").GetString());
        }
    }

    [Fact]
    public void Equivalent_offsets_and_dateline_coordinates_produce_the_same_physical_result()
    {
        var a = SkyValidation.Context(10, 180, "2026-10-30T23:59:00Z", null);
        var b = SkyValidation.Context(10, -180, "2026-10-31T02:59:00+03:00", 0);
        var first = _calculator.Position(a, SolarSystemBody.Mars);
        var second = _calculator.Position(b, SolarSystemBody.Mars);
        Assert.InRange(Math.Abs(first.AirlessAltitudeDegrees - second.AirlessAltitudeDegrees), 0, 1e-9);
        Assert.InRange(Math.Abs(first.AzimuthDegrees - second.AzimuthDegrees), 0, 1e-9);
        Assert.Null(a.Site.SuppliedElevationMeters);
        Assert.Equal(0, a.Site.EffectiveElevationMeters);
    }

    [Fact]
    public async Task Parallel_requests_do_not_share_mutable_observer_or_time_state()
    {
        var cases = Data.GetProperty("positions").EnumerateArray().ToArray();
        await Task.WhenAll(Enumerable.Range(0, 64).Select(i => Task.Run(() =>
            AssertPosition(cases[i % cases.Length], cases[i % cases.Length].GetProperty("rows")[0]))));
    }
}
