using System.Net;
using Microsoft.Extensions.Primitives;
using Yorungez.Api.Http;

namespace Yorungez.Api.Tests;

public sealed class CloudflareClientAddressTests
{
    private static readonly IReadOnlyList<IPNetwork> Edges = CloudflareClientAddress.EdgeNetworks;
    private static readonly IPAddress Edge = IPAddress.Parse("172.70.1.10");

    [Fact]
    public void Edge_peer_with_a_single_header_yields_the_visitor()
    {
        Assert.Equal(IPAddress.Parse("203.0.113.7"), CloudflareClientAddress.Resolve(Edge, "203.0.113.7", Edges));
        Assert.Equal(IPAddress.Parse("2001:db8::7"),
            CloudflareClientAddress.Resolve(IPAddress.Parse("2606:4700:10::1"), " 2001:db8::7 ", Edges));
    }

    [Fact]
    public void Direct_to_origin_request_cannot_choose_its_address()
    {
        // Cloudflare bypassed: Traefik saw the caller itself, so the header is the caller's claim.
        Assert.Null(CloudflareClientAddress.Resolve(IPAddress.Parse("198.51.100.20"), "203.0.113.7", Edges));
        Assert.Null(CloudflareClientAddress.Resolve(IPAddress.Parse("10.89.0.3"), "203.0.113.7", Edges));
    }

    [Fact]
    public void Missing_repeated_or_malformed_header_keeps_the_edge_address()
    {
        Assert.Null(CloudflareClientAddress.Resolve(Edge, StringValues.Empty, Edges));
        Assert.Null(CloudflareClientAddress.Resolve(Edge, new StringValues(["203.0.113.7", "203.0.113.8"]), Edges));
        Assert.Null(CloudflareClientAddress.Resolve(Edge, "not-an-address", Edges));
        Assert.Null(CloudflareClientAddress.Resolve(null, "203.0.113.7", Edges));
        Assert.Null(CloudflareClientAddress.Resolve(Edge, "203.0.113.7", []));
    }

    [Fact]
    public void Mapped_ipv4_addresses_are_compared_and_returned_as_ipv4()
    {
        var mappedEdge = IPAddress.Parse("::ffff:172.70.1.10");
        Assert.Equal(IPAddress.Parse("203.0.113.7"),
            CloudflareClientAddress.Resolve(mappedEdge, "::ffff:203.0.113.7", Edges));
    }

    [Fact]
    public void Edge_list_matches_the_published_cloudflare_ranges()
    {
        Assert.Equal(22, Edges.Count);
        Assert.Equal(15, Edges.Count(n => n.BaseAddress.AddressFamily == System.Net.Sockets.AddressFamily.InterNetwork));
    }
}
