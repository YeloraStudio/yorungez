namespace Yorungez.Catalog.Domain;

public sealed record DeepSkyObject(string Id, string Name, string Designation, string[] Aliases, string Type,
    double RaHoursJ2000, double DecDegreesJ2000, double? Magnitude, double? MajorArcminutes);
public sealed record ArtAnchorStar(string Id, double RaHoursJ2000, double DecDegreesJ2000,
    double[] PositionPc, double[] VelocityPcPerYear);
public sealed record ArtAnchor(double X, double Y, ArtAnchorStar Star);
public sealed record ConstellationArtwork(string Id, string Src, int[] Size, int[] Anchors);
public sealed record ConstellationArtCatalog(ConstellationArtwork[] Figures, ArtAnchor[] Anchors);
public sealed record SkyOverlays(int SchemaVersion, DeepSkyObject[] DeepSky, ConstellationArtCatalog Art);
public sealed record OverlayProvenance(string Sha256, int DeepSkyCount, int ArtCount, Dictionary<string, string> Attribution, CatalogSource[] Sources);
public sealed record SkyOverlaySnapshot(SkyOverlays Overlays, OverlayProvenance Provenance);
