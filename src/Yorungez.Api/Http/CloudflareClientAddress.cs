using System.Net;
using Microsoft.Extensions.Primitives;

namespace Yorungez.Api.Http;

/// <summary>
/// Restores the visitor address when the site is proxied by Cloudflare.
/// The forwarded-headers middleware runs first and resolves the address that
/// Traefik saw (directly, or through the Web BFF). Only when that address is a
/// Cloudflare edge is the edge's <c>CF-Connecting-IP</c> header trusted. A request
/// that reaches the origin without Cloudflare keeps its own address, whatever
/// headers it carries.
/// </summary>
public static class CloudflareClientAddress
{
    public const string HeaderName = "CF-Connecting-IP";

    // https://www.cloudflare.com/ips-v4 and /ips-v6, fetched 2026-11-03
    // (api.cloudflare.com/client/v4/ips etag 38f79d050aa027e3be3865e495dcc9bc).
    // A new edge range that is missing here only degrades to the edge address,
    // which is the behaviour before this class existed.
    public static readonly IReadOnlyList<IPNetwork> EdgeNetworks = new[]
    {
        "173.245.48.0/20", "103.21.244.0/22", "103.22.200.0/22", "103.31.4.0/22",
        "141.101.64.0/18", "108.162.192.0/18", "190.93.240.0/20", "188.114.96.0/20",
        "197.234.240.0/22", "198.41.128.0/17", "162.158.0.0/15", "104.16.0.0/13",
        "104.24.0.0/14", "172.64.0.0/13", "131.0.72.0/22",
        "2400:cb00::/32", "2606:4700::/32", "2803:f800::/32", "2405:b500::/32",
        "2405:8100::/32", "2a06:98c0::/29", "2c0f:f248::/32",
    }.Select(IPNetwork.Parse).ToArray();

    /// <summary>Returns the visitor address, or null when the request did not come through a Cloudflare edge.</summary>
    public static IPAddress? Resolve(IPAddress? resolvedPeer, StringValues header, IReadOnlyList<IPNetwork> edges)
    {
        if (resolvedPeer is null || edges.Count == 0 || header.Count != 1) return null;
        var peer = Normalize(resolvedPeer);
        if (!edges.Any(network => network.Contains(peer))) return null;
        return IPAddress.TryParse(header[0]?.Trim(), out var client) ? Normalize(client) : null;
    }

    public static Func<HttpContext, RequestDelegate, Task> Middleware(IReadOnlyList<IPNetwork> edges) => (context, next) =>
    {
        if (Resolve(context.Connection.RemoteIpAddress, context.Request.Headers[HeaderName], edges) is { } client)
            context.Connection.RemoteIpAddress = client;
        return next(context);
    };

    private static IPAddress Normalize(IPAddress address) => address.IsIPv4MappedToIPv6 ? address.MapToIPv4() : address;
}
