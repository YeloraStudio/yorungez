using System.Globalization;
using System.Net;
using Microsoft.AspNetCore.Identity;
using Yorungez.Identity.Application;
using Yorungez.Identity.Infrastructure.Persistence;

namespace Yorungez.Identity.Infrastructure;

public sealed class AccountReminderEmail(UserManager<Account> users, IEmailDelivery delivery, EmailSettings settings) : IAccountReminderEmail
{
    public async Task<bool> SendAsync(Guid userId, ReminderEmailContent content, CancellationToken ct)
    {
        var user = await users.FindByIdAsync(userId.ToString());
        if (user is null || !user.EmailConfirmed || string.IsNullOrWhiteSpace(user.Email)) return false;
        await delivery.SendAsync(ReminderEmailTemplate.Create(user.Email, content, settings.FrontendBaseUrl), ct);
        return true;
    }
}

public static class ReminderEmailTemplate
{
    public static EmailMessage Create(string recipient, ReminderEmailContent content, string frontend)
    {
        var zone = TimeZoneInfo.FindSystemTimeZoneById(content.TimeZoneId);
        var local = TimeZoneInfo.ConvertTime(content.InstantUtc, zone);
        var localLabel = local.ToString("dd MMM yyyy, HH:mm 'GMT'zzz", CultureInfo.InvariantCulture) + " · " + content.TimeZoneId;
        var utc = content.InstantUtc.ToUniversalTime().ToString("dd MMM yyyy, HH:mm 'UTC'", CultureInfo.InvariantCulture);
        var url = frontend.TrimEnd('/') + "/en";
        static string H(string value) => WebUtility.HtmlEncode(value);
        var plain = $"Your sky reminder\n\n{content.Title}\n{localLabel}\n{utc}\n\nYou requested this reminder in Yorungez. This event or observing time does not guarantee local visibility; check the horizon, weather and equipment.\n\nSource: {content.SourceUrl}\nManage your reminders in the Yorungez app sidebar.\nExplore the sky: {url}";
        var html = $$"""
            <!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head>
            <body style="margin:0;background:#F7F1E6;color:#3C3F43;font-family:Arial,Helvetica,sans-serif">
            <table role="presentation" width="100%" cellpadding="0" cellspacing="0"><tr><td align="center" style="padding:32px 16px">
            <table role="presentation" width="100%" style="max-width:600px" cellpadding="0" cellspacing="0">
            <tr><td style="padding:0 0 24px"><img src="cid:{{AccountEmailTemplate.LogoContentId}}" alt="Yorungez" width="240" style="max-width:100%;height:auto"></td></tr>
            <tr><td style="background:#3C3F43;border-radius:16px 16px 0 0;padding:28px"><p style="color:#C9B6A6;letter-spacing:2px;font-size:12px">YOUR SKY REMINDER</p><h1 style="color:#F7F1E6;font-size:28px;line-height:1.3;margin:0">{{H(content.Title)}}</h1></td></tr>
            <tr><td style="background:#FFFFFF;padding:28px;border-radius:0 0 16px 16px">
            <p style="font-size:18px;line-height:1.7;margin:0 0 8px">{{H(localLabel)}}</p><p style="color:#66696D;line-height:1.6;margin:0 0 24px">{{H(utc)}}</p>
            <a href="{{H(url)}}" style="display:inline-block;background:#8B2333;color:#F7F1E6;text-decoration:none;padding:16px 24px;border-radius:8px;font-weight:bold">Explore the sky &rarr;</a>
            <p style="font-size:14px;line-height:1.7;margin-top:24px">You requested this reminder in Yorungez. This event or observing time does not guarantee local visibility; check the horizon, weather and equipment.</p>
            <p style="font-size:13px;line-height:1.7;color:#66696D">Manage or cancel future reminders in the Yorungez app sidebar.</p>
            <a href="{{H(content.SourceUrl)}}" style="font-size:13px;color:#8B2333">Event / calculation source</a>
            </td></tr><tr><td style="padding:24px 0;color:#66696D;font-size:12px">Yorungez · A little curiosity. An entire universe.</td></tr></table>
            </td></tr></table></body></html>
            """;
        return new(recipient, "Yorungez sky reminder: " + content.Title, plain, html);
    }
}
