using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Yorungez.Identity.Application;
using Yorungez.Identity.Domain;
using Yorungez.Identity.Infrastructure.Persistence;

namespace Yorungez.Identity.Infrastructure.Security;

public sealed record JwtSettings(string Issuer, string Audience, string SigningKey,
    int AccessMinutes = 10, int RefreshDays = 7)
{
    public void Validate()
    {
        if (!Uri.TryCreate(Issuer, UriKind.Absolute, out _) || string.IsNullOrWhiteSpace(Audience)
            || Encoding.UTF8.GetByteCount(SigningKey) < 64 || SigningKey.StartsWith("replace", StringComparison.OrdinalIgnoreCase)
            || AccessMinutes is < 1 or > 30 || RefreshDays is < 1 or > 30)
            throw new InvalidOperationException("JWT configuration is missing or invalid. Supply a random signing key with at least 64 UTF-8 bytes.");
    }
}

public static class SecretHash
{
    public static string Of(string value) => Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(value)));
}

public sealed class TokenIssuer(JwtSettings settings, TimeProvider clock)
{
    public (TokenPair Pair, RefreshSession Session) Issue(Account account, Guid familyId)
    {
        var now = DateTimeOffset.FromUnixTimeSeconds(clock.GetUtcNow().ToUnixTimeSeconds());
        var expires = now.AddMinutes(settings.AccessMinutes);
        var refreshExpires = now.AddDays(settings.RefreshDays);
        var refresh = Microsoft.AspNetCore.WebUtilities.WebEncoders.Base64UrlEncode(RandomNumberGenerator.GetBytes(48));
        var stamp = SecretHash.Of(account.SecurityStamp ?? throw new InvalidOperationException("Missing account stamp."));
        var token = new JwtSecurityToken(settings.Issuer, settings.Audience,
        [
            new(JwtRegisteredClaimNames.Sub, account.Id.ToString()),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString("N")),
            new(JwtRegisteredClaimNames.Iat, now.ToUnixTimeSeconds().ToString(System.Globalization.CultureInfo.InvariantCulture), ClaimValueTypes.Integer64),
            new("sid", familyId.ToString()), new("ver", stamp)
        ], now.UtcDateTime, expires.UtcDateTime,
            new SigningCredentials(new SymmetricSecurityKey(Encoding.UTF8.GetBytes(settings.SigningKey)), SecurityAlgorithms.HmacSha256));
        return (new(new JwtSecurityTokenHandler().WriteToken(token), expires, refresh, refreshExpires),
            RefreshSession.Create(account.Id, familyId, SecretHash.Of(refresh), stamp, now, refreshExpires));
    }
}
