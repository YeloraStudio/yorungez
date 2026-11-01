using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Distributed;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Yorungez.Identity.Infrastructure.Persistence;

namespace Yorungez.Api.Http;

public sealed class IdentityReadiness(IdentityStore store) : IHealthCheck
{
    public async Task<HealthCheckResult> CheckHealthAsync(HealthCheckContext context, CancellationToken ct = default)
    {
        try
        {
            if (!await store.Database.CanConnectAsync(ct)
                || (await store.Database.GetPendingMigrationsAsync(ct)).Any()) return HealthCheckResult.Unhealthy();
            // A listening server alone does not prove the application's schema is usable.
            _ = await store.Users.AsNoTracking().Select(u => u.Id).Take(1).ToArrayAsync(ct);
            return HealthCheckResult.Healthy();
        }
        catch (Exception ex) when (ex is not OperationCanceledException) { return HealthCheckResult.Unhealthy(); }
    }
}

public sealed class CacheReadiness(IDistributedCache cache) : IHealthCheck
{
    public async Task<HealthCheckResult> CheckHealthAsync(HealthCheckContext context, CancellationToken ct = default)
    {
        var key = "yorungez:health:" + Guid.NewGuid().ToString("N");
        try
        {
            await cache.SetStringAsync(key, "1", new DistributedCacheEntryOptions
                { AbsoluteExpirationRelativeToNow = TimeSpan.FromSeconds(5) }, ct);
            var value = await cache.GetStringAsync(key, ct);
            await cache.RemoveAsync(key, ct);
            return value == "1" ? HealthCheckResult.Healthy() : HealthCheckResult.Degraded();
        }
        catch (Exception ex) when (ex is not OperationCanceledException) { return HealthCheckResult.Degraded(); }
    }
}
