using System.Text.Json;
using Microsoft.Extensions.Caching.Distributed;
using Microsoft.Extensions.Logging;
using Yorungez.Catalog.Application;
using Yorungez.Catalog.Domain;

namespace Yorungez.Catalog.Infrastructure;

public sealed class GlossaryRepository(IDistributedCache cache, ILogger<GlossaryRepository> logger) : IGlossaryRepository
{
    public const string DataVersion = "2026-10-31.7";
    private static readonly JsonSerializerOptions Json = new(JsonSerializerDefaults.Web);
    private static readonly Lazy<GlossaryTerm[]> Seed = new(Load);

    public async Task<IReadOnlyList<GlossaryTerm>> GetAllAsync(CancellationToken ct)
    {
        var seed = Seed.Value; // Always validate the shipped bilingual source, including on a cache hit.
        var key = $"catalog:glossary:{DataVersion}";
        try
        {
            var cached = await cache.GetStringAsync(key, ct);
            if (cached is not null)
            {
                var terms = JsonSerializer.Deserialize<GlossaryTerm[]>(cached, Json);
                if (terms is not null && Complete(terms)) return terms;
            }
            await cache.SetStringAsync(key, JsonSerializer.Serialize(seed, Json),
                new DistributedCacheEntryOptions { AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(30) }, ct);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            logger.LogWarning("Glossary cache unavailable ({ExceptionType}); using curated source.", ex.GetType().Name);
        }
        return seed;
    }

    private static GlossaryTerm[] Load()
    {
        using var stream = typeof(GlossaryRepository).Assembly.GetManifestResourceStream(
            "Yorungez.Catalog.Infrastructure.Data.glossary.json")
            ?? throw new InvalidOperationException("Glossary resource missing.");
        var terms = JsonSerializer.Deserialize<GlossaryTerm[]>(stream, Json)!;
        if (!Complete(terms)) throw new InvalidOperationException("Glossary requires complete tr/en definitions and sources.");
        return terms;
    }

    private static bool Complete(GlossaryTerm[] terms) => terms.Length > 0
        && terms.Select(t => t.Id).Distinct(StringComparer.Ordinal).Count() == terms.Length
        && terms.All(t => t.Sources.Length > 0 && new[] { "tr", "en" }.All(l =>
            t.Translations.TryGetValue(l, out var v) && !string.IsNullOrWhiteSpace(v.Name)
            && !string.IsNullOrWhiteSpace(v.Definition)));
}
