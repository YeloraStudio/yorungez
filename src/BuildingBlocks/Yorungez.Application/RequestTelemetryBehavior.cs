using System.Diagnostics;
using System.Diagnostics.Metrics;
using MediatR;

namespace Yorungez.Application;

public sealed class RequestTelemetryBehavior<TRequest, TResponse> : IPipelineBehavior<TRequest, TResponse>
    where TRequest : notnull
{
    private static readonly ActivitySource Activities = new("yorungez.application");
    private static readonly Meter Meter = new("yorungez.application");
    private static readonly Histogram<double> Duration = Meter.CreateHistogram<double>("cqrs.duration", "ms");

    public async Task<TResponse> Handle(TRequest request, RequestHandlerDelegate<TResponse> next, CancellationToken ct)
    {
        // Only the fixed request type is recorded. Never record request bodies, tokens or coordinates.
        using var activity = Activities.StartActivity(typeof(TRequest).Name);
        var started = Stopwatch.GetTimestamp();
        try { return await next(); }
        finally
        {
            Duration.Record(Stopwatch.GetElapsedTime(started).TotalMilliseconds,
                new KeyValuePair<string, object?>("request.type", typeof(TRequest).Name));
        }
    }
}
