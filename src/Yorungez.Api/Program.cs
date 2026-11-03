using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.AspNetCore.Http.Features;
using Microsoft.AspNetCore.HttpOverrides;
using System.Net;
using Microsoft.AspNetCore.Localization;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.Security.Cryptography.X509Certificates;
using System.Text;
using System.Threading.RateLimiting;
using Yorungez.Api.Http;
using Yorungez.Api.Localization;
using Yorungez.Application;
using Yorungez.Astronomy.Application;
using Yorungez.Astronomy.Domain;
using Yorungez.Astronomy.Infrastructure;
using Yorungez.Catalog.Application;
using Yorungez.Catalog.Infrastructure;
using Yorungez.Identity.Application;
using Yorungez.Identity.Infrastructure;
using Yorungez.Identity.Infrastructure.Persistence;
using Yorungez.Identity.Infrastructure.Security;
using Yorungez.Notebook.Application;
using Yorungez.Notebook.Infrastructure;

var migrate = args.Contains("--migrate", StringComparer.Ordinal);
var checkSmtp = args.Contains("--check-smtp", StringComparer.Ordinal);
var previewEmails = args.Contains("--preview-emails", StringComparer.Ordinal);
var builder = WebApplication.CreateBuilder(args.Where(a => a is not ("--migrate" or "--check-smtp" or "--preview-emails")).ToArray());
if (builder.Environment.IsDevelopment())
    builder.Configuration.AddJsonFile("appsettings.Local.json", optional: true, reloadOnChange: false).AddEnvironmentVariables();

builder.Services.AddSingleton<ITextCatalog, TextCatalog>();
builder.Services.Configure<RequestLocalizationOptions>(options =>
{
    options.SetDefaultCulture("en").AddSupportedCultures("tr", "en").AddSupportedUICultures("tr", "en");
    options.ApplyCurrentCultureToResponseHeaders = true;
    options.RequestCultureProviders = [new AcceptLanguageHeaderRequestCultureProvider()];
});
builder.Services.AddMediatR(c =>
{
    c.RegisterServicesFromAssemblies(typeof(FindTermsQuery).Assembly, typeof(RegisterCommand).Assembly,
        typeof(CalculateSkyQuery).Assembly, typeof(ListNotebookQuery).Assembly);
    c.AddOpenBehavior(typeof(RequestTelemetryBehavior<,>));
});
builder.Services.AddScoped<IGlossaryRepository, GlossaryRepository>();
builder.Services.AddSingleton<ISkyCatalogRepository, SkyCatalogRepository>();
builder.Services.AddSingleton<IPlanningCatalog, PlanningCatalogRepository>();
builder.Services.AddSingleton<ISkyCalculator, AstronomyEngineCalculator>();
builder.Services.AddStackExchangeRedisCache(o =>
{
    o.Configuration = builder.Configuration.GetConnectionString("Redis");
    o.InstanceName = "yorungez:";
});
builder.Services.AddIdentityModule(builder.Configuration);
builder.Services.AddNotebookModule();

var protection = builder.Services.AddDataProtection().SetApplicationName("yorungez");
if (builder.Environment.IsEnvironment("Testing")) protection.UseEphemeralDataProtectionProvider();
else
{
    var keyPath = builder.Configuration["DataProtection:KeyRingPath"]
        ?? throw new InvalidOperationException("Configure the persistent data-protection key directory.");
    protection.PersistKeysToFileSystem(new DirectoryInfo(keyPath));
    if (builder.Environment.IsDevelopment() && OperatingSystem.IsWindows()) protection.ProtectKeysWithDpapi();
    else if (!builder.Environment.IsDevelopment())
    {
        var certificatePath = builder.Configuration["DataProtection:CertificatePath"]
            ?? throw new InvalidOperationException("Production requires a certificate to protect persisted keys.");
        protection.ProtectKeysWithCertificate(X509CertificateLoader.LoadPkcs12FromFile(
            certificatePath, builder.Configuration["DataProtection:CertificatePassword"]));
    }
}

builder.Services.AddAuthentication("Yorungez").AddBrowser(builder.Environment.IsDevelopment() || builder.Environment.IsEnvironment("Testing")).AddJwtBearer();
builder.Services.AddOptions<JwtBearerOptions>(JwtBearerDefaults.AuthenticationScheme)
    .Configure<JwtSettings>((options, settings) =>
    {
        options.MapInboundClaims = false;
        options.IncludeErrorDetails = false;
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true, ValidIssuer = settings.Issuer,
            ValidateAudience = true, ValidAudience = settings.Audience,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(settings.SigningKey)),
            ValidateLifetime = true, RequireExpirationTime = true,
            ClockSkew = TimeSpan.FromSeconds(15), ValidAlgorithms = [SecurityAlgorithms.HmacSha256]
        };
        options.Events = new JwtBearerEvents
        {
            OnTokenValidated = async context =>
            {
                var user = context.Principal!;
                if (!Guid.TryParse(user.FindFirst("sub")?.Value, out var id)
                    || !Guid.TryParse(user.FindFirst("sid")?.Value, out var family)
                    || user.FindFirst("ver")?.Value is not { } stamp
                    || !await context.HttpContext.RequestServices.GetRequiredService<IIdentityGateway>()
                        .ValidateSessionAsync(id, family, stamp, context.HttpContext.RequestAborted))
                    context.Fail("Session is not valid.");
            }
        };
    });
