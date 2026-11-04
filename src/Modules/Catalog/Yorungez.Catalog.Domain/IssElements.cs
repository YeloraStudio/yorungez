namespace Yorungez.Catalog.Domain;

// Public source data only. No observer/location/account information.
public sealed record IssElements(int SchemaVersion, int NoradCatalogId, DateTimeOffset EpochUtc,
    DateTimeOffset RetrievedAtUtc, DateTimeOffset ExpiresAtUtc, string SourceUrl,
    string ReferenceFrame, string TimeSystem, string MeanElementTheory, string RawOmm, string Sha256);
