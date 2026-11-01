using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
namespace Yorungez.Api.Tests;
public sealed class PlanningEndpointTests(AppFactory app):IClassFixture<AppFactory> {
    [Theory][InlineData("tr")][InlineData("en")]
    public async Task Calendar_has_verified_USNO_facts_provenance_and_conditional_cache(string language){
        using var client=app.Client(language);var response=await client.GetAsync("/api/v1/events/calendar?year=2026&month=10");Assert.Equal(HttpStatusCode.OK,response.StatusCode);
        var data=await response.Content.ReadFromJsonAsync<JsonElement>();Assert.Equal(1781,data.GetProperty("provenance").GetProperty("phaseReferenceCount").GetInt32());
        Assert.Contains(data.GetProperty("events").EnumerateArray(),e=>e.GetProperty("kind").GetString()=="last-quarter"&&e.GetProperty("instantUtc").GetDateTimeOffset()==DateTimeOffset.Parse("2026-10-03T13:25:00Z"));
        using var request=new HttpRequestMessage(HttpMethod.Get,"/api/v1/events/calendar?year=2026&month=10");request.Headers.IfNoneMatch.Add(response.Headers.ETag!);Assert.Equal(HttpStatusCode.NotModified,(await client.SendAsync(request)).StatusCode);
    }
    [Theory][InlineData(2036,1)][InlineData(2026,0)][InlineData(2026,13)]
    public async Task Invalid_calendar_ranges_have_a_localized_validation_response(int year,int month){using var client=app.Client("tr");var r=await client.GetAsync($"/api/v1/events/calendar?year={year}&month={month}");Assert.Equal(HttpStatusCode.BadRequest,r.StatusCode);Assert.Contains("Calendar.InvalidMonth",await r.Content.ReadAsStringAsync());}
    [Theory][InlineData("tr")][InlineData("en")]
    public async Task Place_search_and_nearest_point_are_local_no_store_and_preserve_exact_coordinates(string language){using var client=app.Client(language);
        var r=await client.PostAsJsonAsync("/api/v1/locations/places",new{query="Balıkesir Altıeylül"});Assert.Equal(HttpStatusCode.OK,r.StatusCode);Assert.True(r.Headers.CacheControl!.NoStore);
        var doc=await r.Content.ReadFromJsonAsync<JsonElement>();Assert.Contains(doc.GetProperty("places").EnumerateArray(),p=>p.GetProperty("place").GetProperty("name").GetString()!.Contains("Altıeylül"));
        var nearest=await client.PostAsJsonAsync("/api/v1/locations/places",new{latitude=39.6484,longitude=27.8826});Assert.Equal(HttpStatusCode.OK,nearest.StatusCode);Assert.True(nearest.Headers.CacheControl!.NoStore);
    }
    [Theory][InlineData(-91,0)][InlineData(0,181)]
    public async Task Place_lookup_rejects_invalid_coordinates(double latitude,double longitude){using var client=app.Client("en");var r=await client.PostAsJsonAsync("/api/v1/locations/places",new{latitude,longitude});Assert.Equal(HttpStatusCode.BadRequest,r.StatusCode);Assert.Contains("Place.InvalidInput",await r.Content.ReadAsStringAsync());}
}
