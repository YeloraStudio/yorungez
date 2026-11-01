using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Yorungez.Identity.Application;
using Yorungez.Identity.Infrastructure.Persistence;
using Yorungez.Identity.Infrastructure.Security;

namespace Yorungez.Identity.Infrastructure;

public static class IdentityModule
{
    public static IServiceCollection AddIdentityModule(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddDbContext<IdentityStore>((provider, options) =>
        {
            var config = provider.GetRequiredService<IConfiguration>();
            options.UseNpgsql(config.GetConnectionString("Identity")
                ?? throw new InvalidOperationException("Identity database connection is required."),
                o => o.MigrationsHistoryTable("__EFMigrationsHistory", "identity"));
        });
        services.AddIdentityCore<Account>(o =>
        {
            o.User.RequireUniqueEmail = true;
            o.SignIn.RequireConfirmedEmail = true;
            o.Password.RequiredLength = 15;
            o.Password.RequireDigit = false;
            o.Password.RequireLowercase = false;
            o.Password.RequireUppercase = false;
            o.Password.RequireNonAlphanumeric = false;
            o.Lockout.MaxFailedAccessAttempts = 5;
            o.Lockout.DefaultLockoutTimeSpan = TimeSpan.FromMinutes(15);
        }).AddRoles<IdentityRole<Guid>>().AddEntityFrameworkStores<IdentityStore>().AddDefaultTokenProviders();
        services.Configure<PasswordHasherOptions>(o => o.IterationCount = 210000);
        services.Configure<DataProtectionTokenProviderOptions>(o => o.TokenLifespan = TimeSpan.FromHours(2));
        services.AddSingleton(TimeProvider.System);
        services.AddSingleton(provider =>
        {
            var config = provider.GetRequiredService<IConfiguration>();
            var settings = new JwtSettings(config["Jwt:Issuer"] ?? "https://yorungez.local",
                config["Jwt:Audience"] ?? "yorungez-api", config["Jwt:SigningKey"] ?? "",
                config.GetValue("Jwt:AccessMinutes", 10), config.GetValue("Jwt:RefreshDays", 7));
            settings.Validate();
            return settings;
        });
        services.AddSingleton(provider =>
        {
            var config = provider.GetRequiredService<IConfiguration>();
            var environment = provider.GetRequiredService<IHostEnvironment>();
            var local = environment.IsDevelopment() || environment.IsEnvironment("Testing");
            var host = config["Email:Host"] ?? (local ? "127.0.0.1" : "");
            var frontend = config["Email:FrontendBaseUrl"] ?? (local ? "http://localhost:3000" : "");
            var requireTls = config.GetValue("Email:RequireTls", !local);
            if (!string.IsNullOrWhiteSpace(config["Email:UserName"])
                && string.IsNullOrWhiteSpace(config["Email:Password"]))
                throw new InvalidOperationException("SMTP authentication requires both username and password.");
            if (string.IsNullOrWhiteSpace(host) || !Uri.TryCreate(frontend, UriKind.Absolute, out var uri)
                || uri.Scheme is not ("https" or "http")
                || (!local && (!requireTls || uri.Scheme != "https")))
                throw new InvalidOperationException("Configure a trusted frontend URL and TLS email delivery.");
            return new EmailSettings(host, config.GetValue("Email:Port", local ? 1029 : 587),
                config["Email:Sender"] ?? (local ? "no-reply@yorungez.invalid" : throw new InvalidOperationException("Email sender required.")),
                frontend, requireTls, config["Email:UserName"], config["Email:Password"]);
        });
        services.AddSingleton<TokenIssuer>();
        services.AddScoped<IIdentityGateway, IdentityGateway>();
        services.AddSingleton<IEmailDelivery, SmtpEmailDelivery>();
        services.AddScoped<EmailOutboxDispatcher>();
        if (configuration.GetValue("Email:RunOutboxWorker", true)
            && configuration["environment"] != "Testing") services.AddHostedService<EmailOutboxWorker>();
        return services;
    }
}
