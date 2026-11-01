namespace Yorungez.Catalog.Domain;

public sealed record CalendarFact(string Id, string Kind, string TargetId, DateTimeOffset InstantUtc,
    string SourceId, DateTimeOffset? ComputedInstantUtc, double? ReferenceDeltaSeconds,
    double? ElongationDegrees, string? Visibility);
public sealed record CalendarData(int SchemaVersion, int StartYear, int EndYear, CalendarFact[] Events);
public sealed record EventSource(string Id, string Url);
public sealed record CalendarProvenance(string Sha256, int EventCount, int PhaseReferenceCount,
    double MaxPhaseDifferenceSeconds, double ToleranceSeconds, string EngineVersion,
    string Source, EventSource[] Sources);
public sealed record CalendarMonth(int Year, int Month, CalendarFact[] Events, CalendarProvenance Provenance);
public sealed record PlacePoint(long Id, string Name, string Ascii, double Latitude, double Longitude,
    string Country, string Region, long Population, string Feature);
public sealed record LocatedPlace(PlacePoint Place, double? DistanceKm);
