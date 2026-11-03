using System.Collections.Concurrent;
using System.Net;
using System.Text.Json;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Serilog;
using Serilog.Core;
using Serilog.Events;
using Yorungez.Api.Http;
using Yorungez.Api.Localization;
using Yorungez.Application;

namespace Yorungez.Api.Tests;

public sealed class ApiLoggingTests
{
    private sealed class Capture : ILogEventSink
    {
        public ConcurrentQueue<LogEvent> Events { get; } = new();
        public void Emit(LogEvent logEvent) => Events.Enqueue(logEvent);
        public string[] Lines() => Events.Select(e => { var writer = new StringWriter(); new ApiJsonFormatter().Format(e, writer); return writer.ToString(); }).ToArray();
    }

    private static async Task<(WebApplication App, Capture Capture)> Start()
    {
        var capture = new Capture();
        var builder = WebApplication.CreateBuilder(new WebApplicationOptions { EnvironmentName = "Testing" });
        builder.WebHost.UseTestServer();
        builder.Logging.ClearProviders();
        builder.Services.AddSerilog(new LoggerConfiguration().MinimumLevel.Debug()
            .MinimumLevel.Override("Microsoft", LogEventLevel.Warning).WriteTo.Sink(capture).CreateLogger(), dispose: true);
        builder.Services.AddSingleton<ITextCatalog, TextCatalog>();
        builder.Services.AddExceptionHandler<ApiExceptionHandler>();
        builder.Services.AddProblemDetails();
        var app = builder.Build();
        app.UseRouting();
        app.UseMiddleware<HttpRequestTelemetry>();
        app.UseRequestLocalization(new RequestLocalizationOptions()
            .SetDefaultCulture("en").AddSupportedCultures("en", "tr").AddSupportedUICultures("en", "tr"));
        app.UseExceptionHandler();
        app.MapGet("/objects/{id}", () => Results.StatusCode(403));
        app.MapPost("/login", () => Results.StatusCode(401));
        app.MapGet("/health/ready", () => Results.Ok());
        app.MapPost("/limited", () => Results.StatusCode(429));
        app.MapGet("/fault", () => { ThrowPrivateFailure(); return Results.Ok(); });
        await app.StartAsync();
        return (app, capture);
    }

    private static void ThrowPrivateFailure() => throw new InvalidOperationException("PRIVATE_EXCEPTION password=PRIVATE_VALUE latitude=39.123456");

    [Fact]
    public async Task Requests_have_two_correlated_events_and_final_status_without_private_inputs()
    {
        var (app, capture) = await Start(); await using var owned = app;
        using var client = app.GetTestClient();
        using var request = new HttpRequestMessage(HttpMethod.Get, "/objects/PRIVATE_ROUTE?token=PRIVATE_QUERY");
        request.Headers.Add("Authorization", "Bearer PRIVATE_AUTH");
        request.Headers.Add("Cookie", "session=PRIVATE_COOKIE");
        request.Headers.Add("X-Request-ID", "PRIVATE_CALLER_ID");
        var response = await client.SendAsync(request);
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
        var lines = capture.Lines(); var combined = string.Join("", lines);
        Assert.DoesNotContain("PRIVATE_", combined);
        var events = lines.Select(line => JsonDocument.Parse(line)).Where(d => d.RootElement.TryGetProperty("RequestId", out _)).ToArray();
        Assert.Equal(2, events.Length);
        Assert.Equal("HttpRequestStarted", events[0].RootElement.GetProperty("Event").GetString());
        var completed = events[1].RootElement;
        Assert.Equal("/objects/{id}", completed.GetProperty("Route").GetString());
        Assert.Equal(403, completed.GetProperty("StatusCode").GetInt32());
        Assert.Equal("Warning", completed.GetProperty("Level").GetString());
        Assert.True(completed.GetProperty("ElapsedMs").GetDouble() >= 0);
        var id = completed.GetProperty("RequestId").GetString();
        Assert.True(Guid.TryParseExact(id, "N", out _));
        Assert.Equal(id, response.Headers.GetValues("X-Request-ID").Single());
        Assert.Equal(id, events[0].RootElement.GetProperty("RequestId").GetString());
    }

