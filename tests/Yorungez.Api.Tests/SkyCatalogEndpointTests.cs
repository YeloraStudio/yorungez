using System.Net;
using System.Net.Http.Json;
using System.Text.Json;

namespace Yorungez.Api.Tests;

public sealed class SkyCatalogEndpointTests
{
    [Theory]
    [InlineData("tr")]
    [InlineData("en")]
    public async Task Anonymous_catalogue_has_consistent_bilingual_identifiers_without_database_or_cache(string language)
    {
        await using var app = new AppFactory { CacheUnavailable = true };
        using var client = app.Client(language);
        var response = await client.GetAsync("/api/v1/catalog/sky");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var snapshot = await response.Content.ReadFromJsonAsync<JsonElement>();
        var catalog = snapshot.GetProperty("catalog");
        var stars = catalog.GetProperty("stars").EnumerateArray().ToArray();
        var ids = stars.Select(s => s.GetProperty("id").GetString()).ToHashSet();
        Assert.Equal(5073, ids.Count);
        Assert.Equal(5070, stars.Count(s => s.GetProperty("inclusion").GetString() == "bright"));
        var sirius = stars.Single(s => s.GetProperty("hip").ValueKind == JsonValueKind.Number && s.GetProperty("hip").GetInt32() == 32349);
        Assert.Equal("hyg-32263", sirius.GetProperty("id").GetString());
        Assert.Equal("Sirius", sirius.GetProperty("name").GetString());
        Assert.All(stars, star => {
            var distance = star.GetProperty("distanceParsecs");
            Assert.True(distance.ValueKind == JsonValueKind.Null || distance.GetDouble() is > 0 and < 100000);
        });
        var constellations = catalog.GetProperty("constellations").EnumerateArray().ToArray();
        Assert.Equal(88, constellations.Select(c => c.GetProperty("id").GetString()).Distinct().Count());
        Assert.Single(constellations, c => c.GetProperty("id").GetString() == "con-ser");
        foreach (var constellation in constellations)
        {
            Assert.False(string.IsNullOrWhiteSpace(constellation.GetProperty("names").GetProperty(language).GetString()));
            foreach (var line in constellation.GetProperty("lines").EnumerateArray())
                foreach (var node in line.EnumerateArray()) Assert.Contains(node.GetString(), ids);
        }
        Assert.Equal(64, snapshot.GetProperty("provenance").GetProperty("derivedSha256").GetString()!.Length);
    }

    [Fact]
    public async Task Catalog_revalidation_uses_the_provenance_digest()
    {
        await using var app = new AppFactory { CacheUnavailable = true };
        using var client = app.Client();
        var response = await client.GetAsync("/api/v1/catalog/sky");
        var snapshot = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal('"' + snapshot.GetProperty("provenance").GetProperty("derivedSha256").GetString() + '"', response.Headers.ETag!.Tag);
        using var request = new HttpRequestMessage(HttpMethod.Get, "/api/v1/catalog/sky");
        request.Headers.IfNoneMatch.Add(response.Headers.ETag);
        var unchanged = await client.SendAsync(request);
        Assert.Equal(HttpStatusCode.NotModified, unchanged.StatusCode);
        Assert.Empty(await unchanged.Content.ReadAsByteArrayAsync());
    }
}
