using Microsoft.AspNetCore.DataProtection;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.Caching.Distributed;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using System.Security.Cryptography.X509Certificates;
using Yorungez.Identity.Application;
using Yorungez.Identity.Infrastructure;

namespace Yorungez.Api.Tests.Recovery;

// In-process HTTP only: no listener, real SMTP, shared cache or production key ring.
internal sealed class RecoveryAppFactory(string connection, string ringPath,
    X509Certificate2 certificate, string jwtMaterial) : WebApplicationFactory<Program>
{
    public CapturedEmailDelivery Email { get; } = new();

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");
        builder.ConfigureAppConfiguration((_, config) => config.AddInMemoryCollection(new Dictionary<string, string?>
        {
            ["ConnectionStrings:Identity"] = connection,
            ["ConnectionStrings:Redis"] = "127.0.0.1:1,abortConnect=false",
            ["Jwt:Issuer"] = "https://recovery.example.invalid", ["Jwt:Audience"] = "yorungez-recovery-tests",
            ["Jwt:SigningKey"] = jwtMaterial, ["RateLimits:IdentityPerMinute"] = "1000",
            ["Email:RunOutboxWorker"] = "false", ["Email:Host"] = "127.0.0.1", ["Email:Port"] = "1",
            ["Email:Sender"] = "recovery@example.invalid", ["Email:FrontendBaseUrl"] = "http://localhost:3000",
            ["Email:RequireTls"] = "false", ["Email:UserName"] = "", ["Email:Password"] = ""
        }));
        builder.ConfigureServices(services =>
        {
            services.AddLogging(log => log.ClearProviders());
            services.RemoveAll<IEmailDelivery>(); services.AddSingleton<IEmailDelivery>(Email);
            foreach (var worker in services.Where(d => d.ServiceType == typeof(IHostedService)
                && d.ImplementationType == typeof(EmailOutboxWorker)).ToArray()) services.Remove(worker);
            services.RemoveAll<IDistributedCache>(); services.AddDistributedMemoryCache();
            // Program's ordinary Testing provider is ephemeral. This drill deliberately restores persisted keys.
            services.RemoveAll<IDataProtectionProvider>();
            services.AddSingleton<IDataProtectionProvider>(DataProtectionProvider.Create(new DirectoryInfo(ringPath), options =>
            {
                options.SetApplicationName("yorungez").ProtectKeysWithCertificate(certificate);
                options.Services.AddLogging(log => log.ClearProviders());
            }));
        });
    }

    public HttpClient Client() => CreateClient(new WebApplicationFactoryClientOptions
        { BaseAddress = new Uri("https://localhost"), AllowAutoRedirect = false, HandleCookies = false });
}
