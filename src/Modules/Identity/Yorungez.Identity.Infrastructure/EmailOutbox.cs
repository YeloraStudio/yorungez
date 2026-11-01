using MailKit.Net.Smtp;
using MailKit.Security;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using MimeKit;
using System.Text.Json;
using Yorungez.Identity.Application;
using Yorungez.Identity.Infrastructure.Persistence;

namespace Yorungez.Identity.Infrastructure;

public sealed record EmailSettings(string Host, int Port, string Sender, string FrontendBaseUrl,
    bool RequireTls, string? UserName, string? Password);

public sealed class SmtpEmailDelivery(EmailSettings options) : IEmailDelivery
{
    public async Task SendAsync(EmailMessage message, CancellationToken ct)
    {
        var mail = Compose(message, options.Sender);
        using var client = new SmtpClient { Timeout = 10000 };
        await client.ConnectAsync(options.Host, options.Port,
            options.RequireTls ? SecureSocketOptions.StartTls : SecureSocketOptions.None, ct);
        if (!string.IsNullOrEmpty(options.UserName))
            await client.AuthenticateAsync(options.UserName, options.Password
                ?? throw new InvalidOperationException("SMTP authentication password is required."), ct);
        await client.SendAsync(mail, ct);
        await client.DisconnectAsync(true, ct);
    }

    public static MimeMessage Compose(EmailMessage message, string sender)
    {
        var mail = new MimeMessage();
        mail.From.Add(new MailboxAddress("yorungez", sender));
        mail.To.Add(MailboxAddress.Parse(message.Recipient));
        mail.Subject = message.Subject;
        mail.Body = new BodyBuilder { TextBody = message.Body, HtmlBody = message.HtmlBody }.ToMessageBody();
        return mail;
    }

    // Explicit diagnostic: TLS/authentication only, never an email submission.
    public async Task CheckConnectionAsync(CancellationToken ct)
    {
        using var client = new SmtpClient { Timeout = 10000 };
        await client.ConnectAsync(options.Host, options.Port,
            options.RequireTls ? SecureSocketOptions.StartTls : SecureSocketOptions.None, ct);
        if (!string.IsNullOrEmpty(options.UserName))
            await client.AuthenticateAsync(options.UserName, options.Password
                ?? throw new InvalidOperationException("SMTP authentication password is required."), ct);
        await client.DisconnectAsync(true, ct);
    }
}

public sealed class EmailOutboxDispatcher(IdentityStore store, IEmailDelivery delivery,
    IDataProtectionProvider protection, TimeProvider clock, ILogger<EmailOutboxDispatcher> logger, EmailSettings settings)
{
    private readonly IDataProtector _protector = protection.CreateProtector("yorungez.identity.email-outbox.v1");

    public async Task<int> DispatchOnceAsync(CancellationToken ct)
    {
        var now = clock.GetUtcNow();
        var candidates = await store.PendingEmails.AsNoTracking()
            .Where(e => e.SentAt == null && e.Attempts < 10 && e.NextAttemptAt <= now
                && (e.LeaseUntil == null || e.LeaseUntil < now))
            .OrderBy(e => e.CreatedAt).Select(e => e.Id).Take(20).ToArrayAsync(ct);
        var sent = 0;
        foreach (var id in candidates)
        {
            var version = Guid.NewGuid();
            var claimed = await store.PendingEmails.Where(e => e.Id == id && e.SentAt == null
                && (e.LeaseUntil == null || e.LeaseUntil < now))
                .ExecuteUpdateAsync(s => s.SetProperty(e => e.LeaseUntil, now.AddMinutes(1))
                    .SetProperty(e => e.Version, version), ct);
            if (claimed == 0) continue;
            var row = await store.PendingEmails.SingleAsync(e => e.Id == id, ct);
            row.Attempts++;
            try
            {
                var message = JsonSerializer.Deserialize<EmailMessage>(_protector.Unprotect(row.ProtectedPayload))
                    ?? throw new InvalidOperationException("Invalid protected email payload.");
                if (message.HtmlBody is null)
                {
                    // Upgrade an old pending plain-text snapshot to the current English policy.
                    var oldLink = new Uri(message.Body.Split('\n', StringSplitOptions.RemoveEmptyEntries).Last().Trim());
                    var action = row.Kind == "confirmation" ? "confirm-email" : row.Kind == "reset" ? "reset-password" : throw new InvalidOperationException("Unknown email action.");
                    if (oldLink.GetLeftPart(UriPartial.Authority) != new Uri(settings.FrontendBaseUrl).GetLeftPart(UriPartial.Authority)
                        || !oldLink.AbsolutePath.EndsWith("/account/" + action, StringComparison.Ordinal))
                        throw new InvalidOperationException("Invalid legacy email link.");
                    message = AccountEmailTemplate.Create(row.Kind, message.Recipient,
                        $"{settings.FrontendBaseUrl.TrimEnd('/')}/en/account/{action}{oldLink.Fragment}");
                }
                await delivery.SendAsync(message, ct);
                row.SentAt = clock.GetUtcNow();
                sent++;
            }
            catch (Exception ex) when (ex is not OperationCanceledException)
            {
                row.NextAttemptAt = clock.GetUtcNow().AddSeconds(Math.Min(3600, 15 * Math.Pow(2, row.Attempts)));
                logger.LogWarning("Email outbox attempt failed ({ExceptionType}); payload and recipient omitted.", ex.GetType().Name);
            }
            row.LeaseUntil = null;
            row.Version = Guid.NewGuid();
            await store.SaveChangesAsync(ct);
        }
        return sent;
    }
}

public sealed class EmailOutboxWorker(IServiceScopeFactory scopes, ILogger<EmailOutboxWorker> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        using var timer = new PeriodicTimer(TimeSpan.FromSeconds(5));
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await using var scope = scopes.CreateAsyncScope();
                await scope.ServiceProvider.GetRequiredService<EmailOutboxDispatcher>().DispatchOnceAsync(stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested) { break; }
            catch (Exception ex)
            {
                logger.LogWarning("Email outbox is unavailable ({ExceptionType}).", ex.GetType().Name);
            }
            if (!await timer.WaitForNextTickAsync(stoppingToken)) break;
        }
    }
}
