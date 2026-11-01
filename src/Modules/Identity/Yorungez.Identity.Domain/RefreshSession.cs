namespace Yorungez.Identity.Domain;

public sealed class RefreshSession
{
    public Guid Id { get; private set; } = Guid.NewGuid();
    public Guid UserId { get; private set; }
    public Guid FamilyId { get; private set; }
    public string TokenHash { get; private set; } = "";
    public string SecurityStampHash { get; private set; } = "";
    public DateTimeOffset CreatedAt { get; private set; }
    public DateTimeOffset ExpiresAt { get; private set; }
    public DateTimeOffset? ConsumedAt { get; private set; }
    public DateTimeOffset? RevokedAt { get; private set; }
    public Guid Version { get; private set; } = Guid.NewGuid();

    private RefreshSession() { }

    public static RefreshSession Create(Guid user, Guid family, string tokenHash, string stampHash,
        DateTimeOffset now, DateTimeOffset expires)
    {
        if (user == Guid.Empty || family == Guid.Empty || expires <= now
            || tokenHash.Length != 64 || stampHash.Length != 64)
            throw new ArgumentException("Invalid refresh session.");
        return new() { UserId = user, FamilyId = family, TokenHash = tokenHash,
            SecurityStampHash = stampHash, CreatedAt = now, ExpiresAt = expires };
    }

    public void Consume(DateTimeOffset now)
    {
        if (ConsumedAt is not null || RevokedAt is not null || ExpiresAt <= now)
            throw new InvalidOperationException("Session cannot be consumed.");
        ConsumedAt = now;
        Version = Guid.NewGuid();
    }

    public void Revoke(DateTimeOffset now) { RevokedAt = now; Version = Guid.NewGuid(); }
}
