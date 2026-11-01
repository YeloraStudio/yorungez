using System.Net;
using System.Net.Http.Json;
using System.Text.Json;

namespace Yorungez.Api.Tests;

[Trait("Category", "Integration")]
public sealed class FaultAndThrottleTests
{
    [Fact]
    public async Task Redis_outage_does_not_block_the_curated_public_glossary()
    {
        var app = new AppFactory { CacheUnavailable = true };
        try
        {
            await app.InitializeAsync();
            using var client = app.Client("tr");
            Assert.Equal(HttpStatusCode.OK, (await client.GetAsync("/api/v1/terms/azimuth")).StatusCode);
            var ready = await client.GetAsync("/health/ready");
            Assert.Equal(HttpStatusCode.OK, ready.StatusCode);
            Assert.Equal("Degraded", await ready.Content.ReadAsStringAsync());
        }
        finally { await ((IAsyncLifetime)app).DisposeAsync(); }
    }

    [Fact]
    public async Task Authentication_rate_limit_returns_a_localized_response()
    {
        var app = new AppFactory { RateLimit = 1 };
        try
        {
            await app.InitializeAsync();
            using var client = app.Client("en");
            Assert.Equal(HttpStatusCode.Unauthorized, (await client.GetAsync("/api/v1/auth/me")).StatusCode);
            var response = await client.GetAsync("/api/v1/auth/me");
            Assert.Equal(HttpStatusCode.TooManyRequests, response.StatusCode);
            var body = await response.Content.ReadFromJsonAsync<JsonElement>();
            Assert.Equal("Common.RateLimited", body.GetProperty("code").GetString());
            Assert.Contains("Too many requests", body.GetProperty("detail").GetString());
        }
        finally { await ((IAsyncLifetime)app).DisposeAsync(); }
    }
}