builder.Services.AddAuthorization();
builder.Services.Configure<ForwardedHeadersOptions>(options =>
{
    options.ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto;
    options.ForwardLimit = 1;
    foreach (var address in builder.Configuration.GetSection("ReverseProxy:KnownProxies").Get<string[]>() ?? [])
        options.KnownProxies.Add(IPAddress.Parse(address));
});
builder.Services.AddRateLimiter(o =>
{
    o.AddPolicy("notebook", context => RateLimitPartition.GetFixedWindowLimiter(
        context.User.FindFirst("sub")?.Value ?? context.Connection.RemoteIpAddress?.ToString() ?? "unknown",
        _ => new FixedWindowRateLimiterOptions { PermitLimit = 120, Window = TimeSpan.FromMinutes(1), QueueLimit = 0 }));
    o.AddPolicy("astronomy", context => RateLimitPartition.GetFixedWindowLimiter(
        context.Connection.RemoteIpAddress?.ToString() ?? "unknown", _ => new FixedWindowRateLimiterOptions
        { PermitLimit = 120, Window = TimeSpan.FromMinutes(1), QueueLimit = 0 }));
    o.AddPolicy("identity", context => RateLimitPartition.GetFixedWindowLimiter(
        context.Connection.RemoteIpAddress?.ToString() ?? "unknown", _ => new FixedWindowRateLimiterOptions
        { PermitLimit = builder.Configuration.GetValue("RateLimits:IdentityPerMinute", 20), Window = TimeSpan.FromMinutes(1), QueueLimit = 0 }));
    o.OnRejected = (context, _) => new ValueTask(LocalizedProblems.Write(context.HttpContext, 429, "Common.RateLimited"));
});
builder.Services.AddProblemDetails();
builder.Services.AddExceptionHandler<ApiExceptionHandler>();
builder.Services.AddHealthChecks().AddCheck<IdentityReadiness>("identity").AddCheck<CacheReadiness>("cache");

var app = builder.Build();
_ = app.Services.GetRequiredService<ITextCatalog>();
_ = app.Services.GetRequiredService<JwtSettings>();
_ = app.Services.GetRequiredService<EmailSettings>();
if (checkSmtp)
{
    try
    {
        await new SmtpEmailDelivery(app.Services.GetRequiredService<EmailSettings>()).CheckConnectionAsync(new CancellationTokenSource(TimeSpan.FromSeconds(20)).Token);
        Console.WriteLine("SMTP TLS/authentication check passed. No email was sent.");
    }
    catch (Exception ex)
    {
        Console.Error.WriteLine($"SMTP check failed ({ex.GetType().Name}). Credentials and server response omitted.");
        Environment.ExitCode = 1;
    }
    return;
}
if (previewEmails)
{
    if (!app.Environment.IsDevelopment()) throw new InvalidOperationException("Email preview is development-only.");
    var directory = Path.GetFullPath(Path.Combine(app.Environment.ContentRootPath, "../../docs/ux/emails"));
    Directory.CreateDirectory(directory);
    foreach (var kind in new[] { "confirmation", "reset" })
    {
        var action = kind == "confirmation" ? "confirm-email" : "reset-password";
        var preview = AccountEmailTemplate.Create(kind, "preview@example.invalid", $"https://example.invalid/en/account/{action}#preview=not-a-real-token");
        await File.WriteAllTextAsync(Path.Combine(directory, kind + ".html"), preview.HtmlBody!);
    }
    Console.WriteLine("Public sample email previews generated. No email was sent.");
    return;
}
if (string.IsNullOrWhiteSpace(builder.Configuration.GetConnectionString("Redis")))
    throw new InvalidOperationException("Redis connection is required.");

if (migrate)
{
    await using var scope = app.Services.CreateAsyncScope();
    await scope.ServiceProvider.GetRequiredService<IdentityStore>().Database.MigrateAsync();
    await scope.ServiceProvider.GetRequiredService<NotebookDatabase>().Database.MigrateAsync();
    return;
}

app.UseForwardedHeaders();
// Production sits behind Cloudflare; without this every visitor would share
// the rate-limit partition of the Cloudflare edge that carried the request.
if (app.Configuration.GetValue("ReverseProxy:TrustCloudflare", false))
    app.Use(CloudflareClientAddress.Middleware(CloudflareClientAddress.EdgeNetworks));
app.UseRequestLocalization();
app.UseExceptionHandler();
app.UseStatusCodePages(async context =>
{
    var status = context.HttpContext.Response.StatusCode;
    var code = status switch { 400 => "Common.InvalidInput", 401 => "Common.Unauthorized", 403 => "Common.Forbidden",
        404 => "Common.NotFound", 405 => "Common.InvalidInput", 413 => "Sky.RequestTooLarge",
        429 => "Common.RateLimited", _ => "Common.Unexpected" };
    await LocalizedProblems.Write(context.HttpContext, status, code);
});
if (!app.Environment.IsDevelopment() && !app.Environment.IsEnvironment("Testing"))
{
    app.UseHsts();
    app.UseWhen(context => !context.Request.Path.StartsWithSegments("/health"), branch => branch.UseHttpsRedirection());
}
app.Use(BrowserAuthentication.Guard);
app.UseAuthentication();
app.Use(async (context, next) =>
{
    if (context.Request.Path.StartsWithSegments("/api/v1/sky"))
    {
        context.Response.Headers.CacheControl = "no-store";
        var bodyLimit = context.Features.Get<IHttpMaxRequestBodySizeFeature>();
        if (bodyLimit is { IsReadOnly: false }) bodyLimit.MaxRequestBodySize = 8192;
        if (context.Request.ContentLength > 8192)
        {
            await LocalizedProblems.Write(context, 413, "Sky.RequestTooLarge");
            return;
        }
    }
    await next(context);
});
app.UseRateLimiter();
app.UseAuthorization();
app.MapHealthChecks("/health/live", new HealthCheckOptions { Predicate = _ => false });
app.MapHealthChecks("/health/ready");
app.MapModuleEndpoints();
app.Run();

public partial class Program;
