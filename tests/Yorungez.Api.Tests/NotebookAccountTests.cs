using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.WebUtilities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Yorungez.Identity.Application;
using Yorungez.Identity.Infrastructure.Persistence;
using Yorungez.Notebook.Application;
using Yorungez.Notebook.Infrastructure;

namespace Yorungez.Api.Tests;

public sealed class NotebookAccountTests(AppFactory app) : IClassFixture<AppFactory>
{
    private const string Password = "A long notebook test passphrase 42!";
    private async Task<(string Email, UserProfile User)> SignIn(HttpClient client)
    {
        client.DefaultRequestHeaders.Add("Origin", "http://localhost:3000");
        client.DefaultRequestHeaders.Add("X-Yorungez-Request", "1");
        var email = $"notebook-{Guid.NewGuid():N}@example.invalid";
        Assert.Equal(HttpStatusCode.Accepted, (await client.PostAsJsonAsync("/api/v1/auth/register", new { firstName = "Public", lastName = "Tester", email, password = Password })).StatusCode);
        var pending = await client.PostAsJsonAsync("/api/v1/session/login", new { email, password = Password });
        Assert.Equal(HttpStatusCode.Forbidden, pending.StatusCode);
        await app.DispatchAsync();
        var link = new Uri(app.Email.Messages.Last(m => m.Recipient == email).Body.Split('\n', StringSplitOptions.RemoveEmptyEntries).Last());
        var fragment = QueryHelpers.ParseQuery(link.Fragment.TrimStart('#'));
        Assert.Equal(HttpStatusCode.OK, (await client.PostAsJsonAsync("/api/v1/auth/confirm-email", new { userId = fragment["userId"].ToString(), token = fragment["token"].ToString() })).StatusCode);
        var login = await client.PostAsJsonAsync("/api/v1/session/login", new { email, password = Password });
        Assert.Equal(HttpStatusCode.OK, login.StatusCode);
        var cookie = login.Headers.GetValues("Set-Cookie").Single();
        Assert.Contains("httponly", cookie, StringComparison.OrdinalIgnoreCase);
        Assert.Contains("samesite=strict", cookie, StringComparison.OrdinalIgnoreCase);
        Assert.Contains("secure", cookie, StringComparison.OrdinalIgnoreCase);
        var body = await login.Content.ReadAsStringAsync();
        Assert.DoesNotContain("accessToken", body); Assert.DoesNotContain("refreshToken", body);
        return (email, (await login.Content.ReadFromJsonAsync<UserProfile>())!);
    }
    private static EntryInput Note(string? id = null, long revision = 0, string body = "Public test note") =>
        new(id ?? Guid.NewGuid().ToString(), "note", revision, body, null, null, null);

    [Fact]
    public async Task Account_deletion_requires_the_password_and_cascades_only_to_the_owner()
    {
        using var client = app.Client();
        var (email, owner) = await SignIn(client);
        using var otherClient = app.Client();
        var (_, other) = await SignIn(otherClient);
        Assert.Equal(HttpStatusCode.OK, (await client.PostAsJsonAsync("/api/v1/notebook/", Place())).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await otherClient.PostAsJsonAsync("/api/v1/notebook/", Note())).StatusCode);
        var reminder = new ReminderInput(Guid.NewGuid(), 0, null, "jupiter", DateTimeOffset.UtcNow.AddDays(1), "Europe/Istanbul", 30);
        Assert.Equal(HttpStatusCode.OK, (await client.PostAsJsonAsync("/api/v1/notebook/reminders", reminder)).StatusCode);
        var login = await client.PostAsJsonAsync("/api/v1/auth/login", new { email, password = Password });
        Assert.Equal(HttpStatusCode.OK, login.StatusCode);
        var tokens = (await login.Content.ReadFromJsonAsync<TokenPair>())!;

