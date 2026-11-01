using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Http.Features;
using System.Security.Claims;
using Yorungez.Identity.Application;
using Yorungez.Identity.Infrastructure;

namespace Yorungez.Api.Http;

public static class BrowserAuthentication
{
    public const string Scheme = "YorungezBrowser";
    public static AuthenticationBuilder AddBrowser(this AuthenticationBuilder auth, bool local)
    {
        auth.AddPolicyScheme("Yorungez", null, options => options.ForwardDefaultSelector = context =>
            context.Request.Headers.Authorization.ToString().StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase)
                ? JwtBearerDefaults.AuthenticationScheme : Scheme);
        return auth.AddCookie(Scheme, options =>
        {
            options.Cookie.Name = local ? "yorungez-session" : "__Host-yorungez-session";
            options.Cookie.HttpOnly = true; options.Cookie.Path = "/";
            options.Cookie.SameSite = SameSiteMode.Strict;
            options.Cookie.SecurePolicy = local ? CookieSecurePolicy.SameAsRequest : CookieSecurePolicy.Always;
            options.SlidingExpiration = false;
            options.Events.OnRedirectToLogin = c => { c.Response.StatusCode = 401; return Task.CompletedTask; };
            options.Events.OnRedirectToAccessDenied = c => { c.Response.StatusCode = 403; return Task.CompletedTask; };
            options.Events.OnValidatePrincipal = async c =>
            {
                var p = c.Principal!;
                if (!Guid.TryParse(p.FindFirstValue("sub"), out var id) || !Guid.TryParse(p.FindFirstValue("sid"), out var family)
                    || p.FindFirstValue("ver") is not { } stamp
                    || !await c.HttpContext.RequestServices.GetRequiredService<IIdentityGateway>()
                        .ValidateSessionAsync(id, family, stamp, c.HttpContext.RequestAborted))
                { c.RejectPrincipal(); await c.HttpContext.SignOutAsync(Scheme); }
            };
        });
    }
    public static async Task Guard(HttpContext context, RequestDelegate next)
    {
        var request = context.Request;
        var personal = request.Path.StartsWithSegments("/api/v1/notebook") || request.Path.StartsWithSegments("/api/v1/auth")
            || request.Path.StartsWithSegments("/api/v1/session");
        if (personal)
        {
            context.Response.Headers.CacheControl = "no-store";
            var limit = context.Features.Get<IHttpMaxRequestBodySizeFeature>();
            if (limit is { IsReadOnly: false }) limit.MaxRequestBodySize = 65536;
            if (request.ContentLength > 65536)
            { await LocalizedProblems.Write(context, 413, "Common.InvalidInput"); return; }
        }
        var browserWrite = request.Path.StartsWithSegments("/api/v1/session")
            || (request.Cookies.Keys.Any(k => k is "yorungez-session" or "__Host-yorungez-session") && personal);
        if (browserWrite && request.Method is not ("GET" or "HEAD" or "OPTIONS"))
        {
            var trusted = new Uri(context.RequestServices.GetRequiredService<EmailSettings>().FrontendBaseUrl).GetLeftPart(UriPartial.Authority);
            var origin = request.Headers.Origin.ToString();
            var local = context.RequestServices.GetRequiredService<IHostEnvironment>().IsDevelopment()
                || context.RequestServices.GetRequiredService<IHostEnvironment>().IsEnvironment("Testing");
            var loopback = local && Uri.TryCreate(origin, UriKind.Absolute, out var uri) && uri.IsLoopback && uri.Scheme is "http" or "https";
            if (request.Headers["X-Yorungez-Request"] != "1" || (!loopback && origin != trusted)
                || !request.HasJsonContentType())
            { await LocalizedProblems.Write(context, 403, "Common.Forbidden"); return; }
        }
        await next(context);
    }
}
