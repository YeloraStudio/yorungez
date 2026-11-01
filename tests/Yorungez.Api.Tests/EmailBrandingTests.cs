using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using MimeKit;
using Yorungez.Identity.Application;
using Yorungez.Identity.Infrastructure;
using Yorungez.Identity.Infrastructure.Persistence;

namespace Yorungez.Api.Tests;

public sealed class EmailBrandingTests(AppFactory app) : IClassFixture<AppFactory>
{
    [Theory]
    [InlineData("confirmation", "Verify email address")]
    [InlineData("reset", "Reset password")]
    public void Branded_mail_survives_MIME_roundtrip_with_plain_text_and_safe_action_link(string kind, string action)
    {
        const string link = "https://example.invalid/en/account/confirm-email#userId=public&token=example%22%3Cvalue%3E";
        var message = AccountEmailTemplate.Create(kind, "public@example.invalid", link);
        var mime = SmtpEmailDelivery.Compose(message, "sender@example.com");
        using var stream = new MemoryStream(); mime.WriteTo(stream); stream.Position = 0;
        var read = MimeMessage.Load(stream);
        Assert.IsType<MultipartAlternative>(read.Body);
        var text = Assert.IsType<string>(read.TextBody); var html = Assert.IsType<string>(read.HtmlBody);
        Assert.Equal(message.Body.ReplaceLineEndings("\n"), text.ReplaceLineEndings("\n"));
        Assert.Equal(message.HtmlBody!.ReplaceLineEndings("\n"), html.ReplaceLineEndings("\n"));
        Assert.Contains("lang=\"en\"", read.HtmlBody); Assert.Contains(action, read.HtmlBody);
        Assert.Contains("2 hours", read.TextBody); Assert.EndsWith(link, read.TextBody);
        Assert.Contains("&amp;token=", read.HtmlBody); Assert.DoesNotContain("<script", read.HtmlBody);
        foreach (var color in new[] { "#3C3F43", "#8B2333", "#C9B6A6", "#F7F1E6" }) Assert.Contains(color, read.HtmlBody);
        Assert.DoesNotContain("<img", read.HtmlBody); Assert.DoesNotContain("<script", read.HtmlBody);
        Assert.Equal("sender@example.com", read.From.Mailboxes.Single().Address);
    }

    [Theory]
    [InlineData("tr")]
    [InlineData("en")]
    public async Task Registration_email_is_English_even_when_interface_is_Turkish(string language)
    {
        using var client = app.Client(language);
        var address = $"email-policy-{Guid.NewGuid():N}@example.invalid";
        Assert.Equal(System.Net.HttpStatusCode.Accepted, (await client.PostAsJsonAsync("/api/v1/auth/register", new { firstName = "Public", lastName = "Tester", email = address, password = "Public policy test passphrase 2026" })).StatusCode);
        await app.DispatchAsync();
        var message = app.Email.Messages.Last(m => m.Recipient == address);
        Assert.Equal("Verify your yorungez email address", message.Subject);
        Assert.Contains("/en/account/confirm-email#", message.Body); Assert.Contains("lang=\"en\"", message.HtmlBody);
        Assert.DoesNotContain("/tr/account/", message.Body);
    }

    [Fact]
    public async Task Previously_queued_plain_Turkish_mail_is_upgraded_to_English_without_changing_fragment()
    {
        using var client = app.Client("tr"); var address = $"legacy-policy-{Guid.NewGuid():N}@example.invalid";
        await client.PostAsJsonAsync("/api/v1/auth/register", new { firstName = "Public", lastName = "Tester", email = address, password = "Public legacy test passphrase 2026" });
        string fragment;
        await using (var scope = app.Services.CreateAsyncScope())
        {
            var store = scope.ServiceProvider.GetRequiredService<IdentityStore>();
            var user = await store.Users.SingleAsync(u => u.Email == address);
            var row = await store.PendingEmails.SingleAsync(e => e.UserId == user.Id);
            var protector = scope.ServiceProvider.GetRequiredService<IDataProtectionProvider>().CreateProtector("yorungez.identity.email-outbox.v1");
            var original = JsonSerializer.Deserialize<EmailMessage>(protector.Unprotect(row.ProtectedPayload))!;
            var oldLink = original.Body.Split('\n', StringSplitOptions.RemoveEmptyEntries).Last().Replace("/en/account/", "/tr/account/");
            fragment = new Uri(oldLink).Fragment;
            row.ProtectedPayload = protector.Protect(JsonSerializer.Serialize(new EmailMessage(address, "Eski konu", "Eski gövde\n\n" + oldLink)));
            await store.SaveChangesAsync();
        }
        await app.DispatchAsync(); var upgraded = app.Email.Messages.Last(m => m.Recipient == address);
        Assert.Contains("lang=\"en\"", upgraded.HtmlBody); Assert.DoesNotContain("Eski", upgraded.Body);
        Assert.Equal(fragment, new Uri(upgraded.Body.Split('\n', StringSplitOptions.RemoveEmptyEntries).Last()).Fragment);
    }
}
