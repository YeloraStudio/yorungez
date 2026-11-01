namespace Yorungez.Catalog.Domain;

public sealed record CatalogStar(string Id, int? Hip, string Name, string Designation, string Constellation,
    double RaHoursJ2000, double DecDegreesJ2000, double Magnitude, double? ColorIndex,
    double? DistanceParsecs, double[] PositionPc, double[] VelocityPcPerYear,
    double PmRaMasPerYear, double PmDecMasPerYear, double? RadialVelocityKmPerSecond, string Inclusion);
public sealed record CatalogConstellation(string Id, string Iau, Dictionary<string, string> Names, string[][] Lines);
public sealed record SkyCatalog(int SchemaVersion, string Version, string Epoch,
    CatalogStar[] Stars, CatalogConstellation[] Constellations);
public sealed record CatalogSource(string Url, string Sha256);
public sealed record CatalogProvenance(string Version, string DerivedSha256, int StarCount, int BrightCount,
    int ConstellationCount, CatalogSource[] Sources, Dictionary<string, string> Attribution, string[] Limitations);
public sealed record SkyCatalogSnapshot(SkyCatalog Catalog, CatalogProvenance Provenance);
