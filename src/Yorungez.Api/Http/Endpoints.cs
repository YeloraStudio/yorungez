using MediatR;
using Microsoft.AspNetCore.Authentication;
using System.Globalization;
using System.Security.Claims;
using Yorungez.Application;
using Yorungez.Astronomy.Application;
using Yorungez.Catalog.Application;
using Yorungez.Identity.Application;
using Yorungez.Notebook.Application;

namespace Yorungez.Api.Http;

public sealed record Credentials(string Email, string Password);
public sealed record EmailInput(string Email);
public sealed record ConfirmationInput(Guid UserId, string Token);
public sealed record ResetInput(Guid UserId, string Token, string Password);
public sealed record RefreshInput(string RefreshToken);

public sealed record PlaceInput(string? Query,double? Latitude,double? Longitude);

public static class Endpoints
{
    private static string Language => CultureInfo.CurrentUICulture.TwoLetterISOLanguageName;
    private static IResult Receipt(ActionReceipt receipt, ITextCatalog texts, int status = 200) =>
        Results.Json(new { code = receipt.Code, message = texts.Get(receipt.Code, Language) }, statusCode: status);

    public static void MapModuleEndpoints(this WebApplication app)
    {
        app.MapGet("/api/v1/status", (ITextCatalog texts) => new { service = "yorungez", stage = "foundation",
            apiVersion = "v1", language = Language, supportedLanguages = new[] { "tr", "en" }, message = texts.Get("Service.Running", Language) });

        var terms = app.MapGroup("/api/v1/terms");
        terms.MapGet("/", async (string? q, ISender sender, CancellationToken ct) =>
            Results.Ok(await sender.Send(new FindTermsQuery(q, Language), ct)));
        terms.MapGet("/{id}", async (string id, ISender sender, CancellationToken ct) =>
            Results.Ok(await sender.Send(new GetTermQuery(id, Language), ct)));
        app.MapGet("/api/v1/catalog/sky", async (HttpContext context, ISender sender, CancellationToken ct) =>
        {
            var snapshot = await sender.Send(new GetSkyCatalogQuery(), ct);
            var etag = "\"" + snapshot.Provenance.DerivedSha256 + "\"";
            context.Response.Headers.ETag = etag;
            context.Response.Headers.CacheControl = "public, max-age=86400";
            if (context.Request.Headers.IfNoneMatch.Any(value => value == etag)) return Results.StatusCode(304);
            return Results.Ok(snapshot);
        });

        app.MapGet("/api/v1/catalog/overlays", async (HttpContext context, ISender sender, CancellationToken ct) =>
        {
            var snapshot = await sender.Send(new GetSkyOverlaysQuery(), ct);
            var etag = "\"" + snapshot.Provenance.Sha256 + "\"";
            context.Response.Headers.ETag = etag;
            context.Response.Headers.CacheControl = "public, max-age=86400";
            if (context.Request.Headers.IfNoneMatch.Any(value => value == etag)) return Results.StatusCode(304);
            return Results.Ok(snapshot);
        });

        app.MapGet("/api/v1/events/calendar", async (int year, int month, HttpContext context, ISender sender, CancellationToken ct) =>
        {
            var result=await sender.Send(new GetCalendarMonthQuery(year,month),ct);
            var etag=$"\"{result.Provenance.Sha256}-{year}-{month}\"";
            context.Response.Headers.ETag=etag;context.Response.Headers.CacheControl="public, max-age=86400";
            if(context.Request.Headers.IfNoneMatch.Any(v=>v==etag))return Results.StatusCode(304);
            return Results.Ok(result);
        });
        app.MapPost("/api/v1/locations/places", async (PlaceInput input,HttpContext context,ISender sender,CancellationToken ct)=>
        {
            context.Response.Headers.CacheControl="no-store";
            var places=await sender.Send(new FindPlacesQuery(input.Query,input.Latitude,input.Longitude),ct);
            return Results.Ok(new {places,source="GeoNames",license="CC BY 4.0",sourceUrl="https://www.geonames.org/",mode=input.Query is null?"nearest-place-point":"search"});
        }).RequireRateLimiting("astronomy");

        // POST keeps private coordinates out of URLs/access logs and shared caches.
        var sky = app.MapGroup("/api/v1/sky").RequireRateLimiting("astronomy");
        sky.AddEndpointFilter(async (context, next) =>
        {
            context.HttpContext.Response.Headers.CacheControl = "no-store";
            return await next(context);
        });
        sky.MapPost("/positions", async (SkyInput input, ISender sender, CancellationToken ct) =>
            Results.Ok(await sender.Send(new CalculateSkyQuery(input, Language), ct)));
        sky.MapPost("/horizon-crossings", async (CrossingsInput input, ISender sender, CancellationToken ct) =>
            Results.Ok(await sender.Send(new CalculateCrossingsQuery(input, Language), ct)));

        var auth = app.MapGroup("/api/v1/auth").RequireRateLimiting("identity");
        auth.AddEndpointFilter(async (context, next) =>
        {
            context.HttpContext.Response.Headers.CacheControl = "no-store";
            return await next(context);
        });
        auth.MapPost("/register", async (RegistrationInput input, ISender sender, ITextCatalog texts, CancellationToken ct) =>
            Receipt(await sender.Send(new RegisterCommand(input.Email, input.Password, Language, input.FirstName, input.LastName), ct), texts, 202));
        auth.MapPost("/confirm-email", async (ConfirmationInput input, ISender sender, ITextCatalog texts, CancellationToken ct) =>
            Receipt(await sender.Send(new ConfirmEmailCommand(input.UserId, input.Token), ct), texts));
        auth.MapPost("/login", async (Credentials input, HttpContext context, ISender sender, CancellationToken ct) =>
        { context.Response.Headers.CacheControl = "no-store"; return Results.Ok(await sender.Send(new LoginCommand(input.Email, input.Password), ct)); });
        auth.MapPost("/refresh", async (RefreshInput input, HttpContext context, ISender sender, CancellationToken ct) =>
        { context.Response.Headers.CacheControl = "no-store"; return Results.Ok(await sender.Send(new RefreshCommand(input.RefreshToken), ct)); });
        auth.MapPost("/resend-confirmation", async (EmailInput input, ISender sender, ITextCatalog texts, CancellationToken ct) =>
            Receipt(await sender.Send(new ResendConfirmationCommand(input.Email, Language), ct), texts, 202));
        auth.MapPost("/forgot-password", async (EmailInput input, ISender sender, ITextCatalog texts, CancellationToken ct) =>
            Receipt(await sender.Send(new ForgotPasswordCommand(input.Email, Language), ct), texts, 202));
        auth.MapPost("/reset-password", async (ResetInput input, ISender sender, ITextCatalog texts, CancellationToken ct) =>
            Receipt(await sender.Send(new ResetPasswordCommand(input.UserId, input.Token, input.Password), ct), texts));
        auth.MapPost("/logout", async (ClaimsPrincipal user, HttpContext context, ISender sender, ITextCatalog texts, CancellationToken ct) =>
        {
            var result = await sender.Send(new LogoutCommand(UserId(user), Guid.Parse(user.FindFirstValue("sid")!)), ct);
            await context.SignOutAsync(BrowserAuthentication.Scheme);
            return Receipt(result, texts);
        }).RequireAuthorization();
        auth.MapPost("/profile", async (ProfileInput input, ClaimsPrincipal user, HttpContext context, ISender sender, CancellationToken ct) =>
        {
            if (context.Request.Headers["X-Yorungez-Account"] is { Count: > 0 } expected && expected != UserId(user).ToString())
                throw new Yorungez.Application.AppFailure("Identity.AccountChanged", Yorungez.Application.FailureKind.Conflict);
            return Results.Ok(await sender.Send(new SaveProfileCommand(UserId(user), input.FirstName, input.LastName), ct));
        }).RequireAuthorization();
        auth.MapPost("/language", async (LanguageInput input, ClaimsPrincipal user, HttpContext context, ISender sender, CancellationToken ct) =>
        {
            if (context.Request.Headers["X-Yorungez-Account"] is { Count: > 0 } expected && expected != UserId(user).ToString())
                throw new Yorungez.Application.AppFailure("Identity.AccountChanged", Yorungez.Application.FailureKind.Conflict);
            return Results.Ok(await sender.Send(new SaveLanguageCommand(UserId(user), input.PreferredLanguage), ct));
        }).RequireAuthorization();
        auth.MapGet("/me", async (ClaimsPrincipal user, ISender sender, CancellationToken ct) =>
            Results.Ok(await sender.Send(new CurrentUserQuery(UserId(user)), ct))).RequireAuthorization();

        app.MapPost("/api/v1/session/login", async (Credentials input, HttpContext context, ISender sender, CancellationToken ct) =>
        {
            var session = await sender.Send(new BrowserLoginCommand(input.Email, input.Password), ct);
            var identity = new ClaimsIdentity(new[] { new Claim("sub", session.UserId.ToString()),
                new Claim("sid", session.FamilyId.ToString()), new Claim("ver", session.StampHash) }, BrowserAuthentication.Scheme);
            await context.SignInAsync(BrowserAuthentication.Scheme, new ClaimsPrincipal(identity), new AuthenticationProperties
            { IsPersistent = true, AllowRefresh = false, ExpiresUtc = session.ExpiresAt });
            return Results.Ok(await sender.Send(new CurrentUserQuery(session.UserId), ct));
        }).RequireRateLimiting("identity");

        var notebook = app.MapGroup("/api/v1/notebook").RequireAuthorization().RequireRateLimiting("notebook");
        notebook.AddEndpointFilter(async (context, next) =>
        {
            // A tab opened as A must not write its draft into B after another tab signs in.
            if (context.HttpContext.Request.Headers["X-Yorungez-Account"] is { Count: > 0 } expected
                && expected != UserId(context.HttpContext.User).ToString())
            { await LocalizedProblems.Write(context.HttpContext, 409, "Notebook.AccountChanged"); return Results.Empty; }
            return await next(context);
        });
        notebook.MapGet("/", async (ClaimsPrincipal user, ISender sender, CancellationToken ct) =>
            Results.Ok(new { userId = UserId(user), entries = await sender.Send(new ListNotebookQuery(UserId(user)), ct) }));
        notebook.MapPost("/", async (EntryInput input, ClaimsPrincipal user, ISender sender, CancellationToken ct) =>
            Results.Ok(await sender.Send(new SaveNotebookCommand(UserId(user), input), ct)));
    }

    private static Guid UserId(ClaimsPrincipal user) => Guid.Parse(user.FindFirstValue("sub")!);
}

public sealed record RegistrationInput(string Email, string Password, string? FirstName, string? LastName);
public sealed record ProfileInput(string? FirstName, string? LastName);
public sealed record LanguageInput(string? PreferredLanguage);
