namespace Yorungez.Notebook.Domain;

// Owned entirely by Notebook. Identity is referenced by its public user ID only.
public sealed class NotebookEntry
{
    public Guid UserId { get; set; }
    public string Id { get; set; } = "";
    public string Kind { get; set; } = "";
    public long Revision { get; set; }
    public DateTimeOffset CreatedAtUtc { get; set; }
    public DateTimeOffset UpdatedAtUtc { get; set; }
    public DateTimeOffset? DeletedAtUtc { get; set; }
    public string? Body { get; set; }
    public string? TargetId { get; set; }
    public string? TargetName { get; set; }
    public DateTimeOffset? InstantUtc { get; set; }
    public DateTimeOffset? ObservedAtUtc { get; set; }
    // User declaration of occurrence; this is never an independent scientific verification.
    public bool ObservationConfirmed { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    public double? ElevationMeters { get; set; }
    public string? PlaceName { get; set; }
}