        using var deletion = app.Client();
        var path = "/api/v1/auth/delete-account";
        Assert.Equal(HttpStatusCode.Unauthorized, (await deletion.PostAsJsonAsync(path, new { email, password = "incorrect" })).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await client.GetAsync("/api/v1/auth/me")).StatusCode);
        var result = await deletion.PostAsJsonAsync(path, new { email, password = Password });
        Assert.Equal(HttpStatusCode.OK, result.StatusCode);
        Assert.True(result.Headers.CacheControl?.NoStore);
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.GetAsync("/api/v1/auth/me")).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await deletion.PostAsJsonAsync("/api/v1/auth/refresh", new { tokens.RefreshToken })).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await otherClient.GetAsync("/api/v1/auth/me")).StatusCode);

        await using var scope = app.Services.CreateAsyncScope();
        var identity = scope.ServiceProvider.GetRequiredService<IdentityStore>();
        Assert.False(await identity.Users.AnyAsync(a => a.Id == owner.Id));
        Assert.False(await identity.RefreshSessions.AnyAsync(s => s.UserId == owner.Id));
        Assert.False(await identity.PendingEmails.AnyAsync(m => m.UserId == owner.Id));
        var notebook = scope.ServiceProvider.GetRequiredService<NotebookDatabase>();
        Assert.False(await notebook.Entries.AnyAsync(e => e.UserId == owner.Id));
        Assert.False(await notebook.Reminders.AnyAsync(e => e.UserId == owner.Id));
        Assert.True(await notebook.Entries.AnyAsync(e => e.UserId == other.Id));
    }

    [Fact]
    public async Task Anonymous_records_are_rejected_and_never_inserted()
    {
        using var client = app.Client();
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.GetAsync("/api/v1/notebook/")).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.PostAsJsonAsync("/api/v1/notebook/", Note())).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.PostAsJsonAsync("/api/v1/notebook/", Observation())).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.PostAsJsonAsync("/api/v1/notebook/", Place())).StatusCode);
    }

    private static EntryInput Observation() => new(Guid.NewGuid().ToString(), "observation", 0, "Public personal report", null, null, null, ObservationConfirmed: true);
    private static EntryInput Place() => new(Guid.NewGuid().ToString(), "place", 0, null, null, null, new(41.0123456789, 28.987654321, null, "Public observing spot"));

    [Fact]
    public async Task An_observation_requires_only_description_and_personal_declaration_without_inventing_time_or_location()
    {
        using var client = app.Client(); await SignIn(client);
        var response = await client.PostAsJsonAsync("/api/v1/notebook/", Observation());
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var saved = (await response.Content.ReadFromJsonAsync<EntryView>())!;
        Assert.True(saved.ObservationConfirmed); Assert.Null(saved.ObservedAtUtc); Assert.Null(saved.InstantUtc);
        Assert.Null(saved.Target); Assert.Null(saved.Location); Assert.Equal("observation", saved.Kind);
        Assert.InRange(saved.CreatedAtUtc, DateTimeOffset.UtcNow.AddMinutes(-1), DateTimeOffset.UtcNow.AddMinutes(1));
    }

    [Theory]
    [InlineData(0)] [InlineData(1)] [InlineData(2)] [InlineData(3)] [InlineData(4)] [InlineData(5)] [InlineData(6)]
    public async Task Invented_future_or_mixed_record_semantics_are_rejected(int variant)
    {
        using var client = app.Client(); await SignIn(client);
        var input = variant switch
        {
            0 => Observation() with { ObservationConfirmed = false },
            1 => Observation() with { ObservedAtUtc = DateTimeOffset.UtcNow.AddDays(1) },
            2 => Note() with { ObservedAtUtc = DateTimeOffset.UtcNow.AddDays(-1) },
            3 => Observation() with { InstantUtc = DateTimeOffset.UtcNow.AddDays(-1) },
            4 => Place() with { Location = null },
            5 => Place() with { Target = new("jupiter", "Jupiter") },
            _ => Place() with { ObservationConfirmed = true }
        };
        var response = await client.PostAsJsonAsync("/api/v1/notebook/", input);
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        var error = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(variant == 1 ? "Notebook.FutureObservation" : "Notebook.InvalidInput", error.GetProperty("code").GetString());
    }

    [Fact]
    public async Task Historical_observation_time_outside_the_sky_model_range_is_preserved_as_UTC()
    {
        using var client = app.Client(); await SignIn(client);
        var input = Observation() with { ObservedAtUtc = DateTimeOffset.Parse("1988-04-12T21:15:00+03:00") };
        var response = await client.PostAsJsonAsync("/api/v1/notebook/", input);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var saved = (await response.Content.ReadFromJsonAsync<EntryView>())!;
        Assert.Equal(DateTimeOffset.Parse("1988-04-12T18:15:00Z"), saved.ObservedAtUtc);
        Assert.Equal(TimeSpan.Zero, saved.ObservedAtUtc!.Value.Offset); Assert.Null(saved.InstantUtc);
    }

    [Fact]
    public async Task Editing_deleting_and_restoring_a_saved_place_never_rewrites_an_existing_observation_snapshot()
    {
        using var client = app.Client(); await SignIn(client); var place = Place();
        Assert.Equal(HttpStatusCode.OK, (await client.PostAsJsonAsync("/api/v1/notebook/", place)).StatusCode);
        var observation = Observation() with { Location = place.Location, ObservedAtUtc = DateTimeOffset.Parse("2020-10-30T20:00:00Z") };
        Assert.Equal(HttpStatusCode.OK, (await client.PostAsJsonAsync("/api/v1/notebook/", observation)).StatusCode);
        var changed = place with { ExpectedRevision = 1, Location = new(0, 0, 250, "Changed location") };
        Assert.Equal(HttpStatusCode.OK, (await client.PostAsJsonAsync("/api/v1/notebook/", changed)).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await client.PostAsJsonAsync("/api/v1/notebook/", changed with { ExpectedRevision = 2, Deleted = true })).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await client.PostAsJsonAsync("/api/v1/notebook/", changed with { ExpectedRevision = 3 })).StatusCode);
        var list = await client.GetFromJsonAsync<JsonElement>("/api/v1/notebook/");
        var stored = list.GetProperty("entries").EnumerateArray().Single(e => e.GetProperty("id").GetString() == observation.Id).Deserialize<EntryView>(new JsonSerializerOptions(JsonSerializerDefaults.Web))!;
        Assert.Equal(observation.Location, stored.Location); Assert.Null(stored.Location!.ElevationMeters);
        Assert.Equal(observation.ObservedAtUtc, stored.ObservedAtUtc); Assert.Equal(1, stored.Revision);
    }

    [Fact]
    public async Task Observation_concurrent_edit_and_recoverable_delete_preserve_the_winning_report()
    {
        using var client = app.Client(); await SignIn(client); var input = Observation();
        await client.PostAsJsonAsync("/api/v1/notebook/", input);
        var replies = await Task.WhenAll(client.PostAsJsonAsync("/api/v1/notebook/", input with { ExpectedRevision = 1, Body = "Observation A" }),
            client.PostAsJsonAsync("/api/v1/notebook/", input with { ExpectedRevision = 1, Body = "Observation B" }));
        Assert.Single(replies, r => r.StatusCode == HttpStatusCode.OK); Assert.Single(replies, r => r.StatusCode == HttpStatusCode.Conflict);
        var winner = (await replies.Single(r => r.IsSuccessStatusCode).Content.ReadFromJsonAsync<EntryView>())!;
        Assert.Equal(HttpStatusCode.OK, (await client.PostAsJsonAsync("/api/v1/notebook/", input with { ExpectedRevision = 2, Body = winner.Body, Deleted = true })).StatusCode);
        var restored = (await (await client.PostAsJsonAsync("/api/v1/notebook/", input with { ExpectedRevision = 3, Body = winner.Body })).Content.ReadFromJsonAsync<EntryView>())!;
        Assert.Null(restored.DeletedAtUtc); Assert.True(restored.ObservationConfirmed); Assert.Equal(winner.Body, restored.Body);
    }

    [Fact]
    public async Task A_note_cannot_be_silently_retyped_as_an_actual_observation()
    {
        using var client = app.Client(); await SignIn(client); var note = Note();
        await client.PostAsJsonAsync("/api/v1/notebook/", note);
        Assert.Equal(HttpStatusCode.Conflict, (await client.PostAsJsonAsync("/api/v1/notebook/", Observation() with { Id = note.Id, ExpectedRevision = 1 })).StatusCode);
    }

    [Theory] [InlineData("place")] [InlineData("observation")]
    public async Task New_inventory_types_are_isolated_between_accounts(string kind)
    {
        using var a = app.Client(); using var b = app.Client(); await SignIn(a); await SignIn(b);
        var input = kind == "place" ? Place() : Observation();
        Assert.Equal(HttpStatusCode.OK, (await a.PostAsJsonAsync("/api/v1/notebook/", input)).StatusCode);
        var list = await b.GetFromJsonAsync<JsonElement>("/api/v1/notebook/"); Assert.Empty(list.GetProperty("entries").EnumerateArray());
        Assert.Equal(HttpStatusCode.Conflict, (await b.PostAsJsonAsync("/api/v1/notebook/", input with { ExpectedRevision = 1 })).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await b.PostAsJsonAsync("/api/v1/notebook/", input)).StatusCode);
    }

    [Fact]
    public async Task Private_records_live_in_Postgres_and_are_visible_from_a_fresh_login_only_to_their_owner()
    {
        using var a = app.Client(); using var b = app.Client();
        var (email, owner) = await SignIn(a); var (_, other) = await SignIn(b);
        var input = Note();
        var saved = (await (await a.PostAsJsonAsync("/api/v1/notebook/", input)).Content.ReadFromJsonAsync<EntryView>())!;
        Assert.Equal(1, saved.Revision); Assert.Null(saved.Location); Assert.Null(saved.InstantUtc);
        var bRows = await b.GetFromJsonAsync<JsonElement>("/api/v1/notebook/");
        Assert.Equal(0, bRows.GetProperty("entries").GetArrayLength());
        // The same ID in another account creates its own record, never overwrites A.
        Assert.Equal(HttpStatusCode.OK, (await b.PostAsJsonAsync("/api/v1/notebook/", input with { Body = "Other owner's note" })).StatusCode);
        b.DefaultRequestHeaders.Add("X-Yorungez-Account", owner.Id.ToString());
        Assert.Equal(HttpStatusCode.Conflict, (await b.PostAsJsonAsync("/api/v1/notebook/", input with { ExpectedRevision = 1 })).StatusCode);
        using var fresh = app.Client();
        fresh.DefaultRequestHeaders.Add("Origin", "http://localhost:3000"); fresh.DefaultRequestHeaders.Add("X-Yorungez-Request", "1");
        Assert.Equal(HttpStatusCode.OK, (await fresh.PostAsJsonAsync("/api/v1/session/login", new { email, password = Password })).StatusCode);
        var response = await fresh.GetAsync("/api/v1/notebook/");
        Assert.Contains("no-store", response.Headers.CacheControl!.ToString());
        var rows = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(input.Body, rows.GetProperty("entries")[0].GetProperty("body").GetString());
        await using var scope = app.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<NotebookDatabase>();
        Assert.Equal(2, await db.Entries.CountAsync(e => e.Id == input.Id));
        Assert.Equal(input.Body, (await db.Entries.AsNoTracking().SingleAsync(e => e.UserId == owner.Id && e.Id == input.Id)).Body);
        Assert.NotEqual(owner.Id, other.Id);
    }

    [Fact]
    public async Task Concurrent_edits_use_database_revision_and_trash_restore_keeps_snapshots()
    {
        using var client = app.Client(); await SignIn(client);
        var input = Note() with { Target = new("jupiter", "Jupiter"), InstantUtc = DateTimeOffset.Parse("2026-10-31T20:00:00Z"), Location = new(41, 29, null, "Public sample") };
        Assert.Equal(HttpStatusCode.OK, (await client.PostAsJsonAsync("/api/v1/notebook/", input)).StatusCode);
        var writes = await Task.WhenAll(client.PostAsJsonAsync("/api/v1/notebook/", input with { ExpectedRevision = 1, Body = "Version A" }),
            client.PostAsJsonAsync("/api/v1/notebook/", input with { ExpectedRevision = 1, Body = "Version B" }));
        Assert.Single(writes, r => r.StatusCode == HttpStatusCode.OK); Assert.Single(writes, r => r.StatusCode == HttpStatusCode.Conflict);
        var winner = (await writes.Single(r => r.IsSuccessStatusCode).Content.ReadFromJsonAsync<EntryView>())!;
        var deleted = (await (await client.PostAsJsonAsync("/api/v1/notebook/", input with { ExpectedRevision = 2, Body = winner.Body, Deleted = true })).Content.ReadFromJsonAsync<EntryView>())!;
        Assert.NotNull(deleted.DeletedAtUtc); Assert.Equal(input.Location, deleted.Location); Assert.Equal(input.InstantUtc, deleted.InstantUtc);
        var restored = (await (await client.PostAsJsonAsync("/api/v1/notebook/", input with { ExpectedRevision = 3, Body = winner.Body })).Content.ReadFromJsonAsync<EntryView>())!;
        Assert.Null(restored.DeletedAtUtc); Assert.Equal(4, restored.Revision); Assert.Equal(winner.CreatedAtUtc, restored.CreatedAtUtc);
    }

    [Theory]
    [InlineData("tr", "Not alanlarını ve bağlı konumu kontrol et.")]
    [InlineData("en", "Check the note fields and attached location.")]
    public async Task Invalid_records_are_localized_and_never_echo_private_content(string language, string detail)
    {
        using var client = app.Client(language); await SignIn(client);
        var response = await client.PostAsJsonAsync("/api/v1/notebook/", Note() with { Location = new(91, 0, null, null), Body = "Secret text not to echo" });
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        var text = await response.Content.ReadAsStringAsync(); Assert.Contains(detail, text); Assert.DoesNotContain("Secret text not to echo", text);
    }

    [Fact]
    public async Task Same_favorite_is_unique_per_account_and_can_be_restored()
    {
        using var client = app.Client(); await SignIn(client);
        var favorite = new EntryInput("favorite:jupiter", "favorite", 0, null, new("jupiter", "Jupiter"), null, null);
        Assert.Equal(HttpStatusCode.OK, (await client.PostAsJsonAsync("/api/v1/notebook/", favorite)).StatusCode);
        Assert.Equal(HttpStatusCode.Conflict, (await client.PostAsJsonAsync("/api/v1/notebook/", favorite)).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await client.PostAsJsonAsync("/api/v1/notebook/", favorite with { ExpectedRevision = 1, Deleted = true })).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await client.PostAsJsonAsync("/api/v1/notebook/", favorite with { ExpectedRevision = 2 })).StatusCode);
        var rows = await client.GetFromJsonAsync<JsonElement>("/api/v1/notebook/");
        Assert.Equal(1, rows.GetProperty("entries").GetArrayLength());
        Assert.Equal(3, rows.GetProperty("entries")[0].GetProperty("revision").GetInt32());
        Assert.Equal(JsonValueKind.Null, rows.GetProperty("entries")[0].GetProperty("deletedAtUtc").ValueKind);
    }

    [Fact]
    public async Task Cookie_writes_require_same_origin_and_custom_header_and_logout_revokes_the_session()
    {
        using var client = app.Client(); var (email, _) = await SignIn(client);
        var login = await client.PostAsJsonAsync("/api/v1/session/login", new { email, password = Password });
        var replay = login.Headers.GetValues("Set-Cookie").Single().Split(';')[0];
        client.DefaultRequestHeaders.Remove("Origin"); client.DefaultRequestHeaders.Add("Origin", "https://attacker.invalid");
        Assert.Equal(HttpStatusCode.Forbidden, (await client.PostAsJsonAsync("/api/v1/notebook/", Note())).StatusCode);
        client.DefaultRequestHeaders.Remove("Origin"); client.DefaultRequestHeaders.Add("Origin", "http://localhost:3000");
        client.DefaultRequestHeaders.Remove("X-Yorungez-Request");
        Assert.Equal(HttpStatusCode.Forbidden, (await client.PostAsJsonAsync("/api/v1/notebook/", Note())).StatusCode);
        client.DefaultRequestHeaders.Add("X-Yorungez-Request", "1");
        Assert.Equal(HttpStatusCode.OK, (await client.PostAsJsonAsync("/api/v1/auth/logout", new { })).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.GetAsync("/api/v1/notebook/")).StatusCode);
        using var stolen = app.Client(); stolen.DefaultRequestHeaders.Add("Cookie", replay);
        Assert.Equal(HttpStatusCode.Unauthorized, (await stolen.GetAsync("/api/v1/notebook/")).StatusCode);
    }
}
