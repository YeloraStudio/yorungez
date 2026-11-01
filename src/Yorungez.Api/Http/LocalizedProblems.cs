using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using System.Globalization;
using Yorungez.Application;

namespace Yorungez.Api.Http;

public static class LocalizedProblems
{
    public static async Task Write(HttpContext context, int status, string code)
    {
        var texts = context.RequestServices.GetRequiredService<ITextCatalog>();
        var culture = CultureInfo.CurrentUICulture.TwoLetterISOLanguageName;
        context.Response.StatusCode = status;
        var problem = new ProblemDetails { Status = status, Title = texts.Get("Common.Title", culture),
            Detail = texts.Get(code, culture), Type = "about:blank" };
        problem.Extensions["code"] = code;
        problem.Extensions["traceId"] = context.TraceIdentifier;
        await context.Response.WriteAsJsonAsync(problem, options: (System.Text.Json.JsonSerializerOptions?)null,
            contentType: "application/problem+json", cancellationToken: context.RequestAborted);
    }
}

public sealed class ApiExceptionHandler(ILogger<ApiExceptionHandler> logger) : IExceptionHandler
{
    public async ValueTask<bool> TryHandleAsync(HttpContext context, Exception error, CancellationToken ct)
    {
        var (status, code) = error switch
        {
            AppFailure e => (e.Kind switch { FailureKind.Validation => 400, FailureKind.Unauthorized => 401,
                FailureKind.Forbidden => 403, FailureKind.NotFound => 404, FailureKind.Conflict => 409, _ => 503 }, e.Code),
            BadHttpRequestException e => (e.StatusCode, e.StatusCode == 413 ? "Sky.RequestTooLarge" : "Common.InvalidInput"),
            _ => (500, "Common.Unexpected")
        };
        if (status == 500) logger.LogError("Request failed ({ExceptionType}); request data omitted. Trace {TraceId}.", error.GetType().Name, context.TraceIdentifier);
        await LocalizedProblems.Write(context, status, code);
        return true;
    }
}
