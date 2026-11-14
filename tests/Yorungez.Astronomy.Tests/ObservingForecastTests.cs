using Yorungez.Astronomy.Application;
using Yorungez.Astronomy.Domain;
using Yorungez.Astronomy.Infrastructure;

namespace Yorungez.Astronomy.Tests;

public sealed class ObservingForecastTests
{
    private static readonly DateTimeOffset Now = new(2026, 11, 24, 9, 0, 0, TimeSpan.Zero);
    private readonly AstronomyEngineCalculator _calculator = new();

    [Fact]
    public async Task Shared_plan_uses_fresh_weather_but_keeps_geometry_when_it_is_stale()
    {
        var input = new ObservingInput(39.65, 27.88, 100, null, null, "moon");
        var clear = await Planner(10).PlanAsync(input, default);
        var cloudy = await Planner(90).PlanAsync(input, default);
        var stale = await Planner(10, Now.AddHours(-13)).PlanAsync(input, default);
        Assert.Contains(clear.Windows, window => window.Conditions == "good");
        Assert.All(cloudy.Windows, window => Assert.Equal("poor", window.Conditions));
        Assert.All(stale.Windows, window => Assert.Equal("unknown", window.Conditions));
        Assert.Equal("unavailable", stale.WeatherStatus);
        Assert.Equal(clear.EndUtc, stale.EndUtc);
        Assert.All(clear.Windows, window =>
        {
            Assert.Equal("moon", window.Target);
            Assert.InRange(window.AltitudeDegrees, 5, 90);
            Assert.True(window.BestUtc >= window.StartUtc && window.BestUtc < window.EndUtc);
        });
    }

    [Fact]
    public async Task Daylight_moon_and_a_dark_meteor_window_follow_different_rules()
    {
        var fullMoon = new ObservingInput(39.65, 27.88, null, "2026-11-27T00:00:00Z", "2026-11-29T00:00:00Z", "moon");
        var moon = await Planner(0).PlanAsync(fullMoon, default);
        Assert.Contains(moon.Windows, w => w.Light == "daylight");
        var eventInput = new ObservingInput(39.65, 27.88, null, "2026-12-14T00:00:00Z", "2026-12-15T23:59:00Z", "geminids");
        var eventPlan = await Planner(0).PlanAsync(eventInput, default);
        Assert.NotEmpty(eventPlan.Windows);
        Assert.All(eventPlan.Windows, w =>
        {
            Assert.Equal("radiant", w.Target);
            Assert.Equal("night", w.Light);
            Assert.InRange(w.AltitudeDegrees, 15, 90);
            Assert.Equal("unknown", w.Conditions);
        });
    }

    [Fact]
    public async Task A_future_day_keeps_lunar_phase_and_geometry_without_fetching_weather()
    {
        var start = new DateTimeOffset(2026, 12, 13, 21, 0, 0, TimeSpan.Zero);
        var input = new ObservingInput(39.65, 27.88, null, start.ToString("O"),
            start.AddDays(1).ToString("O"), "moon", IncludeMoonPhase: true);
        var planner = new ObservingPlanner(_calculator, _calculator, new NoCloudRequest(), new Clock());
        var plan = await planner.PlanAsync(input, default);
        Assert.Equal("outside_range", plan.WeatherStatus);
        Assert.Equal(Now.AddHours(48), plan.WeatherThroughUtc);
        Assert.Null(plan.WeatherUpdatedUtc);
        Assert.NotEmpty(plan.Windows);
        Assert.All(plan.Windows, window =>
        {
            Assert.Equal("unknown", window.Conditions);
            Assert.Null(window.CloudPercent);
        });
        Assert.NotNull(plan.MoonPhase);
        Assert.Equal(start.AddHours(12), plan.MoonPhase.InstantUtc);
        Assert.Equal("waxing-crescent", plan.MoonPhase.Phase);
        Assert.InRange(plan.MoonPhase.IlluminatedFraction, 0.05, 0.30);
    }

    [Fact]
    public async Task Eclipse_windows_are_local_to_the_visible_phase_and_publish_no_polar_azimuth()
    {
        var input = new ObservingInput(34.05, -118.24, null, "2026-03-03T00:00:00Z", "2026-03-04T00:00:00Z", "total-lunar");
        var planner = Planner(0);
        var west = await planner.PlanAsync(input, default);
        Assert.NotEmpty(west.Windows);
        Assert.All(west.Windows, w => Assert.InRange(w.BestUtc.Hour, 11, 12));
        var turkey = await planner.PlanAsync(input with { Latitude = 39.65, Longitude = 27.88 }, default);
        Assert.Empty(turkey.Windows);
        Assert.Contains(planner.Calendar(2026, 3), e => e.Id == "total-lunar" && e.PeakUtc.Day == 3);
        var pole = await planner.PlanAsync(new(89.5, 30, null, null, null, null), default);
        Assert.NotEmpty(pole.Windows);
        Assert.All(pole.Windows, w => Assert.Null(w.AzimuthDegrees));
    }

    private ObservingPlanner Planner(double cloud, DateTimeOffset? updated = null) =>
        new(_calculator, _calculator, new Fixture(cloud, updated ?? Now), new Clock());

    private sealed class Clock : TimeProvider { public override DateTimeOffset GetUtcNow() => Now; }
    private sealed class NoCloudRequest : ICloudForecast
    {
        public Task<CloudForecast?> GetAsync(ObserverSite site, CancellationToken ct) =>
            throw new InvalidOperationException("Long-range geometry does not require a weather request.");
    }
    private sealed class Fixture(double cloud, DateTimeOffset updated) : ICloudForecast
    {
        public Task<CloudForecast?> GetAsync(ObserverSite site, CancellationToken ct) =>
            Task.FromResult<CloudForecast?>(new(updated, Enumerable.Range(0, 49).Select(i => new ForecastHour(Now.AddHours(i), cloud, 0)).ToArray()));
    }
}
