using Microsoft.AspNetCore.WebUtilities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using Yorungez.Identity.Application;
using Yorungez.Identity.Infrastructure.Persistence;
using Yorungez.Identity.Infrastructure.Security;

namespace Yorungez.Api.Tests;

[Trait("Category", "Integration")]
public sealed class IdentityFlowTests(AppFactory app) : IClassFixture<AppFactory>
{
    private const string Password = "a long original astronomy passphrase";
    private sealed record Verification(Guid UserId, string Token);

    private static async Task<TokenPair> Login(HttpClient client, string address, string password = Password)
    {
        client.DefaultRequestHeaders.Authorization = null;
        var response = await client.PostAsJsonAsync("/api/v1/auth/login", new { email = address, password });
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        return (await response.Content.ReadFromJsonAsync<TokenPair>())!;
    }

    private async Task<(string Address, Verification Verify)> Register(HttpClient client)
    {
        var address = "test-" + Guid.NewGuid().ToString("N") + "@example.invalid";
        var response = await client.PostAsJsonAsync("/api/v1/auth/register", new { firstName = "Public", lastName = "Tester", email = address, password = Password });
        Assert.Equal(HttpStatusCode.Accepted, response.StatusCode);
        Assert.False((await response.Content.ReadAsStringAsync()).Contains("accessToken", StringComparison.Ordinal));
        await app.DispatchAsync();
        var mail = app.Email.Messages.Last(m => m.Recipient == address);
        return (address, ReadVerification(mail));
    }

    private static Verification ReadVerification(EmailMessage message)
    {
        var link = new Uri(message.Body.Split('\n', StringSplitOptions.RemoveEmptyEntries).Last());
        Assert.Empty(link.Query); // Credentials are kept out of the URL query sent to servers.
        var values = QueryHelpers.ParseQuery(link.Fragment.TrimStart('#'));
        return new(Guid.Parse(values["userId"].ToString()), values["token"].ToString());
    }

    private async Task<string> Confirmed(HttpClient client)
    {
        var (address, verification) = await Register(client);
        Assert.Equal(HttpStatusCode.OK, (await client.PostAsJsonAsync("/api/v1/auth/confirm-email", verification)).StatusCode);
        return address;
    }

