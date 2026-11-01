using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Distributed;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Microsoft.Extensions.Hosting;
using Npgsql;
using System.Collections.Concurrent;
using System.Security.Cryptography;
using System.Text.Json;
using Yorungez.Identity.Application;
using Yorungez.Identity.Infrastructure;
using Yorungez.Identity.Infrastructure.Persistence;
using Yorungez.Notebook.Infrastructure;

namespace Yorungez.Api.Tests;

public sealed class CapturedEmailDelivery : IEmailDelivery
{
    public ConcurrentQueue<EmailMessage> Messages { get; } = new();
    public bool FailNext { get; set; }
    public Task SendAsync(EmailMessage message, CancellationToken ct)
    {
        if (FailNext) { FailNext = false; throw new IOException("Synthetic delivery failure."); }
        Messages.Enqueue(message);
        return Task.CompletedTask;
    }
}

public sealed class AppFactory : WebApplicationFactory<Program>, IAsyncLifetime
{
    private readonly Dictionary<string, string?> _settings;
    private readonly string _adminConnection;
    private readonly string _database = "yorungez_test_" + Guid.NewGuid().ToString("N");
    private bool _created;
    public CapturedEmailDelivery Email { get; } = new();
    public bool CacheUnavailable { get; init; }
    public int RateLimit { get; init; } = 1000;
    public string SigningKey => _settings["Jwt:SigningKey"]!;

    public AppFactory()
    {
        var root = new DirectoryInfo(AppContext.BaseDirectory);
        while (root is not null && !File.Exists(Path.Combine(root.FullName, "Yorungez.slnx"))) root = root.Parent;
        if (root is null) throw new InvalidOperationException("Cannot find the solution root.");
        var localFile = Path.Combine(root.FullName, "src", "Yorungez.Api", "appsettings.Local.json");
        using var local = JsonDocument.Parse(File.ReadAllText(localFile));
        var supplied = Environment.GetEnvironmentVariable("YORUNGEZ_TEST_POSTGRES")
            ?? local.RootElement.GetProperty("ConnectionStrings").GetProperty("Identity").GetString()!;
        var connection = new NpgsqlConnectionStringBuilder(supplied);
        if (connection.Host is not ("127.0.0.1" or "localhost"))
            throw new InvalidOperationException("Integration tests require an explicitly local PostgreSQL instance.");
        connection.Database = "postgres";
        _adminConnection = connection.ConnectionString;
        connection.Database = _database;
        _settings = new()
        {
            ["ConnectionStrings:Identity"] = connection.ConnectionString,
            ["ConnectionStrings:Redis"] = local.RootElement.GetProperty("ConnectionStrings").GetProperty("Redis").GetString(),
            ["Jwt:Issuer"] = "https://yorungez.test", ["Jwt:Audience"] = "yorungez-tests",
            ["Jwt:SigningKey"] = Convert.ToBase64String(RandomNumberGenerator.GetBytes(64)),
            ["Email:RunOutboxWorker"] = "false", ["Email:FrontendBaseUrl"] = "http://localhost:3000",
            ["Email:Host"] = "127.0.0.1", ["Email:RequireTls"] = "false"
        };
    }

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");
        _settings["RateLimits:IdentityPerMinute"] = RateLimit.ToString(System.Globalization.CultureInfo.InvariantCulture);
        builder.ConfigureAppConfiguration((_, c) => c.AddInMemoryCollection(_settings));
        builder.ConfigureServices(services =>
        {
            services.RemoveAll<IEmailDelivery>();
            services.AddSingleton<IEmailDelivery>(Email);
            foreach (var descriptor in services.Where(d => d.ServiceType == typeof(IHostedService)
                && d.ImplementationType == typeof(EmailOutboxWorker)).ToArray()) services.Remove(descriptor);
            if (CacheUnavailable)
            {
                services.RemoveAll<IDistributedCache>();
                services.AddSingleton<IDistributedCache, UnavailableCache>();
            }
        });
    }

    public async Task InitializeAsync()
    {
        await using var admin = new NpgsqlConnection(_adminConnection);
        await admin.OpenAsync();
        await using var create = new NpgsqlCommand($"CREATE DATABASE \"{_database}\"", admin);
        await create.ExecuteNonQueryAsync();
        _created = true;
        await using var scope = Services.CreateAsyncScope();
        await scope.ServiceProvider.GetRequiredService<IdentityStore>().Database.MigrateAsync();
        await scope.ServiceProvider.GetRequiredService<NotebookDatabase>().Database.MigrateAsync();
    }

    public HttpClient Client(string language = "en")
    {
        var client = CreateClient(new WebApplicationFactoryClientOptions { BaseAddress = new Uri("https://localhost"), AllowAutoRedirect = false });
        client.DefaultRequestHeaders.AcceptLanguage.ParseAdd(language);
        return client;
    }

    public async Task DispatchAsync()
    {
        await using var scope = Services.CreateAsyncScope();
        await scope.ServiceProvider.GetRequiredService<EmailOutboxDispatcher>().DispatchOnceAsync(default);
    }

    async Task IAsyncLifetime.DisposeAsync()
    {
        await base.DisposeAsync();
        if (!_created) return;
        if (!System.Text.RegularExpressions.Regex.IsMatch(_database, "^yorungez_test_[a-f0-9]{32}$"))
            throw new InvalidOperationException("Unexpected integration database cleanup target.");
        await using var admin = new NpgsqlConnection(_adminConnection);
        await admin.OpenAsync();
        await using var drop = new NpgsqlCommand($"DROP DATABASE \"{_database}\" WITH (FORCE)", admin);
        await drop.ExecuteNonQueryAsync();
    }
}

internal sealed class UnavailableCache : IDistributedCache
{
    private static IOException Error() => new("Synthetic cache outage.");
    public byte[]? Get(string key) => throw Error();
    public Task<byte[]?> GetAsync(string key, CancellationToken token = default) => throw Error();
    public void Refresh(string key) => throw Error();
    public Task RefreshAsync(string key, CancellationToken token = default) => throw Error();
    public void Remove(string key) => throw Error();
    public Task RemoveAsync(string key, CancellationToken token = default) => throw Error();
    public void Set(string key, byte[] value, DistributedCacheEntryOptions options) => throw Error();
    public Task SetAsync(string key, byte[] value, DistributedCacheEntryOptions options, CancellationToken token = default) => throw Error();
}
