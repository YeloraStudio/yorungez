using System.Diagnostics;
using System.Text.Json;
using Microsoft.AspNetCore.Routing;
using Serilog;
using Serilog.Events;
using Serilog.Formatting;

namespace Yorungez.Api.Http;

public static class ApiLogging
{
    public static Serilog.Core.Logger CreateLogger(IConfiguration configuration, string environment)
    {
        if (!Enum.TryParse<LogEventLevel>(configuration["Serilog:MinimumLevel:Default"] ?? "Warning", true, out var level) || !Enum.IsDefined(level))
            throw new InvalidOperationException("Invalid API log level.");
        return new LoggerConfiguration().MinimumLevel.Is(level)
            .MinimumLevel.Override("Microsoft", LogEventLevel.Warning)
            .MinimumLevel.Override("System", LogEventLevel.Warning)
            .Enrich.FromLogContext()
            .Enrich.WithProperty("Environment", environment)
            .WriteTo.Console(new ApiJsonFormatter()).CreateLogger();
    }

    public static string[] ExceptionFrames(Exception error) =>
        (new StackTrace(error, false).GetFrames() ?? []).Take(40)
        .Select(frame => frame.GetMethod())
        .Where(method => method is not null)
        .Select(method => $"{method!.DeclaringType?.FullName}.{method.Name}").ToArray();
}

// Only approved fields are serialized. Framework messages, SQL, arbitrary properties,
// exception messages/Data and raw stack strings can contain private request values.
public sealed class ApiJsonFormatter : ITextFormatter
{
    private static readonly string[] RequestFields = ["Event", "RequestId", "TraceId", "SpanId", "RequestMethod",
        "Route", "StatusCode", "ElapsedMs", "Outcome", "ExceptionType", "ExceptionFrames"];

    public void Format(LogEvent logEvent, TextWriter output)
    {
        var fields = new Dictionary<string, object?>
        {
            ["Timestamp"] = logEvent.Timestamp.ToUniversalTime(), ["Level"] = logEvent.Level.ToString(),
            ["Service"] = "yorungez-api"
        };
        var source = logEvent.Properties.GetValueOrDefault("SourceContext") as ScalarValue;
        fields["Source"] = source?.Value;
        fields["Environment"] = (logEvent.Properties.GetValueOrDefault("Environment") as ScalarValue)?.Value;
        if (Equals(source?.Value, typeof(HttpRequestTelemetry).FullName))
        {
            foreach (var name in RequestFields)
                if (logEvent.Properties.TryGetValue(name, out var value)) fields[name] = Value(value);
        }
        else if (Equals(source?.Value, typeof(Yorungez.Identity.Infrastructure.EmailOutboxDispatcher).FullName)
            || Equals(source?.Value, typeof(Yorungez.Identity.Infrastructure.EmailOutboxWorker).FullName))
        {
            foreach (var name in new[] { "Event", "FailureCategory", "ExceptionType", "SmtpStatusCode", "Attempt" })
                if (logEvent.Properties.TryGetValue(name, out var value)) fields[name] = Value(value);
        }
        else
        {
            fields["Event"] = "RuntimeDiagnostic";
            if (logEvent.Properties.TryGetValue("EventId", out var id)) fields["EventId"] = Value(id);
        }
        if (logEvent.Exception is { } exception)
        {
            fields["ExceptionType"] = exception.GetType().FullName;
            fields["ExceptionFrames"] = ApiLogging.ExceptionFrames(exception);
        }
        output.WriteLine(JsonSerializer.Serialize(fields));
    }

    private static object? Value(LogEventPropertyValue value) => value switch
    {
        ScalarValue scalar => scalar.Value,
        SequenceValue sequence => sequence.Elements.Select(Value).ToArray(),
        // Event IDs are structured framework metadata; arbitrary structures are not emitted.
        StructureValue structure => structure.Properties.Where(p => p.Name == "Id")
            .ToDictionary(p => p.Name, p => Value(p.Value)),
        _ => null
    };
}

public sealed class HttpRequestTelemetry(RequestDelegate next, ILogger<HttpRequestTelemetry> logger)
{
    public static readonly object FailureKey = new();

    public async Task InvokeAsync(HttpContext context)
    {
        var started = Stopwatch.GetTimestamp();
        var requestId = Guid.NewGuid().ToString("N");
        context.TraceIdentifier = requestId;
        context.Response.Headers["X-Request-ID"] = requestId;
        var route = (context.GetEndpoint() as RouteEndpoint)?.RoutePattern.RawText ?? "[unmatched]";
        // Emit only application-owned constants, never the original input string.
        var method = context.Request.Method switch
        {
            "GET" => "GET", "POST" => "POST", "PUT" => "PUT", "PATCH" => "PATCH",
            "DELETE" => "DELETE", "HEAD" => "HEAD", "OPTIONS" => "OPTIONS", _ => "OTHER"
        };
        var trace = Activity.Current?.TraceId.ToString();
        var span = Activity.Current?.SpanId.ToString();
        logger.Log(LogLevel.Debug,
            "{Event} {RequestMethod} {Route} request={RequestId} trace={TraceId} span={SpanId}",
            "HttpRequestStarted", method, route, requestId, trace, span);
        Exception? failure = null;
        var unhandled = false;
        try { await next(context); }
        catch (Exception error) { failure = error; unhandled = true; throw; }
        finally
        {
            failure ??= context.Items.TryGetValue(FailureKey, out var value) ? value as Exception : null;
            var aborted = failure is OperationCanceledException && context.RequestAborted.IsCancellationRequested;
            var status = aborted ? 499 : failure is not null && context.Response.StatusCode < 400 ? 500 : context.Response.StatusCode;
            var elapsedMs = Math.Round(Stopwatch.GetElapsedTime(started).TotalMilliseconds, 3);
            var slow = elapsedMs >= 1000;
            var level = status >= 500 ? LogLevel.Error
                : slow ? LogLevel.Warning
                : aborted ? LogLevel.Debug
                : status is 401 or 403 or 404 ? LogLevel.Information
                : status >= 400 ? LogLevel.Warning : LogLevel.Debug;
            logger.Log(level,
                "{Event} {RequestMethod} {Route} status={StatusCode} elapsed={ElapsedMs} outcome={Outcome} request={RequestId} trace={TraceId} span={SpanId} exception={ExceptionType} frames={ExceptionFrames}",
                "HttpRequestCompleted", method, route, status, elapsedMs,
                aborted ? "ClientAborted" : unhandled ? "UnhandledFailure" : failure is not null ? "HandledFailure" : slow ? "SlowRequest" : "Completed", requestId, trace, span,
                failure?.GetType().FullName, failure is null ? null : ApiLogging.ExceptionFrames(failure));
        }
    }
}
