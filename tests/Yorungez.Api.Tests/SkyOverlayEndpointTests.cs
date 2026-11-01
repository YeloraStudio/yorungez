using System.Net;
using System.Net.Http.Json;
using System.Text.Json;

namespace Yorungez.Api.Tests;
public sealed class SkyOverlayEndpointTests
{
    [Theory]
    [InlineData("tr")]
    [InlineData("en")]
    public async Task Overlay_catalogue_is_anonymous_source_fingerprinted_and_cache_independent(string language)
    {
        await using var app = new AppFactory { CacheUnavailable = true };
        using var client = app.Client(language);
        var response = await client.GetAsync("/api/v1/catalog/overlays");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var snapshot = await response.Content.ReadFromJsonAsync<JsonElement>();
        var data = snapshot.GetProperty("overlays");
        var objects = data.GetProperty("deepSky").EnumerateArray().ToArray();
        Assert.Equal(107, objects.Length);
        var m31 = Assert.Single(objects, o => o.GetProperty("name").GetString() == "M31");
        Assert.Equal("dso-ngc0224", m31.GetProperty("id").GetString());
        Assert.InRange(m31.GetProperty("raHoursJ2000").GetDouble(), 0.7, 0.8);
        Assert.Equal(85, data.GetProperty("art").GetProperty("figures").GetArrayLength());
        Assert.Equal(64, snapshot.GetProperty("provenance").GetProperty("sha256").GetString()!.Length);
        Assert.Equal(2, snapshot.GetProperty("provenance").GetProperty("sources").GetArrayLength());
        using var request = new HttpRequestMessage(HttpMethod.Get, "/api/v1/catalog/overlays");
        request.Headers.IfNoneMatch.Add(response.Headers.ETag!);
        Assert.Equal(HttpStatusCode.NotModified, (await client.SendAsync(request)).StatusCode);
    }
}
