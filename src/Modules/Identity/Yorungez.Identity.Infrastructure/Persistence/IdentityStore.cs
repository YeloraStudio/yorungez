using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Yorungez.Identity.Domain;

namespace Yorungez.Identity.Infrastructure.Persistence;

public sealed class Account : IdentityUser<Guid>
{
    public string? FirstName { get; set; }
    public string? LastName { get; set; }
    public string PreferredLanguage { get; set; } = "en";
}

public sealed class PendingEmail
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public string Kind { get; set; } = "";
    public string ProtectedPayload { get; set; } = "";
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset NextAttemptAt { get; set; }
    public DateTimeOffset? SentAt { get; set; }
    public DateTimeOffset? LeaseUntil { get; set; }
    public int Attempts { get; set; }
    public Guid Version { get; set; } = Guid.NewGuid();
}

public sealed class AccountExplorationPreferences
{
    public Guid UserId { get; set; }
    public bool MusicEnabled { get; set; } = true;
    public string SkyLayersJson { get; set; } = "[]";
    public long Revision { get; set; }
}

public sealed class IdentityStore(DbContextOptions<IdentityStore> options)
    : IdentityDbContext<Account, IdentityRole<Guid>, Guid>(options)
{
    public DbSet<RefreshSession> RefreshSessions => Set<RefreshSession>();
    public DbSet<PendingEmail> PendingEmails => Set<PendingEmail>();
    public DbSet<AccountExplorationPreferences> ExplorationPreferences => Set<AccountExplorationPreferences>();

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);
        builder.HasDefaultSchema("identity");
        builder.Entity<Account>(b => { b.Property(a => a.FirstName).HasMaxLength(100); b.Property(a => a.LastName).HasMaxLength(100);
            b.Property(a => a.PreferredLanguage).HasMaxLength(2).IsRequired().HasDefaultValue("en"); });
        builder.Entity<AccountExplorationPreferences>(b =>
        {
            b.ToTable("ExplorationPreferences");
            b.HasKey(p => p.UserId);
            b.Property(p => p.SkyLayersJson).HasColumnType("jsonb").IsRequired();
            b.Property(p => p.Revision).IsConcurrencyToken();
            b.HasOne<Account>().WithOne().HasForeignKey<AccountExplorationPreferences>(p => p.UserId).OnDelete(DeleteBehavior.Cascade);
        });
        builder.Entity<RefreshSession>(b =>
        {
            b.ToTable("RefreshSessions");
            b.HasKey(t => t.Id);
            b.Property(t => t.TokenHash).HasMaxLength(64).IsRequired();
            b.Property(t => t.SecurityStampHash).HasMaxLength(64).IsRequired();
            b.HasIndex(t => t.TokenHash).IsUnique();
            b.HasIndex(t => new { t.UserId, t.FamilyId });
            b.Property(t => t.Version).IsConcurrencyToken();
            b.HasOne<Account>().WithMany().HasForeignKey(t => t.UserId).OnDelete(DeleteBehavior.Cascade);
        });
        builder.Entity<PendingEmail>(b =>
        {
            b.ToTable("EmailOutbox");
            b.HasKey(e => e.Id);
            b.Property(e => e.Kind).HasMaxLength(32).IsRequired();
            b.Property(e => e.ProtectedPayload).IsRequired();
            b.Property(e => e.Version).IsConcurrencyToken();
            b.HasIndex(e => new { e.SentAt, e.NextAttemptAt });
            b.HasIndex(e => new { e.UserId, e.Kind, e.CreatedAt });
            b.HasOne<Account>().WithMany().HasForeignKey(e => e.UserId).OnDelete(DeleteBehavior.Cascade);
        });
    }
}

// Schema generation does not connect to or modify this design-time database.
public sealed class DesignTimeStoreFactory : IDesignTimeDbContextFactory<IdentityStore>
{
    public IdentityStore CreateDbContext(string[] args) => new(new DbContextOptionsBuilder<IdentityStore>()
        .UseNpgsql("Host=localhost;Database=yorungez_design", o =>
            o.MigrationsHistoryTable("__EFMigrationsHistory", "identity")).Options);
}
