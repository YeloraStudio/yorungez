# API request/response diagnostics — K-043

Serilog.AspNetCore 10.0.0 writes newline-delimited JSON to stdout. Portainer's API container Logs view and Docker collect the same stream. No additional logging service or database is required.

Each application request has `HttpRequestStarted` and `HttpRequestCompleted` events, joined by a server-generated `RequestId`. The response returns it as `X-Request-ID`; ProblemDetails returns the same value in `traceId`. Incoming request ID headers are ignored. W3C `TraceId`/`SpanId` are also recorded when available.

Completion fields include UTC `Timestamp`, `RequestMethod`, normalized `Route` (for example `/objects/{id}`), `StatusCode`, `ElapsedMs`, `Outcome`, environment and service. Unmatched URLs use `[unmatched]`. A request that never completes still has its start event; a process termination cannot produce a completion event. Requests rejected by Cloudflare, Traefik or Kestrel before application middleware require those services' own diagnostics.

| Result | Level |
| --- | --- |
| Ordinary successful request / redirect | Information |
| 4xx, including 401, 403 and 429 | Warning |
| 5xx | Error |
| Successful `/health/live` and `/health/ready` | Debug |
| Client cancellation observed by middleware | Warning, status 499 (diagnostic convention, not a guaranteed wire response) |

Exceptions include type and up to 40 method frames, without exception message, Data, file paths or argument values. `HandledFailure` means the API exception handler produced a response; `UnhandledFailure` means the failure escaped downstream middleware. Framework diagnostics retain source, event ID where available and safe exception details; free-form messages and arbitrary structured properties are deliberately omitted. This trades some message detail for protecting authentication and location data. Reproduce difficult failures with synthetic inputs in a controlled development environment.

Request and response bodies, authorization/cookies, query strings, raw URL paths and route values, coordinates, IP addresses, email addresses, personal notes and credentials are not collected by this logger. Request/response tracking means metadata, not payload capture. Do not add a raw payload sink or EF sensitive-data logging.

## Operations

In Portainer select the **api** container and open **Logs** with timestamps/follow as needed. Search for `HttpRequestCompleted`, an affected response's `X-Request-ID`, `"StatusCode":500`, or `"Level":"Error"`. A 401/429 warning is not necessarily an application defect. `ElapsedMs` measures time inside the application middleware, not network delivery or browser rendering.

From the production Compose directory (operator's shell):

```sh
docker compose --env-file .env -f compose.production.yaml logs --tail 100 -f api
```

`API_LOG_LEVEL` defaults to `Information`; set `Debug` temporarily in the private server environment to include healthy probes. Microsoft/System diagnostics stay at Warning. Changing environment/log-driver settings requires container recreation. Compose limits each API/migration container's Docker `json-file` logs to five files of 10 MB. This is bounded local retention, not durable cross-deployment history; container removal deletes its logs. Existing server logging policy and any external collector need operator verification.

## Validation and delivery

Five isolated TestServer/formatter tests verify correlation, safe route normalization, 401/403/404/429/500 levels, exception handling, probe noise and sensitive-data exclusion. Release API compilation passed. PostgreSQL/Redis-backed full integration and production log acceptance remain separate checks; local Docker was unavailable during this package. This change is prepared on a feature branch; live logging is not claimed until approved deployment and an operator verifies real requests in Portainer. Scientific and physical-device acceptance remain open.
