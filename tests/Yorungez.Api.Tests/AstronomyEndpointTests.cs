using System.Net;
using System.Net.Http.Json;
using System.Text.Json;

namespace Yorungez.Api.Tests;

// Deliberately no DB fixture initialization: this factory points at a nonexistent
// test database and an unavailable cache. Public calculations must still work.
public sealed class AstronomyEndpointTests
{
    [Theory]
    [InlineData("tr", "Güneş")]
    [InlineData("en", "Sun")]
    public async Task Anonymous_calculations_are_bilingual_and_independent_of_identity_database_and_cache(string language, string sunName)
    {
        await using var app = new AppFactory { CacheUnavailable = true };
        using var client = app.Client(language);
        var response = await client.PostAsJsonAsync("/api/v1/sky/positions", new
        { latitude = 41.0082, longitude = 28.9784, instant = "2026-10-30T23:00:00+03:00" });
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal(language, response.Content.Headers.ContentLanguage.Single());
        Assert.Contains("no-store", response.Headers.CacheControl!.ToString());
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(DateTimeOffset.Parse("2026-10-30T20:00:00Z"), json.GetProperty("instantUtc").GetDateTimeOffset());
        var bodies = json.GetProperty("bodies").EnumerateArray().ToArray();
        Assert.Equal(9, bodies.Length);
        var sun = bodies.Single(b => b.GetProperty("id").GetString() == "sun");
        Assert.Equal(sunName, sun.GetProperty("name").GetString());
        Assert.False(sun.GetProperty("coordinates").GetProperty("centerAboveMathematicalHorizon").GetBoolean());
        var metadata = json.GetProperty("calculation");
        Assert.True(metadata.GetProperty("elevationAssumed").GetBoolean());
        Assert.Equal("unknown", metadata.GetProperty("conditionsStatus").GetString());
        Assert.False(json.TryGetProperty("latitude", out _));
        var terms = (await client.GetFromJsonAsync<JsonElement>("/api/v1/terms/")).EnumerateArray()
            .Select(t => t.GetProperty("id").GetString()).ToHashSet();
        foreach (var term in metadata.GetProperty("glossaryTermIds").EnumerateArray())
            Assert.Contains(term.GetString(), terms);
    }

    [Theory]
    [InlineData("tr")]
    [InlineData("en")]
    public async Task Polar_direction_is_withheld_with_an_explicit_localized_reason(string language)
    {
        await using var app = new AppFactory();
        using var client = app.Client(language);
        var response = await client.PostAsJsonAsync("/api/v1/sky/positions", new
        { latitude = 89.9, longitude = 0, instant = "2026-03-20T12:00:00Z", bodies = new[] { "neptune" } });
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = (await response.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("bodies")[0];
        Assert.Equal("unsupported_near_pole", body.GetProperty("azimuthStatus").GetString());
        Assert.Equal(JsonValueKind.Null, body.GetProperty("coordinates").GetProperty("azimuthDegrees").ValueKind);
        Assert.False(string.IsNullOrWhiteSpace(body.GetProperty("azimuthDescription").GetString()));
    }

    [Theory]
    [InlineData(91, 0, "2026-10-30T20:00:00Z", "sun", "Sky.InvalidCoordinates")]
    [InlineData(0, 181, "2026-10-30T20:00:00Z", "sun", "Sky.InvalidCoordinates")]
    [InlineData(0, 0, "2026-10-30T20:00:00", "sun", "Sky.InvalidInstant")]
    [InlineData(0, 0, "2026-02-30T20:00:00Z", "sun", "Sky.InvalidInstant")]
    [InlineData(0, 0, "1999-12-31T23:59:59Z", "sun", "Sky.UnsupportedDate")]
    [InlineData(0, 0, "2036-01-01T00:00:00Z", "sun", "Sky.UnsupportedDate")]
    [InlineData(0, 0, "2026-10-30T20:00:00Z", "earth", "Sky.UnsupportedBody")]
    [InlineData(0, 0, "2026-10-30T20:00:00Z", "0", "Sky.UnsupportedBody")]
    public async Task Invalid_contexts_are_rejected_without_silent_clamping_or_time_interpretation(
        double latitude, double longitude, string instant, string body, string code)
    {
        await using var app = new AppFactory();
        using var client = app.Client();
        var response = await client.PostAsJsonAsync("/api/v1/sky/positions", new
        { latitude, longitude, instant, bodies = new[] { body } });
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        Assert.Equal(code, (await response.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("code").GetString());
    }

    [Fact]
    public async Task Oversized_public_calculation_requests_are_rejected_without_echoing_payload()
    {
        await using var app = new AppFactory();
        using var client = app.Client("en");
        var privateMarker = "synthetic-private-payload";
        using var content = new StringContent("{\"padding\":\"" + privateMarker + new string('a', 9000) + "\"}",
            System.Text.Encoding.UTF8, "application/json");
        var response = await client.PostAsync("/api/v1/sky/positions", content);
        Assert.Equal(HttpStatusCode.RequestEntityTooLarge, response.StatusCode);
        var text = await response.Content.ReadAsStringAsync();
        Assert.DoesNotContain(privateMarker, text);
        Assert.Equal("Sky.RequestTooLarge", JsonDocument.Parse(text).RootElement.GetProperty("code").GetString());
    }

    [Fact]
    public async Task Polar_no_crossing_uses_nulls_and_search_window_instead_of_inventing_times()
    {
        await using var app = new AppFactory();
        using var client = app.Client("tr");
        var response = await client.PostAsJsonAsync("/api/v1/sky/horizon-crossings", new
        { latitude = 80, longitude = 0, instant = "2026-06-21T00:00:00Z", body = "sun", elevationMeters = 0 });
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("Arama penceresinde bulunamadı", json.GetProperty("risingStatus").GetString());
        Assert.Equal(JsonValueKind.Null, json.GetProperty("crossings").GetProperty("risingUtc").ValueKind);
        Assert.Equal(JsonValueKind.Null, json.GetProperty("crossings").GetProperty("settingUtc").ValueKind);
        Assert.Contains("24 UTC", json.GetProperty("definition").GetString());
    }
}
