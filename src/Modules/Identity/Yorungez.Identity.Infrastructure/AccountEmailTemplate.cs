using System.Net;
using Yorungez.Identity.Application;

namespace Yorungez.Identity.Infrastructure;

/// <summary>Transactional mail has a fixed English language policy, independent of the UI language.</summary>
public static class AccountEmailTemplate
{
    public const string LogoContentId = "yorungez-wordmark";
    public static EmailMessage Create(string kind, string recipient, string actionUrl)
    {
        if (kind is not ("confirmation" or "reset") || !Uri.TryCreate(actionUrl, UriKind.Absolute, out var uri)
            || uri.Scheme is not ("http" or "https")) throw new ArgumentException("Invalid email action.");
        var confirmation = kind == "confirmation";
        var subject = confirmation ? "Verify your yorungez email address" : "Reset your yorungez password";
        var title = confirmation ? "Your sky. Your discoveries." : "Let's get you back to the sky.";
        var eyebrow = confirmation ? "VERIFY YOUR EMAIL" : "PASSWORD RESET";
        var description = confirmation
            ? "Confirm your email address to keep your notes, favorites and discoveries together in your private yorungez account."
            : "We received a request to reset the password for your yorungez account. Choose a new password using the secure link below.";
        var action = confirmation ? "Verify email address" : "Reset password";
        const string expiry = "This link expires in 2 hours.";
        var ignore = confirmation ? "If you didn't create this account, you can safely ignore this email."
            : "If you didn't request a password reset, you can safely ignore this email. Your password will stay the same.";
        var safeUrl = WebUtility.HtmlEncode(actionUrl);
        var html = $$"""
            <!doctype html>
            <html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>{{subject}}</title></head>
            <body style="margin:0;padding:0;background-color:#F7F1E6;color:#3C3F43;font-family:Arial,Helvetica,sans-serif;">
            <div style="display:none;max-height:0;overflow:hidden;opacity:0;">{{action}}. {{expiry}}</div>
            <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" bgcolor="#F7F1E6"><tr><td align="center" style="padding:36px 16px;">
            <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="max-width:600px;">
            <tr><td style="padding:0 8px 24px;color:#3C3F43;"><img src="cid:{{LogoContentId}}" alt="yorungez" width="240" height="75" style="display:block;border:0;width:240px;max-width:100%;height:auto;"></td></tr>
            <tr><td bgcolor="#3C3F43" style="border-radius:16px 16px 0 0;padding:30px 28px;">
            <p style="margin:0 0 12px;color:#C9B6A6;font-size:11px;font-weight:bold;letter-spacing:2px;">{{eyebrow}}</p>
            <h1 style="margin:0;color:#F7F1E6;font-size:28px;line-height:1.3;font-weight:700;">{{title}}</h1>
            </td></tr>
            <tr><td bgcolor="#FFFFFF" style="padding:30px 28px;border:1px solid #E3DFD6;border-top:0;border-radius:0 0 16px 16px;">
            <p style="margin:0 0 24px;font-size:16px;line-height:1.7;color:#3C3F43;">{{description}}</p>
            <table role="presentation" cellspacing="0" cellpadding="0" border="0"><tr><td bgcolor="#8B2333" style="border-radius:8px;text-align:center;">
            <a href="{{safeUrl}}" style="background-color:#8B2333;border:1px solid #8B2333;border-radius:8px;color:#F7F1E6;display:inline-block;padding:15px 24px;font-size:15px;font-weight:bold;text-decoration:none;">{{action}} &rarr;</a>
            </td></tr></table>
            <p style="margin:16px 0 24px;font-size:13px;line-height:1.6;color:#66696D;">{{expiry}}</p>
            <p style="margin:0;padding-top:22px;border-top:1px solid #E3DFD6;font-size:13px;line-height:1.7;color:#66696D;">{{ignore}}</p>
            <p style="margin:18px 0 8px;font-size:12px;line-height:1.6;color:#66696D;">Button not working? Copy this link into your browser:</p>
            <a href="{{safeUrl}}" style="font-size:12px;line-height:1.7;word-break:break-all;overflow-wrap:anywhere;color:#8B2333;">{{safeUrl}}</a>
            </td></tr>
            <tr><td style="padding:24px 8px 0;font-size:12px;line-height:1.7;color:#66696D;">A little curiosity. An entire universe.<br><span style="color:#3C3F43;font-weight:bold;">yorungez</span> &middot; Your personal observatory<br>We will never ask you to send us your password.</td></tr>
            </table></td></tr></table></body></html>
            """;
        // Keep the action URL as the final line for plain-text clients and legacy outbox compatibility.
        var plain = $"{title}\n\n{description}\n\n{action}\n{expiry}\n\n{ignore}\n\nyorungez — Your personal observatory\n\n{actionUrl}";
        return new(recipient, subject, plain, html);
    }
}
