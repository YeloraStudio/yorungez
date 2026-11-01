using System.Security.Cryptography;
using System.Text.Json;
using Yorungez.Catalog.Application;
using Yorungez.Catalog.Domain;

namespace Yorungez.Catalog.Infrastructure;

public sealed class SkyCatalogRepository : ISkyCatalogRepository
{
    private static readonly Lazy<SkyCatalogSnapshot> Snapshot = new(Load);
    public SkyCatalogSnapshot Read() => Snapshot.Value;
    private static readonly Lazy<SkyOverlaySnapshot> Overlays = new(LoadOverlays);
    public SkyOverlaySnapshot ReadOverlays() => Overlays.Value;

    private static SkyOverlaySnapshot LoadOverlays()
    {
        var assembly = typeof(SkyCatalogRepository).Assembly;
        using var stream = assembly.GetManifestResourceStream("Yorungez.Catalog.Infrastructure.Data.overlays.json")!;
        using var memory = new MemoryStream(); stream.CopyTo(memory);
        var bytes = memory.ToArray();
        using var manifest = assembly.GetManifestResourceStream("Yorungez.Catalog.Infrastructure.Data.overlays-manifest.json")!;
        var json = new JsonSerializerOptions(JsonSerializerDefaults.Web);
        var provenance = JsonSerializer.Deserialize<OverlayProvenance>(manifest, json)!;
        if (Convert.ToHexStringLower(SHA256.HashData(bytes)) != provenance.Sha256)
            throw new InvalidOperationException("Sky overlay catalogue fingerprint mismatch.");
        var overlays = JsonSerializer.Deserialize<SkyOverlays>(bytes, json)!;
        if (overlays.DeepSky.Length != provenance.DeepSkyCount || overlays.Art.Figures.Length != provenance.ArtCount
            || overlays.DeepSky.Select(o => o.Id).Distinct().Count() != overlays.DeepSky.Length
            || overlays.DeepSky.Any(o => !double.IsFinite(o.RaHoursJ2000) || o.RaHoursJ2000 is < 0 or >= 24
                || !double.IsFinite(o.DecDegreesJ2000) || o.DecDegreesJ2000 is < -90 or > 90)
            || overlays.Art.Figures.Any(f => f.Anchors.Length != 3 || f.Size.Length != 2
                || f.Anchors.Any(i => i < 0 || i >= overlays.Art.Anchors.Length)))
            throw new InvalidOperationException("Invalid sky overlay identities or coordinates.");
        return new(overlays, provenance);
    }

    private static SkyCatalogSnapshot Load()
    {
        var assembly = typeof(SkyCatalogRepository).Assembly;
        using var stream = assembly.GetManifestResourceStream("Yorungez.Catalog.Infrastructure.Data.bright-sky.json")
            ?? throw new InvalidOperationException("Sky catalogue resource missing.");
        using var memory = new MemoryStream();
        stream.CopyTo(memory);
        var bytes = memory.ToArray();
        using var source = assembly.GetManifestResourceStream("Yorungez.Catalog.Infrastructure.Data.catalog-manifest.json")
            ?? throw new InvalidOperationException("Sky provenance resource missing.");
        var json = new JsonSerializerOptions(JsonSerializerDefaults.Web);
        var provenance = JsonSerializer.Deserialize<CatalogProvenance>(source, json)!;
        if (!string.Equals(Convert.ToHexStringLower(SHA256.HashData(bytes)), provenance.DerivedSha256, StringComparison.Ordinal))
            throw new InvalidOperationException("Sky catalogue does not match recorded provenance.");
        var catalog = JsonSerializer.Deserialize<SkyCatalog>(bytes, json)!;
        var ids = catalog.Stars.Select(s => s.Id).ToHashSet(StringComparer.Ordinal);
        if (ids.Count != catalog.Stars.Length || catalog.Stars.Length != provenance.StarCount
            || catalog.Constellations.Length != 88 || catalog.Constellations.Select(c => c.Id).Distinct().Count() != 88
            || catalog.Stars.Any(s => !double.IsFinite(s.RaHoursJ2000) || !double.IsFinite(s.DecDegreesJ2000)
                || s.RaHoursJ2000 is < 0 or >= 24 || s.DecDegreesJ2000 is < -90 or > 90
                || s.PositionPc.Length != 3 || s.VelocityPcPerYear.Length != 3
                || s.PositionPc.Concat(s.VelocityPcPerYear).Any(n => !double.IsFinite(n))
                || s.DistanceParsecs is <= 0 or >= 100000)
            || catalog.Constellations.Any(c => !c.Names.ContainsKey("tr") || !c.Names.ContainsKey("en")
                || c.Lines.SelectMany(l => l).Any(id => !ids.Contains(id))))
            throw new InvalidOperationException("Sky catalogue identities or coordinates are invalid.");
        return new(catalog, provenance);
    }
}
