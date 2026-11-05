using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.WebUtilities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging.Abstractions;
using Yorungez.Catalog.Application;
using Yorungez.Identity.Application;
using Yorungez.Notebook.Application;
using Yorungez.Notebook.Infrastructure;

namespace Yorungez.Api.Tests;

public sealed class ReminderTests(AppFactory app) : IClassFixture<AppFactory>, IAsyncLifetime
{
    public async Task InitializeAsync()
    {
        // Each case advances a synthetic scheduler clock. Do not dispatch another case's pending rows.
        // AppFactory owns a fresh, uniquely named disposable database for this test class.
        await using var scope = app.Services.CreateAsyncScope();
        await scope.ServiceProvider.GetRequiredService<NotebookDatabase>().Reminders.ExecuteDeleteAsync();
        app.Email.FailNext = false;
    }
    public Task DisposeAsync() => Task.CompletedTask;
    private const string Route = "/api/v1/notebook/reminders";
    private async Task<(Guid Id, string Email)> Login(HttpClient client)
    {
        client.DefaultRequestHeaders.Add("Origin", "http://localhost:3000");
        client.DefaultRequestHeaders.Add("X-Yorungez-Request", "1");
        var email = $"reminder-{Guid.NewGuid():N}@example.invalid";
        const string password = "A synthetic reminder passphrase 42!";
        Assert.Equal(HttpStatusCode.Accepted, (await client.PostAsJsonAsync("/api/v1/auth/register", new { email, password, firstName = "Public", lastName = "Tester" })).StatusCode);
        await app.DispatchAsync();
        var link = new Uri(app.Email.Messages.Last(m => m.Recipient == email).Body.Split('\n', StringSplitOptions.RemoveEmptyEntries).Last());
        var fragment = QueryHelpers.ParseQuery(link.Fragment.TrimStart('#'));
        Assert.Equal(HttpStatusCode.OK, (await client.PostAsJsonAsync("/api/v1/auth/confirm-email", new { userId = fragment["userId"].ToString(), token = fragment["token"].ToString() })).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await client.PostAsJsonAsync("/api/v1/session/login", new { email, password })).StatusCode);
        var user = (await client.GetFromJsonAsync<UserProfile>("/api/v1/auth/me"))!;
        return (user.Id, email);
    }
    private static ReminderInput Observing(int days = 1) => new(Guid.NewGuid(), 0, null, "jupiter", DateTimeOffset.UtcNow.AddDays(days), "Europe/Istanbul", 30);
    private static async Task<ReminderView> Save(HttpClient client, ReminderInput input)
    {
        var response = await client.PostAsJsonAsync(Route, input);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Contains("no-store", response.Headers.CacheControl!.ToString());
        return (await response.Content.ReadFromJsonAsync<ReminderView>())!;
    }
    private async Task<int> Dispatch(DateTimeOffset now)
    {
        await using var scope = app.Services.CreateAsyncScope();
        return await new ReminderDispatcher(scope.ServiceProvider.GetRequiredService<NotebookDatabase>(),
            scope.ServiceProvider.GetServices<IReminderChannel>(), new FixedClock(now), NullLogger<ReminderDispatcher>.Instance).DispatchOnceAsync(default);
    }
    [Fact]
    public async Task Anonymous_cannot_read_schedule_or_get_private_capabilities()
    {
        using var client = app.Client();
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.GetAsync(Route)).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.PostAsJsonAsync(Route, Observing())).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.GetAsync("/api/v1/notebook/notification-capabilities")).StatusCode);
    }
    [Fact]
    public async Task Persisted_private_reminders_keep_UTC_and_zone_and_report_push_unavailable()
    {
        using var client = app.Client(); var owner = await Login(client);
        var input = Observing(); var saved = await Save(client, input);
        Assert.Equal(input.InstantUtc, saved.InstantUtc); Assert.Equal("Europe/Istanbul", saved.TimeZoneId);
        Assert.Equal(input.InstantUtc!.Value.AddMinutes(-30), saved.DueAtUtc);
        Assert.Equal("scheduled", saved.Status); Assert.Equal("email", saved.Channel);
        Assert.Contains("Observing time", saved.Title);
        var list = await client.GetFromJsonAsync<JsonElement>(Route);
        Assert.Equal(owner.Id, list.GetProperty("userId").GetGuid());
        Assert.Contains(list.GetProperty("reminders").EnumerateArray(), r => r.GetProperty("id").GetGuid() == saved.Id);
        var capabilities = await client.GetFromJsonAsync<JsonElement>("/api/v1/notebook/notification-capabilities");
        Assert.True(capabilities.GetProperty("email").GetBoolean()); Assert.False(capabilities.GetProperty("push").GetBoolean());
    }
    [Fact]
    public async Task Another_account_cannot_read_cancel_or_overwrite_a_reminder()
    {
        using var a = app.Client(); var owner = await Login(a); var input = Observing(); var saved = await Save(a, input);
        using var b = app.Client(); await Login(b);
        var list = await b.GetFromJsonAsync<JsonElement>(Route); Assert.Empty(list.GetProperty("reminders").EnumerateArray());
        Assert.Equal(HttpStatusCode.Conflict, (await b.PostAsJsonAsync(Route, input with { ExpectedRevision = saved.Revision, Cancelled = true })).StatusCode);
        b.DefaultRequestHeaders.Add("X-Yorungez-Account", owner.Id.ToString());
        Assert.Equal(HttpStatusCode.Conflict, (await b.PostAsJsonAsync(Route, Observing())).StatusCode);
        await Save(a, input with { ExpectedRevision = saved.Revision, Cancelled = true });
    }
    [Fact]
    public async Task Canonical_calendar_facts_are_resolved_server_side_and_tampering_is_rejected()
    {
        using var client = app.Client(); await Login(client);
        var month = DateTimeOffset.UtcNow.AddMonths(2);
        var catalog = app.Services.GetRequiredService<IPlanningCatalog>();
        var fact = catalog.ReadMonth(month.Year, month.Month).Events.First(e => e.InstantUtc > month);
        var input = new ReminderInput(Guid.NewGuid(), 0, fact.Id, null, fact.InstantUtc, "Asia/Kathmandu", 60);
        var saved = await Save(client, input); Assert.Equal(fact.TargetId, saved.TargetId); Assert.Equal(fact.Id, saved.EventId);
        Assert.Equal(HttpStatusCode.BadRequest, (await client.PostAsJsonAsync(Route, input with { Id = Guid.NewGuid(), InstantUtc = fact.InstantUtc.AddMinutes(1) })).StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, (await client.PostAsJsonAsync(Route, input with { Id = Guid.NewGuid(), EventId = "invented" })).StatusCode);
        await Save(client, input with { ExpectedRevision = saved.Revision, Cancelled = true });
    }
    [Theory]
    [InlineData("zone")] [InlineData("lead")] [InlineData("past")] [InlineData("horizon")] [InlineData("target")]
    public async Task Invalid_or_already_due_inputs_are_rejected(string variant)
    {
        using var client = app.Client(); await Login(client); var input = Observing();
        input = variant switch { "zone" => input with { TimeZoneId = "Invented/Zone" }, "lead" => input with { LeadMinutes = -1 },
            "past" => input with { InstantUtc = DateTimeOffset.UtcNow }, "horizon" => input with { InstantUtc = DateTimeOffset.UtcNow.AddDays(367) }, _ => input with { TargetId = "arbitrary-target" } };
        Assert.Equal(HttpStatusCode.BadRequest, (await client.PostAsJsonAsync(Route, input)).StatusCode);
    }
    [Fact]
    public async Task Duplicate_and_stale_requests_conflict_and_cancelled_records_do_not_send()
    {
        using var client = app.Client(); await Login(client); var input = Observing(); var saved = await Save(client, input);
        Assert.Equal(HttpStatusCode.Conflict, (await client.PostAsJsonAsync(Route, input with { Id = Guid.NewGuid() })).StatusCode);
        Assert.Equal(HttpStatusCode.Conflict, (await client.PostAsJsonAsync(Route, input with { Cancelled = true })).StatusCode);
        var cancelled = await Save(client, input with { ExpectedRevision = saved.Revision, Cancelled = true });
        Assert.Equal("cancelled", cancelled.Status); await Dispatch(saved.DueAtUtc.AddSeconds(1));
        var current = await client.GetFromJsonAsync<JsonElement>(Route);
        Assert.Equal("cancelled", current.GetProperty("reminders")[0].GetProperty("status").GetString());
        var replacement = await Save(client, input with { Id = Guid.NewGuid() });
        Assert.Equal("scheduled", replacement.Status);
        Assert.Equal(HttpStatusCode.Conflict, (await client.PostAsJsonAsync(Route, input with { Id = Guid.NewGuid() })).StatusCode);
    }
    [Fact]
    public async Task Due_mail_is_English_branded_local_and_UTC_then_recorded_as_SMTP_accepted()
    {
        using var client = app.Client("tr"); var user = await Login(client); var input = Observing(); var saved = await Save(client, input);
        await Dispatch(saved.DueAtUtc.AddSeconds(1));
        var mail = app.Email.Messages.Last(m => m.Recipient == user.Email && m.Subject.StartsWith("Yorungez sky reminder:"));
        Assert.Contains("Europe/Istanbul", mail.Body); Assert.Contains("GMT+03:00", mail.Body); Assert.Contains("UTC", mail.Body);
        Assert.Contains("does not guarantee local visibility", mail.Body); Assert.Contains("#8B2333", mail.HtmlBody);
        Assert.DoesNotContain("latitude", mail.Body, StringComparison.OrdinalIgnoreCase);
        await Dispatch(saved.DueAtUtc.AddMinutes(1));
        Assert.Single(app.Email.Messages, m => m.Recipient == user.Email && m.Subject.StartsWith("Yorungez sky reminder:"));
    }
    [Fact]
    public async Task Failure_retries_without_duplicate_live_leases_and_stale_events_expire()
    {
        using var client = app.Client(); var user = await Login(client); var input = Observing(); var saved = await Save(client, input);
        app.Email.FailNext = true; await Dispatch(saved.DueAtUtc.AddSeconds(1));
        Assert.DoesNotContain(app.Email.Messages, m => m.Recipient == user.Email && m.Subject.StartsWith("Yorungez sky reminder:"));
        await Dispatch(saved.DueAtUtc.AddSeconds(2));
        await Dispatch(saved.DueAtUtc.AddMinutes(2));
        Assert.Single(app.Email.Messages, m => m.Recipient == user.Email && m.Subject.StartsWith("Yorungez sky reminder:"));
        var expiredInput = Observing(2); var expired = await Save(client, expiredInput);
        await Dispatch(expired.InstantUtc.AddSeconds(1));
        await using var scope = app.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<NotebookDatabase>();
        Assert.Equal("expired", (await db.Reminders.AsNoTracking().SingleAsync(r => r.Id == expired.Id)).Status);
    }
    [Fact]
    public async Task Concurrent_workers_claim_a_reminder_once_and_zero_lead_has_a_bounded_delivery_window()
    {
        using var client = app.Client(); var user = await Login(client); var input = Observing() with { LeadMinutes = 0 }; var saved = await Save(client, input);
        await Task.WhenAll(Dispatch(saved.InstantUtc.AddSeconds(10)), Dispatch(saved.InstantUtc.AddSeconds(10)));
        Assert.Single(app.Email.Messages, m => m.Recipient == user.Email && m.Subject.StartsWith("Yorungez sky reminder:"));
    }
    private sealed class FixedClock(DateTimeOffset value) : TimeProvider { public override DateTimeOffset GetUtcNow() => value; }

    [Fact]
    public async Task Active_limit_is_bounded_and_cancellation_releases_capacity()
    {
        using var client = app.Client(); var user = await Login(client);
        Guid first;
        await using (var scope = app.Services.CreateAsyncScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<NotebookDatabase>();
            var now = DateTimeOffset.UtcNow;
            var rows = Enumerable.Range(0, 100).Select(n => new Yorungez.Notebook.Domain.EventReminder {
                UserId = user.Id, Id = Guid.NewGuid(), Revision = 1, TargetId = "jupiter", Title = "Public observing example",
                SourceUrl = "https://github.com/cosinekitty/astronomy", EventKey = "capacity-example-" + n,
                InstantUtc = now.AddDays(30).AddMinutes(n), TimeZoneId = "Europe/Istanbul", LeadMinutes = 30,
                Channel = "email", Status = "scheduled", CreatedAtUtc = now, DueAtUtc = now.AddDays(29).AddHours(23),
                NextAttemptAtUtc = now.AddDays(29).AddHours(23), ExpiresAtUtc = now.AddDays(30).AddMinutes(n)
            }).ToArray();
            first = rows[0].Id; db.AddRange(rows); await db.SaveChangesAsync();
        }
        var blocked = await client.PostAsJsonAsync(Route, Observing());
        Assert.Equal(HttpStatusCode.BadRequest, blocked.StatusCode);
        Assert.Equal("Reminders.Limit", (await blocked.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("code").GetString());
        await Save(client, Observing() with { Id = first, ExpectedRevision = 1, Cancelled = true });
        await Save(client, Observing());
    }
}
