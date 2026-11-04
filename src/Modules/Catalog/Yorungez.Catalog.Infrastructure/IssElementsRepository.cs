using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Caching.Distributed;
using Yorungez.Catalog.Application;
using Yorungez.Catalog.Domain;

namespace Yorungez.Catalog.Infrastructure;

public sealed class IssElementsRepository(IHttpClientFactory clients, IDistributedCache cache, TimeProvider clock) : IIssElementsRepository, IDisposable
{
    public const string SourceUrl = "https://celestrak.org/NORAD/elements/gp.php?CATNR=25544&FORMAT=JSON";
    private const string CacheKey = "public:iss:omm:v1";
    private readonly SemaphoreSlim _gate = new(1, 1);
    private IssElements? _last;
    private DateTimeOffset _nextAttempt;
    private static readonly JsonSerializerOptions Json = new(JsonSerializerDefaults.Web);

    public async Task<IssElements?> ReadAsync(CancellationToken ct)
    {
        await _gate.WaitAsync(ct);
        try
        {
            var now = clock.GetUtcNow();
            if (_last is null)
            {
                try
                {
                    var stored = await cache.GetStringAsync(CacheKey, ct);
                    if (stored is not null)
                    {
                        var candidate = JsonSerializer.Deserialize<IssElements>(stored, Json);
                        if (candidate is not null && candidate.RetrievedAtUtc <= now && candidate.ExpiresAtUtc > now)
                            _last = Parse(candidate.RawOmm, candidate.RetrievedAtUtc, now);
                    }
                }
                catch (Exception ex) when (ex is not OperationCanceledException) { /* Public cache is optional. */ }
            }
            // CelesTrak updates GP at most every two hours. Back off equally after
            // failures/403/429; no retry loops, and one server fetch serves all users.
            if (now < _nextAttempt || (_last is not null && now - _last.RetrievedAtUtc < TimeSpan.FromHours(2)))
                return _last?.ExpiresAtUtc > now ? _last : null;
            _nextAttempt = now.AddHours(2);
            try
            {
                using var timeout = CancellationTokenSource.CreateLinkedTokenSource(ct);
                timeout.CancelAfter(TimeSpan.FromSeconds(10));
                var sourceCt = timeout.Token;
                using var response = await clients.CreateClient("CelesTrak").GetAsync(SourceUrl, HttpCompletionOption.ResponseHeadersRead, sourceCt);
                response.EnsureSuccessStatusCode();
                if (response.Content.Headers.ContentLength > 16384) throw new FormatException("Oversized public OMM.");
                await using var stream = await response.Content.ReadAsStreamAsync(sourceCt);
                using var memory = new MemoryStream();
                var buffer = new byte[2048];
                int length;
                while ((length = await stream.ReadAsync(buffer, sourceCt)) > 0)
                {
                    if (memory.Length + length > 16384) throw new FormatException("Oversized public OMM.");
                    memory.Write(buffer, 0, length);
                }
                var raw = new UTF8Encoding(false, true).GetString(memory.ToArray());
                _last = Parse(raw, now, now);
                try { await cache.SetStringAsync(CacheKey, JsonSerializer.Serialize(_last, Json),
                    new DistributedCacheEntryOptions { AbsoluteExpiration = _last.ExpiresAtUtc }, ct); }
                catch (Exception ex) when (ex is not OperationCanceledException) { /* Keep last-good in memory. */ }
            }
            catch (Exception ex) when (ex is HttpRequestException or FormatException or JsonException or DecoderFallbackException ||
                ex is OperationCanceledException && !ct.IsCancellationRequested) { /* Preserve only unexpired last-good. */ }
            return _last?.ExpiresAtUtc > now ? _last : null;
        }
        finally { _gate.Release(); }
    }

    public static IssElements Parse(string raw, DateTimeOffset retrieved, DateTimeOffset now)
    {
        if (Encoding.UTF8.GetByteCount(raw) > 16384) throw new FormatException("Oversized public OMM.");
        using var document = JsonDocument.Parse(raw, new JsonDocumentOptions { MaxDepth = 8 });
        var root = document.RootElement;
        if (root.ValueKind != JsonValueKind.Array || root.GetArrayLength() != 1) throw new FormatException("Expected one OMM.");
        var entry = root[0];
        if (entry.ValueKind != JsonValueKind.Object) throw new FormatException("Expected OMM object.");
        if (!entry.TryGetProperty("NORAD_CAT_ID", out var id) || id.ValueKind != JsonValueKind.Number || !id.TryGetInt32(out var number) || number != 25544)
            throw new FormatException("Unexpected satellite identity.");
        foreach (var (field, expected) in new[] { ("CENTER_NAME", "EARTH"), ("REF_FRAME", "TEME"), ("TIME_SYSTEM", "UTC"), ("MEAN_ELEMENT_THEORY", "SGP4") })
            if (entry.TryGetProperty(field, out var value) && (value.ValueKind != JsonValueKind.String || value.GetString() != expected)) throw new FormatException("Unsupported OMM convention.");
        if (!entry.TryGetProperty("EPOCH", out var epochValue) || epochValue.ValueKind != JsonValueKind.String || !DateTimeOffset.TryParse(epochValue.GetString(), CultureInfo.InvariantCulture,
                DateTimeStyles.AssumeUniversal | DateTimeStyles.AdjustToUniversal, out var epoch) ||
            epoch > now.AddMinutes(30) || now - epoch > TimeSpan.FromHours(72) || retrieved > now.AddMinutes(5))
            throw new FormatException("Invalid OMM epoch.");
        double Numeric(string field, double min, double max)
        {
            if (!entry.TryGetProperty(field, out var value) || value.ValueKind != JsonValueKind.Number || !value.TryGetDouble(out var result) || !double.IsFinite(result) || result < min || result > max)
                throw new FormatException("Invalid OMM element.");
            return result;
        }
        _ = Numeric("MEAN_MOTION", 10, 18); _ = Numeric("ECCENTRICITY", 0, .1); _ = Numeric("INCLINATION", 0, 180);
        foreach (var key in new[] { "RA_OF_ASC_NODE", "ARG_OF_PERICENTER", "MEAN_ANOMALY" }) _ = Numeric(key, 0, 360);
        _ = Numeric("BSTAR", -1, 1); _ = Numeric("MEAN_MOTION_DOT", -1, 1); _ = Numeric("MEAN_MOTION_DDOT", -1, 1);
        return new(1, 25544, epoch, retrieved, epoch.AddHours(72), SourceUrl, "TEME", "UTC", "SGP4", raw,
            Convert.ToHexStringLower(SHA256.HashData(Encoding.UTF8.GetBytes(raw))));
    }
    public void Dispose() => _gate.Dispose();
}
