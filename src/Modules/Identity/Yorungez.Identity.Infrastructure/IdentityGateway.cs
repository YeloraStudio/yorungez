using Microsoft.AspNetCore.DataProtection;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using System.Text.Json;
using Yorungez.Application;
using Yorungez.Identity.Application;
using Yorungez.Identity.Infrastructure.Persistence;
using Yorungez.Identity.Infrastructure.Security;

namespace Yorungez.Identity.Infrastructure;

public sealed class IdentityGateway(IdentityStore store, UserManager<Account> users, TokenIssuer tokens,
    IDataProtectionProvider protection, EmailSettings email, TimeProvider clock) : IIdentityGateway
{
    private static readonly Lazy<string> DummyHash = new(() => new PasswordHasher<Account>(
        Microsoft.Extensions.Options.Options.Create(new PasswordHasherOptions { IterationCount = 210000 }))
        .HashPassword(new Account(), "unrelated-dummy-password-for-timing"));
    private readonly IDataProtector _protector = protection.CreateProtector("yorungez.identity.email-outbox.v1");

    public async Task RegisterAsync(RegisterCommand command, CancellationToken ct)
    {
        var address = command.Email.Trim();
        if (await users.FindByEmailAsync(address) is not null) return;
        await using var transaction = await store.Database.BeginTransactionAsync(ct);
        var account = new Account { Id = Guid.NewGuid(), UserName = address, Email = address, FirstName = command.FirstName!.Trim(), LastName = command.LastName!.Trim(), PreferredLanguage = command.Language is "tr" ? "tr" : "en" };
        var result = await users.CreateAsync(account, command.Password);
        if (!result.Succeeded)
        {
            if (result.Errors.All(e => e.Code is "DuplicateEmail" or "DuplicateUserName")) return;
            throw new AppFailure("Identity.InvalidInput", FailureKind.Validation);
        }
        await QueueConfirmation(account, command.Language, ct);
        await store.SaveChangesAsync(ct);
        await transaction.CommitAsync(ct);
    }

    public async Task ConfirmEmailAsync(ConfirmEmailCommand command, CancellationToken ct)
    {
        var account = await users.FindByIdAsync(command.UserId.ToString());
        if (account is null || !(await users.ConfirmEmailAsync(account, command.Token)).Succeeded)
            throw InvalidToken();
    }

    public async Task<TokenPair> LoginAsync(LoginCommand command, CancellationToken ct)
    {
        var account = await LoginAccount(command.Email, command.Password);
        var issued = tokens.Issue(account, Guid.NewGuid());
        store.RefreshSessions.Add(issued.Session);
        await store.SaveChangesAsync(ct);
        return issued.Pair;
    }

    public async Task<BrowserSession> LoginBrowserAsync(BrowserLoginCommand command, CancellationToken ct)
    {
        var account = await LoginAccount(command.Email, command.Password);
        var issued = tokens.Issue(account, Guid.NewGuid());
        store.RefreshSessions.Add(issued.Session);
        await store.SaveChangesAsync(ct);
        // Browser receives only a DataProtection cookie; JWT/refresh secrets stay server-side.
        return new(account.Id, issued.Session.FamilyId, issued.Session.SecurityStampHash, issued.Session.ExpiresAt);
    }

    private async Task<Account> LoginAccount(string emailAddress, string password)
    {
        var account = await CheckCredentials(emailAddress, password);
        if (!account.EmailConfirmed) throw new AppFailure("Identity.EmailNotConfirmed", FailureKind.Forbidden);
        await users.ResetAccessFailedCountAsync(account);
        return account;
    }

    private async Task<Account> CheckCredentials(string emailAddress, string password)
    {
        var account = await users.FindByEmailAsync(emailAddress.Trim());
        if (account is null)
        {
            _ = new PasswordHasher<Account>().VerifyHashedPassword(new Account(), DummyHash.Value, password);
            throw InvalidCredentials();
        }
        if (await users.IsLockedOutAsync(account)) throw InvalidCredentials();
        if (!await users.CheckPasswordAsync(account, password))
        {
            await users.AccessFailedAsync(account);
            throw InvalidCredentials();
        }
        return account;
    }

    public async Task DeleteAccountAsync(DeleteAccountCommand command, CancellationToken ct)
    {
        var account = await CheckCredentials(command.Email, command.Password);
        ct.ThrowIfCancellationRequested();
        // PostgreSQL cascades the delete atomically to every owned row, including notebook data.
        if (!(await users.DeleteAsync(account)).Succeeded)
            throw new AppFailure("Common.Conflict", FailureKind.Conflict);
    }

    public async Task<TokenPair> RefreshAsync(RefreshCommand command, CancellationToken ct)
    {
        var hash = SecretHash.Of(command.RefreshToken);
        var session = await store.RefreshSessions.SingleOrDefaultAsync(s => s.TokenHash == hash, ct);
        var now = clock.GetUtcNow();
        if (session is null) throw InvalidCredentials();
        if (await FamilyIsRevoked(session.UserId, session.FamilyId, ct)) throw InvalidCredentials();
        if (session.ConsumedAt is not null)
        {
            await RevokeFamily(session.UserId, session.FamilyId, ct);
            throw InvalidCredentials();
        }
        if (session.RevokedAt is not null || session.ExpiresAt <= now) throw InvalidCredentials();
        var account = await users.FindByIdAsync(session.UserId.ToString());
        if (account is null || !account.EmailConfirmed
            || SecretHash.Of(account.SecurityStamp ?? "") != session.SecurityStampHash) throw InvalidCredentials();
        session.Consume(now);
        var issued = tokens.Issue(account, session.FamilyId);
        store.RefreshSessions.Add(issued.Session);
        try { await store.SaveChangesAsync(ct); }
        catch (DbUpdateConcurrencyException) { throw InvalidCredentials(); }
        return issued.Pair;
    }

    public Task LogoutAsync(LogoutCommand command, CancellationToken ct) => RevokeFamily(command.UserId, command.FamilyId, ct);

    public async Task ResendConfirmationAsync(ResendConfirmationCommand command, CancellationToken ct)
    {
        var account = await users.FindByEmailAsync(command.Email.Trim());
        if (account is null || account.EmailConfirmed || await RecentlyQueued(account.Id, "confirmation", ct)) return;
        await QueueConfirmation(account, command.Language, ct);
        await store.SaveChangesAsync(ct);
    }

    public async Task ForgotPasswordAsync(ForgotPasswordCommand command, CancellationToken ct)
    {
        var account = await users.FindByEmailAsync(command.Email.Trim());
        if (account is null || !account.EmailConfirmed || await RecentlyQueued(account.Id, "reset", ct)) return;
        var token = await users.GeneratePasswordResetTokenAsync(account);
        Queue(account, "reset", command.Language, token);
        await store.SaveChangesAsync(ct);
    }

    public async Task ResetPasswordAsync(ResetPasswordCommand command, CancellationToken ct)
    {
        await using var transaction = await store.Database.BeginTransactionAsync(ct);
        var account = await users.FindByIdAsync(command.UserId.ToString());
        if (account is null || !(await users.ResetPasswordAsync(account, command.Token, command.Password)).Succeeded)
            throw InvalidToken();
        var sessions = await store.RefreshSessions.Where(s => s.UserId == account.Id && s.RevokedAt == null).ToListAsync(ct);
        foreach (var session in sessions) session.Revoke(clock.GetUtcNow());
        await store.SaveChangesAsync(ct);
        await transaction.CommitAsync(ct);
    }

    public async Task<UserProfile> SaveProfileAsync(SaveProfileCommand command, CancellationToken ct)
    {
        var user = await users.FindByIdAsync(command.UserId.ToString()) ?? throw InvalidCredentials();
        user.FirstName = command.FirstName!.Trim(); user.LastName = command.LastName!.Trim();
        if (!(await users.UpdateAsync(user)).Succeeded) throw new AppFailure("Identity.InvalidInput", FailureKind.Validation);
        return new(user.Id, user.Email!, user.EmailConfirmed, user.FirstName, user.LastName, user.PreferredLanguage);
    }

    public async Task<UserProfile> CurrentUserAsync(Guid userId, CancellationToken ct)
    {
        var user = await users.FindByIdAsync(userId.ToString()) ?? throw InvalidCredentials();
        return new(user.Id, user.Email!, user.EmailConfirmed, user.FirstName, user.LastName, user.PreferredLanguage);
    }

    public async Task<UserProfile> SaveLanguageAsync(SaveLanguageCommand command, CancellationToken ct)
    {
        var user = await users.FindByIdAsync(command.UserId.ToString()) ?? throw InvalidCredentials();
        user.PreferredLanguage = command.PreferredLanguage!;
        if (!(await users.UpdateAsync(user)).Succeeded) throw new AppFailure("Common.InvalidInput", FailureKind.Validation);
        return new(user.Id, user.Email!, user.EmailConfirmed, user.FirstName, user.LastName, user.PreferredLanguage);
    }

    public async Task<bool> ValidateSessionAsync(Guid userId, Guid familyId, string stampHash, CancellationToken ct)
    {
        var account = await users.FindByIdAsync(userId.ToString());
        if (account is null || !account.EmailConfirmed || SecretHash.Of(account.SecurityStamp ?? "") != stampHash) return false;
        if (await FamilyIsRevoked(userId, familyId, ct)) return false;
        var now = clock.GetUtcNow();
        return await store.RefreshSessions.AsNoTracking().AnyAsync(s => s.UserId == userId && s.FamilyId == familyId
            && s.RevokedAt == null && s.ExpiresAt > now, ct);
    }

    private async Task RevokeFamily(Guid userId, Guid familyId, CancellationToken ct)
    {
        var now = clock.GetUtcNow();
        var version = Guid.NewGuid();
        // A revoked member is a persistent family tombstone, including for a child
        // committed concurrently after this statement's snapshot was established.
        await store.RefreshSessions.Where(s => s.UserId == userId && s.FamilyId == familyId
            && s.RevokedAt == null).ExecuteUpdateAsync(update => update
                .SetProperty(s => s.RevokedAt, now).SetProperty(s => s.Version, version), ct);
    }

    private Task<bool> FamilyIsRevoked(Guid userId, Guid familyId, CancellationToken ct) =>
        store.RefreshSessions.AsNoTracking().AnyAsync(s => s.UserId == userId && s.FamilyId == familyId
            && s.RevokedAt != null, ct);

    private async Task QueueConfirmation(Account account, string language, CancellationToken ct)
    {
        Queue(account, "confirmation", language, await users.GenerateEmailConfirmationTokenAsync(account));
    }

    private void Queue(Account account, string kind, string language, string token)
    {
        if (language is not ("tr" or "en")) throw new AppFailure("Common.InvalidInput", FailureKind.Validation);
        var action = kind == "confirmation" ? "confirm-email" : "reset-password";
        var link = $"{email.FrontendBaseUrl.TrimEnd('/')}/en/account/{action}#userId={account.Id}&token={Uri.EscapeDataString(token)}";
        var message = AccountEmailTemplate.Create(kind, account.Email!, link);
        var now = clock.GetUtcNow();
        store.PendingEmails.Add(new PendingEmail { UserId = account.Id, Kind = kind, CreatedAt = now,
            NextAttemptAt = now, ProtectedPayload = _protector.Protect(JsonSerializer.Serialize(message)) });
    }

    private Task<bool> RecentlyQueued(Guid userId, string kind, CancellationToken ct)
    {
        var since = clock.GetUtcNow().AddMinutes(-1);
        return store.PendingEmails.AnyAsync(e => e.UserId == userId && e.Kind == kind && e.CreatedAt > since, ct);
    }

    private static AppFailure InvalidCredentials() => new("Identity.InvalidCredentials", FailureKind.Unauthorized);
    private static AppFailure InvalidToken() => new("Identity.InvalidToken", FailureKind.Validation);
}
