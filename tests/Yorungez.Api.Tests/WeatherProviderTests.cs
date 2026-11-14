using System.Net;
using System.Text;
using Microsoft.Extensions.Caching.Distributed;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Options;
using Yorungez.Api.Http;
using Yorungez.Astronomy.Domain;
using Yorungez.Core.Geo;

namespace Yorungez.Api.Tests;

public sealed class WeatherProviderTests
{
    [Fact]
    public async Task Neighbors_share_the_cache_and_only_the_rounded_cell_reaches_the_provider()
    {
        using var upstream = new ForecastResponse();
        var config = new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?>
        {
            ["ObservingForecast:MetNoUserAgent"] = "Yorungez-Test/1.0 (+https://example.invalid/)"
        }).Build();
        var cache = new MemoryDistributedCache(Options.Create(new MemoryDistributedCacheOptions()));
        var source = new MetNoForecast(new ClientFactory(upstream), cache, config, TimeProvider.System);
        var a = await source.GetAsync(new(ObserverCoordinates.Create(39.64278, 27.88324), 100), default);
        var b = await source.GetAsync(new(ObserverCoordinates.Create(39.63789, 27.91147), 80), default);
        Assert.NotNull(a);
        Assert.NotNull(b);
        Assert.Equal(1, upstream.Requests);
        Assert.Equal(a.UpdatedAtUtc, b.UpdatedAtUtc);
        var hour = Assert.Single(b.Hours);
        Assert.Equal(20, hour.CloudPercent);
        Assert.Equal(15, hour.LowCloudPercent);
        Assert.Null(hour.FogPercent);
    }

    [Fact]
    public async Task Expired_entry_is_revalidated_and_a_304_reuses_the_forecast()
    {
        var clock = new ForecastClock();
        using var upstream = new ForecastResponse(clock);
        var config = new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?>
        {
            ["ObservingForecast:MetNoUserAgent"] = "Yorungez-Test/1.0 (+https://example.invalid/)"
        }).Build();
        var cache = new MemoryDistributedCache(Options.Create(new MemoryDistributedCacheOptions()));
        var source = new MetNoForecast(new ClientFactory(upstream), cache, config, clock);
        var site = new ObserverSite(ObserverCoordinates.Create(39.64278, 27.88324), null);

        var original = await source.GetAsync(site, default);
        clock.Now = clock.Now.AddMinutes(16);
        var revalidated = await source.GetAsync(site, default);

        Assert.NotNull(original);
        Assert.NotNull(revalidated);
        Assert.Equal(2, upstream.Requests);
        Assert.Equal(original.UpdatedAtUtc, revalidated.UpdatedAtUtc);
        Assert.Equal(original.Hours.ToArray(), revalidated.Hours.ToArray());
        Assert.NotNull(await source.GetAsync(site, default));
        Assert.Equal(2, upstream.Requests);
    }

    private sealed class ClientFactory(HttpMessageHandler handler) : IHttpClientFactory
    {
        public HttpClient CreateClient(string name) => new(handler, disposeHandler: false)
        {
            BaseAddress = new Uri("https://api.met.no/")
        };
    }

    private sealed class ForecastClock : TimeProvider
    {
        public DateTimeOffset Now { get; set; } = DateTimeOffset.UtcNow;
        public override DateTimeOffset GetUtcNow() => Now;
    }

    private sealed class ForecastResponse(TimeProvider? clock = null) : HttpMessageHandler
    {
        private static readonly DateTimeOffset LastModified = new(2026, 11, 14, 10, 0, 0, TimeSpan.Zero);
        public int Requests { get; private set; }

        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            Requests++;
            Assert.Equal("?lat=39.60&lon=27.90", request.RequestUri!.Query);
            Assert.Contains("Yorungez-Test", request.Headers.UserAgent.ToString());
            var expiry = (clock ?? TimeProvider.System).GetUtcNow().AddMinutes(15);
            if (Requests > 1)
            {
                Assert.Equal(LastModified, request.Headers.IfModifiedSince);
                var unchanged = new HttpResponseMessage(HttpStatusCode.NotModified);
                unchanged.Content.Headers.Expires = expiry;
                return Task.FromResult(unchanged);
            }
            Assert.Null(request.Headers.IfModifiedSince);
            const string packet = """
                {"properties":{"meta":{"updated_at":"2026-11-14T10:00:00Z"},"timeseries":[
                    {"time":"2026-11-14T12:00:00Z","data":{"instant":{"details":{"cloud_area_fraction":20,"cloud_area_fraction_low":15}}}},
                    {"time":"2026-11-14T13:00:00Z","data":{"instant":{"details":{"cloud_area_fraction":110}}}}
                ]}}
                """;
            var response = new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StringContent(packet, Encoding.UTF8, "application/json")
            };
            response.Content.Headers.Expires = expiry;
            response.Content.Headers.LastModified = LastModified;
            return Task.FromResult(response);
        }
    }
}
