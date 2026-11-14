using System.Globalization;
using System.Net;
using System.Text.Json;
using Microsoft.Extensions.Caching.Distributed;
using Yorungez.Astronomy.Application;
using Yorungez.Astronomy.Domain;

namespace Yorungez.Api.Http;

public sealed class MetNoForecast(IHttpClientFactory clients, IDistributedCache cache, IConfiguration configuration,
    TimeProvider clock) : ICloudForecast
{
    private static readonly SemaphoreSlim[] Locks = Enumerable.Range(0, 32).Select(_ => new SemaphoreSlim(1)).ToArray();
    private static readonly SemaphoreSlim Requests = new(1);
    private static long nextRequest;
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    public async Task<CloudForecast?> GetAsync(ObserverSite site, CancellationToken ct)
    {
        var userAgent = configuration["ObservingForecast:MetNoUserAgent"];
        if (string.IsNullOrWhiteSpace(userAgent)) userAgent = configuration["ObservingForecast:ImageMetNoUserAgent"];
        if (string.IsNullOrWhiteSpace(userAgent)) return null;

        // Only a shared cell center reaches MET Norway. Exact input is used in memory for geometry.
        var (latitude, longitude) = Cell(site.Coordinates.Latitude, site.Coordinates.Longitude);
        var key = FormattableString.Invariant($"met-no:v1:{latitude:F2}:{longitude:F2}");
        var gate = Locks[(int)((uint)key.GetHashCode(StringComparison.Ordinal) % (uint)Locks.Length)];
        try
        {
            var current = await ReadAsync(key, ct);
            if (current?.RefreshAfterUtc > clock.GetUtcNow()) return Current(current);
            if (!await gate.WaitAsync(TimeSpan.FromSeconds(4), ct)) return null;
            try
            {
                current = await ReadAsync(key, ct);
                if (current?.RefreshAfterUtc > clock.GetUtcNow()) return Current(current);
                using var client = clients.CreateClient("MetNo");
                using var request = new HttpRequestMessage(HttpMethod.Get, FormattableString.Invariant(
                    $"weatherapi/locationforecast/2.0/complete?lat={latitude:F2}&lon={longitude:F2}"));
                request.Headers.UserAgent.ParseAdd(userAgent);
                request.Headers.IfModifiedSince = current?.LastModifiedUtc;
                using HttpResponseMessage response = await SendAsync(client, request, ct);
                var now = clock.GetUtcNow();
                var expires = response.Content.Headers.Expires ?? now.AddMinutes(15);
                if (response.Headers.CacheControl?.MaxAge is { } maxAge)
                    expires = (response.Headers.Date ?? now) + maxAge;
                if (expires <= now) expires = now.AddMinutes(5);

                if (response.StatusCode == HttpStatusCode.NotModified && current?.Forecast is not null)
                    current = current with { RefreshAfterUtc = expires, Available = true };
                else if (response.StatusCode is HttpStatusCode.OK or HttpStatusCode.NonAuthoritativeInformation)
                {
                    await using var body = await response.Content.ReadAsStreamAsync(ct);
                    using var json = await JsonDocument.ParseAsync(body, cancellationToken: ct);
                    current = new Cached(Parse(json.RootElement), response.Content.Headers.LastModified, expires, true);
                }
                else
                {
                    expires = response.Headers.RetryAfter?.Date ?? (now + (response.Headers.RetryAfter?.Delta ?? TimeSpan.FromMinutes(5)));
                    if (response.StatusCode is HttpStatusCode.TooManyRequests or HttpStatusCode.ServiceUnavailable)
                        Interlocked.Exchange(ref nextRequest, Environment.TickCount64 + (long)Math.Clamp((expires - now).TotalMilliseconds, 30000, 86400000));
                    current = new Cached(current?.Forecast, current?.LastModifiedUtc, expires, false);
                }
                await cache.SetAsync(key, JsonSerializer.SerializeToUtf8Bytes(current, JsonOptions), new DistributedCacheEntryOptions
                {
                    AbsoluteExpiration = expires.AddHours(12)
                }, ct);
                return Current(current);
            }
            finally { gate.Release(); }
        }
        catch (OperationCanceledException) when (ct.IsCancellationRequested) { throw; }
        catch (Exception ex) when (ex is HttpRequestException or OperationCanceledException or JsonException or
            InvalidOperationException or KeyNotFoundException or FormatException or IOException or StackExchange.Redis.RedisException)
        {
            return null;
        }
    }

    private static async Task<HttpResponseMessage> SendAsync(HttpClient client, HttpRequestMessage request, CancellationToken ct)
    {
        if (!await Requests.WaitAsync(TimeSpan.FromSeconds(1), ct)) throw new HttpRequestException("Weather queue full.");
        try
        {
            var delay = Interlocked.Read(ref nextRequest) - Environment.TickCount64;
            if (delay > 1000) throw new HttpRequestException("Weather provider backoff.");
            if (delay > 0) await Task.Delay(TimeSpan.FromMilliseconds(delay), ct);
            Interlocked.Exchange(ref nextRequest, Environment.TickCount64 + 200);
            return await client.SendAsync(request, HttpCompletionOption.ResponseContentRead, ct);
        }
        finally { Requests.Release(); }
    }

    private async Task<Cached?> ReadAsync(string key, CancellationToken ct) =>
        await cache.GetAsync(key, ct) is { } bytes ? JsonSerializer.Deserialize<Cached>(bytes, JsonOptions) : null;

    private static CloudForecast? Current(Cached? current) => current is { Available: true } ? current.Forecast : null;

    private static (double Latitude, double Longitude) Cell(double latitude, double longitude)
    {
        // The reminder stores two decimals. Apply the same precision to the live lookup
        // so a stored reminder cannot change weather cells on a rounding boundary.
        var lat = Math.Round(Math.Round(latitude, 2), 1);
        var lon = Math.Round(Math.Round(longitude, 2), 1);
        return (lat == 0 ? 0 : lat, Math.Abs(lat) == 90 || lon == 0 ? 0 : lon == 180 ? -180 : lon);
    }

    internal static CloudForecast Parse(JsonElement root)
    {
        var properties = root.GetProperty("properties");
        var updated = properties.GetProperty("meta").GetProperty("updated_at").GetDateTimeOffset().ToUniversalTime();
        Dictionary<DateTimeOffset, ForecastHour> hours = [];
        foreach (var item in properties.GetProperty("timeseries").EnumerateArray())
        {
            var date = item.GetProperty("time").GetDateTimeOffset().ToUniversalTime();
            if (date.Minute != 0 || date.Second != 0 || !item.GetProperty("data").TryGetProperty("instant", out var instant)
                || !instant.TryGetProperty("details", out var details) || Percent(details, "cloud_area_fraction") is not { } cloud)
                continue;
            hours.TryAdd(date, new(date, cloud, Percent(details, "fog_area_fraction"),
                Percent(details, "cloud_area_fraction_low"), Percent(details, "cloud_area_fraction_medium"),
                Percent(details, "cloud_area_fraction_high")));
        }
        return new(updated, hours.Values.OrderBy(h => h.InstantUtc).ToArray());
    }

    private static double? Percent(JsonElement details, string key) =>
        details.TryGetProperty(key, out var value) && value.ValueKind == JsonValueKind.Number &&
        value.TryGetDouble(out var result) && result is >= 0 and <= 100 ? result : null;

    private sealed record Cached(CloudForecast? Forecast, DateTimeOffset? LastModifiedUtc, DateTimeOffset RefreshAfterUtc, bool Available);
}