    [Theory]
    [InlineData(null, "Tester")]
    [InlineData("", "Tester")]
    [InlineData("Public", " ")]
    [InlineData("Public\nName", "Tester")]
    public async Task Registration_requires_both_names_without_control_characters(string? firstName, string? lastName)
    {
        using var client = app.Client();
        var response = await client.PostAsJsonAsync("/api/v1/auth/register", new { firstName, lastName, email = Guid.NewGuid()+"@example.invalid", password=Password });
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        Assert.Equal("Identity.InvalidName", (await response.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("code").GetString());
    }

    [Fact]
    public async Task Profile_names_survive_login_and_updates_are_scoped_to_the_signed_in_account()
    {
        using var client = app.Client();var address=await Confirmed(client);var pair=await Login(client,address);
        client.DefaultRequestHeaders.Authorization=new AuthenticationHeaderValue("Bearer",pair.AccessToken);
        var before=await client.GetFromJsonAsync<UserProfile>("/api/v1/auth/me");
        Assert.Equal("Public",before!.FirstName);Assert.Equal("Tester",before.LastName);
        var saved=await client.PostAsJsonAsync("/api/v1/auth/profile",new {firstName="  Çağrı  ",lastName="Yılmaz"});
        Assert.Equal(HttpStatusCode.OK,saved.StatusCode);
        var after=await saved.Content.ReadFromJsonAsync<UserProfile>();Assert.Equal("Çağrı",after!.FirstName);Assert.Equal("Yılmaz",after.LastName);
        client.DefaultRequestHeaders.Add("X-Yorungez-Account",Guid.NewGuid().ToString());
        Assert.Equal(HttpStatusCode.Conflict,(await client.PostAsJsonAsync("/api/v1/auth/profile",new {firstName="Other",lastName="Account"})).StatusCode);
        Assert.Equal("Çağrı",(await client.GetFromJsonAsync<UserProfile>("/api/v1/auth/me"))!.FirstName);
        using var anonymous=app.Client();Assert.Equal(HttpStatusCode.Unauthorized,(await anonymous.PostAsJsonAsync("/api/v1/auth/profile",new {firstName="Public",lastName="Tester"})).StatusCode);
    }

    [Fact]
    public async Task Email_confirmation_gates_login_and_credentials_are_not_stored_in_plaintext()
    {
        using var client = app.Client("tr");
        var (address, verification) = await Register(client);
        var denied = await client.PostAsJsonAsync("/api/v1/auth/login", new { email = address, password = Password });
        Assert.Equal(HttpStatusCode.Forbidden, denied.StatusCode);
        Assert.Equal("Identity.EmailNotConfirmed", (await denied.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("code").GetString());
        var duplicate = await client.PostAsJsonAsync("/api/v1/auth/register", new { firstName = "Public", lastName = "Tester", email = address, password = Password });
        Assert.Equal(HttpStatusCode.Accepted, duplicate.StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await client.PostAsJsonAsync("/api/v1/auth/confirm-email", verification)).StatusCode);
        var pair = await Login(client, address);
        Assert.Equal(3, pair.AccessToken.Split('.').Length);
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", pair.AccessToken);
        var me = await client.GetFromJsonAsync<UserProfile>("/api/v1/auth/me");
        Assert.Equal(address, me!.Email);
        Assert.True(me.EmailConfirmed);
        await using var scope = app.Services.CreateAsyncScope();
        var store = scope.ServiceProvider.GetRequiredService<IdentityStore>();
        var user = await store.Users.SingleAsync(u => u.Id == verification.UserId);
        Assert.True(!string.IsNullOrEmpty(user.PasswordHash) && user.PasswordHash != Password);
        var session = await store.RefreshSessions.SingleAsync(s => s.UserId == user.Id);
        Assert.Equal(64, session.TokenHash.Length);
        Assert.False(session.TokenHash == pair.RefreshToken);
        var email = await store.PendingEmails.SingleAsync(e => e.UserId == user.Id);
        Assert.DoesNotContain(address, email.ProtectedPayload);
        Assert.DoesNotContain(verification.Token, email.ProtectedPayload);
        Assert.NotNull(email.SentAt);
    }

    [Fact]
    public async Task Refresh_rotates_once_and_replay_revokes_the_session_family()
    {
        using var client = app.Client();
        var address = await Confirmed(client);
        var first = await Login(client, address);
        var refreshed = await client.PostAsJsonAsync("/api/v1/auth/refresh", new { first.RefreshToken });
        Assert.Equal(HttpStatusCode.OK, refreshed.StatusCode);
        Assert.Contains("no-store", refreshed.Headers.CacheControl!.ToString());
        var second = (await refreshed.Content.ReadFromJsonAsync<TokenPair>())!;
        Assert.True(first.RefreshToken != second.RefreshToken);
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.PostAsJsonAsync("/api/v1/auth/refresh", new { first.RefreshToken })).StatusCode);
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", second.AccessToken);
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.GetAsync("/api/v1/auth/me")).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.PostAsJsonAsync("/api/v1/auth/refresh", new { second.RefreshToken })).StatusCode);
    }

    [Fact]
    public async Task Concurrent_refresh_cannot_issue_two_successful_children()
    {
        using var client = app.Client();
        var address = await Confirmed(client);
        var first = await Login(client, address);
        var responses = await Task.WhenAll(
            client.PostAsJsonAsync("/api/v1/auth/refresh", new { first.RefreshToken }),
            client.PostAsJsonAsync("/api/v1/auth/refresh", new { first.RefreshToken }));
        Assert.Single(responses, r => r.StatusCode == HttpStatusCode.OK);
        Assert.Single(responses, r => r.StatusCode == HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task Logout_invalidates_access_and_refresh_for_that_session()
    {
        using var client = app.Client();
        var address = await Confirmed(client);
        var pair = await Login(client, address);
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", pair.AccessToken);
        Assert.Equal(HttpStatusCode.OK, (await client.PostAsync("/api/v1/auth/logout", null)).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.GetAsync("/api/v1/auth/me")).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.PostAsJsonAsync("/api/v1/auth/refresh", new { pair.RefreshToken })).StatusCode);
    }

    [Fact]
    public async Task Logout_racing_refresh_cannot_leave_a_usable_descendant_session()
    {
        using var client = app.Client();
        var address = await Confirmed(client);
        var first = await Login(client, address);
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", first.AccessToken);
        var logout = client.PostAsync("/api/v1/auth/logout", null);
        var refresh = client.PostAsJsonAsync("/api/v1/auth/refresh", new { first.RefreshToken });
        var responses = await Task.WhenAll(logout, refresh);
        using var logoutResponse = responses[0];
        using var refreshResponse = responses[1];
        Assert.Equal(HttpStatusCode.OK, logoutResponse.StatusCode);
        Assert.Contains(refreshResponse.StatusCode, new[] { HttpStatusCode.OK, HttpStatusCode.Unauthorized });
        if (refreshResponse.StatusCode == HttpStatusCode.OK)
        {
            var child = (await refreshResponse.Content.ReadFromJsonAsync<TokenPair>())!;
            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", child.AccessToken);
            Assert.Equal(HttpStatusCode.Unauthorized, (await client.GetAsync("/api/v1/auth/me")).StatusCode);
            Assert.Equal(HttpStatusCode.Unauthorized, (await client.PostAsJsonAsync("/api/v1/auth/refresh", new { child.RefreshToken })).StatusCode);
        }
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", first.AccessToken);
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.GetAsync("/api/v1/auth/me")).StatusCode);
        // Model the late-child commit deterministically as well as racing real requests.
        // A valid signature and an active child must never revive a logged-out family.
        await using var scope = app.Services.CreateAsyncScope();
        var store = scope.ServiceProvider.GetRequiredService<IdentityStore>();
        var original = new JwtSecurityTokenHandler().ReadJwtToken(first.AccessToken);
        var userId = Guid.Parse(original.Subject);
        var familyId = Guid.Parse(original.Claims.Single(c => c.Type == "sid").Value);
        var account = await store.Users.SingleAsync(u => u.Id == userId);
        var late = scope.ServiceProvider.GetRequiredService<TokenIssuer>().Issue(account, familyId);
        store.RefreshSessions.Add(late.Session);
        await store.SaveChangesAsync();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", late.Pair.AccessToken);
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.GetAsync("/api/v1/auth/me")).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.PostAsJsonAsync("/api/v1/auth/refresh",
            new { late.Pair.RefreshToken })).StatusCode);
    }

    [Fact]
    public async Task Reset_password_revokes_all_previous_sessions_and_the_link_cannot_be_reused()
    {
        using var client = app.Client("en");
        var address = await Confirmed(client);
        var pair = await Login(client, address);
        var known = await client.PostAsJsonAsync("/api/v1/auth/forgot-password", new { email = address });
        var unknown = await client.PostAsJsonAsync("/api/v1/auth/forgot-password", new { email = Guid.NewGuid() + "@example.invalid" });
        Assert.Equal(HttpStatusCode.Accepted, known.StatusCode);
        Assert.Equal(await known.Content.ReadAsStringAsync(), await unknown.Content.ReadAsStringAsync());
        await app.DispatchAsync();
        var mail = app.Email.Messages.Last(m => m.Recipient == address);
        Assert.Equal("Reset your yorungez password", mail.Subject);
        var reset = ReadVerification(mail);
        const string newPassword = "a different long lunar passphrase";
        Assert.Equal(HttpStatusCode.OK, (await client.PostAsJsonAsync("/api/v1/auth/reset-password",
            new { reset.UserId, reset.Token, password = newPassword })).StatusCode);
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", pair.AccessToken);
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.GetAsync("/api/v1/auth/me")).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.PostAsJsonAsync("/api/v1/auth/refresh", new { pair.RefreshToken })).StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, (await client.PostAsJsonAsync("/api/v1/auth/reset-password",
            new { reset.UserId, reset.Token, password = newPassword })).StatusCode);
        _ = await Login(client, address, newPassword);
    }

    [Theory]
    [InlineData("issuer")]
    [InlineData("audience")]
    [InlineData("signature")]
    [InlineData("expired")]
    public async Task JWT_validation_rejects_wrong_trust_or_expiry(string fault)
    {
        using var client = app.Client();
        var address = await Confirmed(client);
        var pair = await Login(client, address);
        var original = new JwtSecurityTokenHandler().ReadJwtToken(pair.AccessToken);
        var key = fault == "signature" ? new string('x', 88) : app.SigningKey;
        var token = new JwtSecurityToken(fault == "issuer" ? "https://other.invalid" : original.Issuer,
            fault == "audience" ? "other-api" : "yorungez-tests",
            original.Claims.Where(c => c.Type is not ("iss" or "aud" or "nbf" or "exp")),
            DateTime.UtcNow.AddHours(-1), fault == "expired" ? DateTime.UtcNow.AddMinutes(-1) : DateTime.UtcNow.AddMinutes(5),
            new SigningCredentials(new SymmetricSecurityKey(Encoding.UTF8.GetBytes(key)), SecurityAlgorithms.HmacSha256));
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", new JwtSecurityTokenHandler().WriteToken(token));
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.GetAsync("/api/v1/auth/me")).StatusCode);
    }

    [Theory]
    [InlineData("tr", "Geçerli bir e-posta adresi gir.")]
    [InlineData("en", "Enter a valid email address.")]
    public async Task Input_errors_are_bilingual_and_do_not_echo_sensitive_input(string language, string expected)
    {
        using var client = app.Client(language);
        var response = await client.PostAsJsonAsync("/api/v1/auth/register", new { firstName = "Public", lastName = "Tester", email = "not-an-email", password = Password });
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        var text = await response.Content.ReadAsStringAsync();
        var body = JsonSerializer.Deserialize<JsonElement>(text);
        Assert.Equal(expected, body.GetProperty("detail").GetString());
        Assert.DoesNotContain(Password, text);
        Assert.DoesNotContain("not-an-email", text);
    }

    [Fact]
    public async Task Delivery_failure_keeps_encrypted_outbox_work_for_retry()
    {
        using var client = app.Client();
        var address = "retry-" + Guid.NewGuid().ToString("N") + "@example.invalid";
        app.Email.FailNext = true;
        Assert.Equal(HttpStatusCode.Accepted, (await client.PostAsJsonAsync("/api/v1/auth/register", new { firstName = "Public", lastName = "Tester", email = address, password = Password })).StatusCode);
        await app.DispatchAsync();
        await using (var scope = app.Services.CreateAsyncScope())
        {
            var store = scope.ServiceProvider.GetRequiredService<IdentityStore>();
            var user = await store.Users.SingleAsync(u => u.Email == address);
            var row = await store.PendingEmails.SingleAsync(e => e.UserId == user.Id);
            Assert.Null(row.SentAt);
            Assert.Equal(1, row.Attempts);
            row.NextAttemptAt = DateTimeOffset.UtcNow.AddSeconds(-1);
            await store.SaveChangesAsync();
        }
        await app.DispatchAsync();
        Assert.Single(app.Email.Messages, m => m.Recipient == address);
    }
}