    [Fact]
    public async Task Handled_exception_is_an_error_with_safe_frames_and_problem_trace_correlation()
    {
        var (app, capture) = await Start(); await using var owned = app;
        using var client = app.GetTestClient(); var response = await client.GetAsync("/fault");
        Assert.Equal(HttpStatusCode.InternalServerError, response.StatusCode);
        var lines = capture.Lines(); var combined = string.Join("", lines);
        Assert.DoesNotContain("PRIVATE_", combined); Assert.DoesNotContain("39.123456", combined);
        using var completed = JsonDocument.Parse(lines.Single(line => line.Contains("HttpRequestCompleted")));
        Assert.Equal("Error", completed.RootElement.GetProperty("Level").GetString());
        Assert.Equal("System.InvalidOperationException", completed.RootElement.GetProperty("ExceptionType").GetString());
        Assert.NotEmpty(completed.RootElement.GetProperty("ExceptionFrames").EnumerateArray());
        using var problem = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        Assert.Equal(problem.RootElement.GetProperty("traceId").GetString(), completed.RootElement.GetProperty("RequestId").GetString());
    }

    [Fact]
    public async Task Probe_success_is_debug_and_unmatched_paths_are_never_logged_verbatim()
    {
        var (app, capture) = await Start(); await using var owned = app;
        using var client = app.GetTestClient(); await client.GetAsync("/health/ready"); await client.GetAsync("/PRIVATE_UNMATCHED?secret=PRIVATE_QUERY");
        var lines = capture.Lines(); Assert.DoesNotContain("PRIVATE_", string.Join("", lines));
        var documents = lines.Where(line => line.Contains("HttpRequestCompleted")).Select(line => JsonDocument.Parse(line)).ToArray();
        Assert.Equal("Debug", documents[0].RootElement.GetProperty("Level").GetString());
        Assert.Equal("[unmatched]", documents[1].RootElement.GetProperty("Route").GetString());
        Assert.Equal(404, documents[1].RootElement.GetProperty("StatusCode").GetInt32());
    }

    [Fact]
    public async Task Authentication_and_rate_limit_responses_keep_status_without_request_or_response_bodies()
    {
        var (app, capture) = await Start(); await using var owned = app;
        using var client = app.GetTestClient();
        foreach (var (path, status) in new[] { ("/login", 401), ("/limited", 429) })
        {
            using var response = await client.PostAsync(path, new StringContent("PRIVATE_BODY password=PRIVATE_SECRET"));
            Assert.Equal(status, (int)response.StatusCode);
        }
        var lines = capture.Lines();
        Assert.DoesNotContain("PRIVATE_", string.Join("", lines));
        var completed = lines.Where(line => line.Contains("HttpRequestCompleted")).Select(line => JsonDocument.Parse(line)).ToArray();
        Assert.Equal(new[] { 401, 429 }, completed.Select(d => d.RootElement.GetProperty("StatusCode").GetInt32()));
        Assert.All(completed, d => Assert.Equal("Warning", d.RootElement.GetProperty("Level").GetString()));
    }

    [Fact]
    public void Runtime_formatter_omits_framework_messages_properties_and_exception_data()
    {
        var capture = new Capture();
        using var logger = new LoggerConfiguration().WriteTo.Sink(capture).CreateLogger();
        var error = new Exception("PRIVATE_EXCEPTION"); error.Data["password"] = "PRIVATE_DATA";
        logger.ForContext("SourceContext", "Microsoft.Test").Error(error, "PRIVATE_TEMPLATE {Password} {RequestPath}", "PRIVATE_PASSWORD", "/PRIVATE_PATH");
        var line = Assert.Single(capture.Lines()); Assert.DoesNotContain("PRIVATE_", line);
        Assert.Contains("RuntimeDiagnostic", line); Assert.Contains("System.Exception", line);
    }
}
