# Mobile night planning, calendar and reminders — K-055

Owner request: 5 November 2026. Implementation and local verification: 6 November 2026. Physical-device acceptance, store signing and submission remain separate gates.

## Required delivery

1. Pull upstream before development; retain other contributors' changes. Baseline `700a762` includes the Web container security update from PR #30.
2. Add native **Tonight**, **Calendar** and **Reminders** routes with back navigation, paired English/Turkish text and portrait/landscape layouts. Keep the full-screen sky as home.
3. Reuse the canonical sourced event snapshot and pinned Astronomy Engine. Calculate standard sunset/sunrise and eight Solar System visibility rows offline; never equate geometric availability with guaranteed detection. Preserve polar states, sea-level/refraction definitions and source provenance.
4. Show a human-readable local date/time, explicit IANA zone/GMT offset and UTC instant. Obtain the device's configured zone without a location upload, allow an explicit zone choice for travel/manual viewpoints, handle DST month/night boundaries. A calendar event is a global instant; it is not a promise of local visibility.
5. Selecting an event or an observing interval opens the corresponding target at the requested UTC instant in an explicitly labelled sky simulation. Provide one-action return to live time. Notes/favourites preserve that event context.
6. Verified accounts can create, inspect and cancel server-owned email reminders for calendar events and Tonight observing times. No anonymous personal persistence or offline write queue. Validate canonical event IDs on the server, preserve UTC/time-zone snapshots, bound lead time/count and reject already-due reminders. Owner/revision checks prevent cross-account writes and silent overwrites.
7. A durable multi-instance-safe scheduler provides leases, bounded retries, expiry/cancellation and privacy-safe diagnostics. Resolve a verified recipient through Identity's public contract; never accept an arbitrary recipient, HTML or mail URL from clients. English branded HTML/plain-text email. SMTP acceptance is distinct from inbox delivery; a crash after SMTP acceptance can cause a duplicate (at-least-once boundary).
8. Establish a channel-neutral delivery contract and explicit capability response for future APNs/FCM push. Push is unavailable until providers, signing/credentials, consent, registration and physical-device acceptance exist; do not add unused notification permissions or pretend push is delivered.
9. After development and tests, generate native icon size/density/adaptive/monochrome and iOS assets from the existing owner logo. Preserve logo masters; validate safe areas/alpha and keep source attribution.
10. Then capture genuine English emulator screens with public example coordinates and no personal account information. Produce a Google Play feature graphic and eight polished English promotional screenshots. Preserve actual app UI; do not invent capabilities or reuse competitor art. Archive raw captures, final prompts, outputs and dimensions. Store submission/signing remain separate.

## Traceability

FR-04 (time/events), FR-05 (visibility), FR-06/07 (private verified-account records), FR-08 (sourced data), FR-11 (EN/TR); UJ-02/03/04/06/07; AC-03/05/06/07/08/09/10/12/13. Existing identifiers, offline public/private separation and open physical-device gates remain intact.

## Verification required

- Native night calculations against the same frozen USNO/Web reference fixtures; ordinary/polar/DST/date-line cases and bounded worker lifecycle.
- Calendar fingerprint, UTC/local month rollover and paired EN/TR layouts.
- Real disposable PostgreSQL tests: auth/owner/revision/idempotency, stale/past/invalid/capacity inputs, cancellation, lease competition, SMTP success/retry/expiry and no sensitive mail/coordinate logging.
- Flutter auth expiry/account changes while reminders are loading or saving; source/target/time navigation, offline public planning and actionable private-network failures.
- Format/analyse/application/science/publication checks and Android build; iOS unsigned CI build when available. Physical sensor/push/store acceptance remains separate.

## Store specifications consulted

