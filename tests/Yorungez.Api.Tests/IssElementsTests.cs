using System.Net;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Microsoft.Extensions.Caching.Distributed;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Options;
using Yorungez.Catalog.Infrastructure;
using Yorungez.Catalog.Application;
using Yorungez.Catalog.Domain;

namespace Yorungez.Api.Tests;

public sealed class IssElementsTests
{
    private static readonly DateTimeOffset Epoch = new(2026, 11, 4, 8, 0, 0, TimeSpan.Zero);
    private static string Packet(string field = "NORAD_CAT_ID", object? value = null)
    {
        var record = new Dictionary<string, object> {
            ["NORAD_CAT_ID"] = 25544, ["EPOCH"] = "2026-11-04T08:00:00", ["MEAN_MOTION"] = 15.5,
            ["ECCENTRICITY"] = .0004, ["INCLINATION"] = 51.6, ["RA_OF_ASC_NODE"] = 75.0,
            ["ARG_OF_PERICENTER"] = 20.0, ["MEAN_ANOMALY"] = 15.0, ["BSTAR"] = .0001,
            ["MEAN_MOTION_DOT"] = .00001, ["MEAN_MOTION_DDOT"] = 0.0
        };
        if (value is not null) record[field] = value;
        return JsonSerializer.Serialize(new[] { record });
    }

    [Fact]
    public void Packet_has_explicit_source_epoch_finite_lifetime_and_raw_digest()
    {
        var packet = IssElementsRepository.Parse(Packet(), Epoch.AddHours(1), Epoch.AddHours(1));
        Assert.Equal(25544, packet.NoradCatalogId);
        Assert.Equal(Epoch, packet.EpochUtc);
        Assert.Equal(Epoch.AddHours(72), packet.ExpiresAtUtc);
        Assert.Equal(64, packet.Sha256.Length);
        Assert.Equal("TEME", packet.ReferenceFrame);
    }

    [Theory]
    [InlineData("NORAD_CAT_ID", 5)]
    [InlineData("REF_FRAME", "J2000")]
    [InlineData("MEAN_ELEMENT_THEORY", "SGP4-XP")]
    [InlineData("ECCENTRICITY", -0.1)]
    [InlineData("MEAN_MOTION", "15.5")]
    [InlineData("EPOCH", "invalid")]
    public void Untrusted_identity_conventions_and_elements_are_rejected(string field, object value) =>
        Assert.Throws<FormatException>(() => IssElementsRepository.Parse(Packet(field, value), Epoch, Epoch));

    [Fact]
    public void Expired_and_far_future_epochs_are_rejected()
    {
        Assert.Throws<FormatException>(() => IssElementsRepository.Parse(Packet(), Epoch.AddHours(73), Epoch.AddHours(73)));
        Assert.Throws<FormatException>(() => IssElementsRepository.Parse(Packet(), Epoch.AddHours(-1), Epoch.AddHours(-1)));
    }

    [Fact]
    public async Task Concurrent_reads_share_one_fetch_back_off_and_do_not_return_expired_elements()
    {
        var clock = new Clock { Now = Epoch.AddHours(1) };
        using var http = new Handler(Packet());
        var cache = new MemoryDistributedCache(Options.Create(new MemoryDistributedCacheOptions()));
        using var repository = new IssElementsRepository(new Factory(http), cache, clock);
        var results = await Task.WhenAll(Enumerable.Range(0, 20).Select(_ => repository.ReadAsync(default)));
        Assert.All(results, value => Assert.NotNull(value));
        Assert.Equal(1, http.Count);
        clock.Now = Epoch.AddHours(4); http.Fail = true;
        Assert.NotNull(await repository.ReadAsync(default));
        Assert.Equal(2, http.Count);
        Assert.NotNull(await repository.ReadAsync(default));
        Assert.Equal(2, http.Count);
        clock.Now = Epoch.AddHours(73);
        Assert.Null(await repository.ReadAsync(default));
        Assert.Equal(3, http.Count);
    }

    [Theory]
    [InlineData(true)]
    [InlineData(false)]
    public async Task Public_endpoint_returns_a_provenance_packet_or_explicit_noncacheable_unavailability(bool available)
    {
        await using var app = new AppFactory { CacheUnavailable = true };
        await using var configured = app.WithWebHostBuilder(builder => builder.ConfigureServices(services =>
        {
            services.RemoveAll<IIssElementsRepository>();
            services.AddSingleton<IIssElementsRepository>(new FixedRepository(available
                ? IssElementsRepository.Parse(Packet(), Epoch, Epoch) : null));
        }));
        using var client = configured.CreateClient();
        var response = await client.GetAsync("/api/v1/catalog/satellites/iss");
        Assert.Equal(available ? HttpStatusCode.OK : HttpStatusCode.ServiceUnavailable, response.StatusCode);
        using var document = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        if (available)
        {
            Assert.Equal(25544, document.RootElement.GetProperty("noradCatalogId").GetInt32());
            Assert.NotNull(response.Headers.ETag);
            Assert.True(response.Headers.CacheControl!.Public);
        }
        else
        {
            Assert.Equal("Satellite.ElementsUnavailable", document.RootElement.GetProperty("code").GetString());
            Assert.True(response.Headers.CacheControl!.NoStore);
        }
    }

    private sealed class FixedRepository(IssElements? value) : IIssElementsRepository
    { public Task<IssElements?> ReadAsync(CancellationToken ct) => Task.FromResult(value); }

    private sealed class Clock : TimeProvider { public DateTimeOffset Now; public override DateTimeOffset GetUtcNow() => Now; }
    private sealed class Factory(HttpMessageHandler handler) : IHttpClientFactory { public HttpClient CreateClient(string name) => new(handler, disposeHandler: false); }
    private sealed class Handler(string body) : HttpMessageHandler
    {
        public int Count; public bool Fail;
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken ct)
        {
            Count++;
            Assert.Equal(IssElementsRepository.SourceUrl, request.RequestUri!.ToString());
            return Task.FromResult(new HttpResponseMessage(Fail ? HttpStatusCode.ServiceUnavailable : HttpStatusCode.OK)
                { Content = new StringContent(body, Encoding.UTF8, "application/json") });
        }
    }
}
