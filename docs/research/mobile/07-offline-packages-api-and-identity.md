# 07 — Offline packages, shared API and identity

**Status:** proposed mobile contract, preserving existing personal-data policy. **Traceability:** FR-06–09/11, ADR-0010/0013, K-046/048.

## Explicit offline capability matrix

| Capability | Offline baseline | Connected behaviour |
|---|---|---|
| Sky calculations and touch exploration | Bundled validated model plus general catalogue | Same local calculations; prepared content updates |
| Phone orientation and local camera | Available with hardware/permission and valid observer/time context | Network should not be required per pose frame |
| Object search, glossary, short EN/TR descriptions | Bundled reviewed subset | Optional extended prepared content |
| Object photographs and survey detail | Included/downloaded permitted packs | Fetch optional packs/details with clear size/source |
| Tonight and supported events | Local model and dated event package | Validated provider/model updates |
| Location | Manual coordinates; device fix subject to OS conditions | Foreground fix and shared place/zone helpers |
| Place name / coordinate timezone | Only what an explicitly downloaded subset can resolve | Existing services and future shared timezone contract |
| Weather / satellite freshness | Last permitted general snapshot, visibly dated; unknown when absent | Controlled refresh, expiry and provider error handling |
| Account / personal inventory | No new durable personal cache or write queue | Verified account; server-owned reads/writes |

The owner's general online/offline request does not explicitly reverse the earlier rule requiring server persistence for personal notes, favourites, observations and saved places. Offline discovery is a mobile requirement; persistent offline personal inventory remains a separate product decision. An unsaved in-memory draft must never be presented as successfully stored. [Current server-notebook policy](../../hesap-ve-sunucu-defteri.md), [general PWA boundary](../../hesap-menusu-ve-cevrimdisi-gokyuzu.md).

## Recommended storage design

Use a small reviewed general package inside the application so first launch works without downloading a large catalogue. Keep optional photographs, finer stars and survey tiles in versioned, independently removable packs. A local SQLite/Drift index is for public content and package metadata under current policy. Prefer managed background database execution for substantial queries. [Drift](https://pub.dev/packages/drift), [Drift isolates](https://drift.simonbinder.eu/isolates/).

The existing Web service worker is not the mobile offline implementation. Reuse canonical content/IDs, provenance and hashing, but build native package installation, file lifecycle and index migration. Content cache eviction, available storage and platform backup rules need explicit tests.

### Proposed package manifest

Fields: package ID/version, schema/model compatibility, locale set, dataset epoch/release, retrieval/build times, licence-manifest reference, compressed/uncompressed sizes, file digests, expiry/freshness policy and supported application range. Add authenticated manifest/signature design if remote updates are enabled. An ordinary SHA-256 hash detects corruption only relative to a trusted expected hash; it does not by itself establish publisher identity.

Recommended installation sequence: inspect compatibility/space → download to staging with bounded retries → verify size/digests/authenticity as designed → validate schema/index and licence metadata → atomically activate → retain previous usable package until cleanup. Limit extraction paths and decompressed size. Interruption, cancellation, invalid package, full disk and old app version must leave a working base sky. These are design requirements, not implemented mobile behaviour.

Prefer a straightforward foreground/manual update flow first. Background work can be suspended or denied by the OS; exact update times are not promised. Event/ephemeris data must not be replaced by downloaded executable code.

Android WorkManager and Apple Background Tasks are candidates for later constrained content refresh, not continuously running the camera/IMU. Evaluate them only after the foreground update flow is reliable. [Android scheduling](https://developer.android.com/develop/background-work/background-tasks/persistent), [Apple Background Tasks](https://developer.apple.com/documentation/backgroundtasks).

## Shared API contract inventory

Repository inspection confirms `/api/v1/catalog/sky`, `/catalog/overlays`, `/events/calendar`, `/locations/places`, `/sky/positions`, `/sky/horizon-crossings`, `/auth/*`, terminology and notebook APIs. Coordinate-bearing computation paths use the existing POST/no-store policy. Preserve that policy rather than putting precise coordinates into shareable URLs.

Preparation gaps:

- Generate a reviewed OpenAPI contract and verify a Dart client/model sample; describe stable errors, language, UTC, units, nullable values, pagination, revisions and model/data versions.
- Consolidate or explicitly expose timezone resolution and object article/image metadata currently served partly through Next.js.
- Define a general package-manifest endpoint and cache semantics without opening personal responses to shared caching.
- Exercise older client/newer server compatibility and unknown future fields/event types.

ASP.NET Core supports first-party OpenAPI generation; it is an appropriate preparation route, not an already-enabled feature in this baseline. [Microsoft OpenAPI documentation](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/openapi/overview?view=aspnetcore-10.0).

## Authentication, language and links

Use the existing Bearer-token path for mobile; retain the browser's separate cookie/BFF/CSRF protection. The custom JWT API is not automatically an OAuth/OIDC provider, so adding an unrelated OAuth SDK/PKCE flow is not presumed necessary.

Recommended mobile session behaviour: access token in memory, rotating refresh credential in platform secure storage, one refresh operation shared by concurrent requests, bounded retry, explicit expired/revoked states and reliable sign-out/account switching. Test native storage restore/migration and server revocation. [Secure-storage candidate](https://pub.dev/packages/flutter_secure_storage), [Dio](https://pub.dev/packages/dio). These lifecycle behaviours still need native implementation and API contract tests.

Read/write the same `preferredLanguage` field as Web. Start in English without a known explicit preference; apply the account preference after login, then let the user change it. Language is non-sensitive local configuration; no token or personal inventory belongs in a preferences file. [Existing language contract](../../account-language-preference.md).

Use verified Android App Links and iOS Universal Links on the owned domain for confirmation/reset and stable public object routes. Serve the appropriate association files and test installed/uninstalled, cold/warm and expired-link cases. Avoid logging one-time tokens or including user coordinates in links. Native links still need to preserve a working Web fallback. [Android links](https://docs.flutter.dev/cookbook/navigation/set-up-app-links), [iOS links](https://docs.flutter.dev/cookbook/navigation/set-up-universal-links).

## Failure semantics

Distinguish no transport, captive portal, API timeout, server failure, unauthorized session, unconfirmed account, revision conflict and stale public content. A Wi-Fi indicator does not prove API reachability. [Connectivity plugin guidance](https://pub.dev/packages/connectivity_plus).

Cancel obsolete searches/downloads; do not automatically retry non-idempotent personal writes without a server-supported strategy. Reconnect must not overwrite a user's local language choice or silently reapply an old observer. General offline exploration remains usable while account services are unavailable.