- [Google Play preview assets](https://support.google.com/googleplay/android-developer/answer/9866151?hl=en): feature graphic 1024×500, store icon 512×512, at least two and up to eight screenshots per supported device type. Eight phone images are a chosen showcase set, not a universal mandatory count.
- [Android adaptive icons](https://developer.android.com/develop/ui/compose/system/icon_design_adaptive): independent layers and the central 66dp safe zone within 108dp.
- [Apple icon asset catalogue](https://developer.apple.com/documentation/xcode/configuring-your-app-icon-using-an-asset-catalog): existing native asset catalogue and 1024px master.

## Evidence

- Upstream was fast-forwarded to `700a762` before work. No Web/container security change from PR #30 was overwritten.
- **166 .NET tests passed** (18 core, 19 astronomy, 129 real-PostgreSQL API tests). Fourteen reminder tests exercise authorization/owner scope, canonical-event tampering, revision/duplicate/capacity rules, cancellation, competing claims, expiry/retry, and captured English local/UTC email. No test sends to a real recipient.
- **77 Flutter tests passed**, including EN/TR at 320×640 and 844×390, IANA local-month filtering, fractional offsets, 23/25-hour DST nights, zone bootstrap/manual-choice races, stale private requests after sign-out, dismissed asynchronous reminder sheets and explicit simulation labels on object details.
- Native planning matches **22 frozen USNO rise/set references** within **25.481 seconds** (unchanged 180-second acceptance bound). Across eight Web parity windows, **119 crossings** differ by at most **0.001020 seconds**. Fixtures cover ordinary latitudes, polar day/night, date-line and DST boundaries.
- Existing native astrometry checks passed: 1,166 JPL solar comparisons (maximum 0.335458 arcmin), 144 star comparisons (0.307578 arcmin), 72 deep-sky comparisons (0.427525 arcmin), and 1,166 pinned JavaScript/C comparisons. Existing polar-azimuth exclusions remain explicit.
- Clean Flutter analysis; Android x64 emulator build and genuine public-example capture flow passed. The [current manual Android/macOS verification](https://github.com/YeloraStudio/yorungez/actions/runs/42122469454) built the unsigned iOS application successfully from application commit `cb41895`; the [PR Android check](https://github.com/YeloraStudio/yorungez/actions/runs/42122470464) also passed. Subsequent evidence-only edits do not change that application source. Emulator/build checks do not establish physical pointing accuracy.
- Existing logo exports include opaque iOS 1024px, Play 512px, Android legacy densities, adaptive foreground and monochrome layers. Every visible adaptive foreground pixel fits the central 66/108 safe circle. [Masters and hashes](../data/branding/mobile/manifest.json).
- [English Google Play assets, capture provenance and regeneration](../data/store/google-play/en-US/README.md): eight genuine app screens with decorative surrounds, a feature graphic, icon and review sheet. No store upload or production signing was performed.

## Runtime and API contract

The existing Notebook module owns `notebook.Reminders`; Identity resolves the currently verified recipient through `IAccountReminderEmail`. API bridges use public module contracts and server-owned canonical event titles/source URLs. There is no cross-module table read, client-supplied recipient/HTML, private browser/mobile cache or personal offline write queue.

Authenticated, verified, owner-scoped, rate-limited, no-store routes under `/api/v1/notebook`:

| Route | Contract |
| --- | --- |
| `GET /reminders` | Account-owned active/recent reminders, at most 500 |
| `POST /reminders` | ID/revision, canonical event ID or bounded observing target/time, UTC instant, IANA zone, lead minutes; cancellation uses the same revision contract |
| `GET /notification-capabilities` | Email enabled; push disabled; currently supported channels: email |

Lead choices are 0/10/30/60/180/1440 minutes; delivery must be at least two minutes in the future, event horizon at most 366 days, and an account can have 100 active reminders. Active duplicate prevention includes the channel; cancellation releases that key so the same event can be scheduled again. Known calendar IDs/instants are validated against the sourced snapshot. Tonight observing-time reminders are labelled as observing plans, not newly discovered global events or guaranteed local visibility.

The 15-second worker uses atomic PostgreSQL claims, two-minute leases, 30-second delivery timeouts and at most eight attempts with bounded exponential backoff. Missed events expire; zero-lead reminders have a five-minute delivery grace. An in-flight claim cannot reliably be recalled. SMTP acceptance is reported separately from inbox arrival; a process crash after SMTP acceptance can produce a duplicate. Logs omit recipient, title, coordinates, links and message payload.

`IReminderChannel`, the persisted channel and explicit capabilities are the future push boundary. APNs/FCM credentials, platform registration/rotation, consent, provider delivery, notification deep links and physical-device tests must be implemented before advertising push support. No unused notification permissions were added.

Device time-zone retrieval is a small Android/iOS channel; offline conversions use pinned `timezone` 0.11.2 / tzdb 2025c. Explicit manual selection wins a concurrent device bootstrap. Device refresh follows foreground resume unless a manual zone is selected. Coordinates do not silently imply a political time zone: travellers/manual viewpoints can select it explicitly. Keep tzdb current through a reviewed dependency update.

Full-screen sky remains home. Tonight uses local noon-to-noon night boundaries and standard sea-level rise/set semantics; geometric centre altitude and detection conditions remain separate. Calendar uses all twelve existing sourced event types and filters by local month. Selected times are explicit simulations, with one-action **Back to live**. A shared serial worker coalesces pending plans; stale frames are cleared on time-mode changes. Notes/favourites preserve the selected event instant.


## Publication and owner artifacts

[PR #31](https://github.com/YeloraStudio/yorungez/pull/31) records source review, final-head CI and the authorized merge. The linked main-branch CI records API/Web image publication, migration and rollout; check its actual conclusion rather than inferring a deployment from a successful local build. Publication scanning compared staged files with local private values without printing them; full-history Gitleaks found no leaks. Production secrets, APK binaries, signing keys and private emulator data are excluded from Git.

Owner-test Android package: **0.1.0+4**, ARM64 profile, versionCode **2004**, existing development certificate, APK SHA-256 `7c882c32aa6c98540d15321da8f11b727eb507a487fcfec07802733d52816c33`. It is an update over the previous owner build and is not a signed store release. Native icon catalogue validation covered 25 iOS entries; all final store-image dimensions, alpha and hashes were checked.
