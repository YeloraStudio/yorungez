# Mobile sky-first delivery plan — K-050

**K-051 follow-up:** [Current immersive implementation/evidence](mobile-immersive-discovery-evidence.md) supersedes the historical manual-zoom, deferred-art/track/satellite and manual-only Android alignment baseline below. Physical/iOS and remaining app-parity gates remain open.

**Owner direction: 4 November 2026.** This plan supersedes the catalogue-as-home foundation and the mobile photographic-landscape candidate. It preserves Flutter Android/iOS, the existing .NET backend, free/ad-free operation, English default with Turkish parity, the supplied brand assets/palette, scientific provenance and verified-account/server-owned personal records.

## Reference interpretation and product goal

All seven supplied screenshots were inspected. They are visual/interaction references, not reusable artwork, code, music or scientific reference data.

| Reference | Observed design | Yorungez requirement |
|---|---|---|
| 1 — current Yorungez catalogue | Catalogue list occupies home | Move catalogue to search; home becomes the full-screen sky |
| 2 — Jupiter portrait | Dark sky, star glow, constellation outline, reticle, azimuth/elevation, short selection summary, edge controls | Real computed positions; restrained source-backed sprites/labels; large touch targets and expandable details |
| 3 — ISS landscape | Same scene fills the wide viewport, selected satellite over a galactic background | Responsive portrait/landscape projection and controls; ISS requires a separate validated SGP4/fresh-GP data pipeline, never a decorative invented orbit |
| 4 — Al Nair | Direction labels, horizon, above-horizon summary and centre selection | Geometric horizon/cardinal guides; actual visibility is separate from geometry |
| 5 — Orion | Constellation lines/art with stars and horizon | Independently toggleable lines/names/art, licensed data and stable object identities |
| 6 — compass landscape | Compass rose, true-north indicator, roll-aware view | A compass tied to the same pose/context as the scene; north reference and unavailable/uncertain states visible |
| 7 — star/path portrait | Target selection, apparent track and concise title | Picking/focus/details first; paths follow a defined validated calculation, not a decorative trail |

The mobile home has **no terrain/landscape**. Virtual mode renders the sky across the whole display. Camera mode composites calculated sky directions on a local rear-camera preview. It does not enhance the camera, identify stars from pixels, or make a physically invisible galaxy appear in captured light. Marker sizes, glows, artwork and archive pictures are illustrations; precise model vectors remain separate.

## End-to-end journeys

1. **First launch:** branded privacy/rationale page → foreground location choice or manual coordinates → optional camera choice → calibration guidance → Start exploring. Explain purpose before each OS prompt. Basic exploration works with permission denied, services off or no camera. A public example may be explicitly selected; never silently pretend it is the device location.
2. **Return launch:** open directly into the full-screen sky. Remember only versioned onboarding completion and non-personal appearance/audio choices locally. Re-query OS permission/capability; do not persist raw location, pose, calibration offset or personal drafts. Request a fresh permitted location; unknown location gets an explicit action, not stale coordinates disguised as GPS.
3. **Virtual exploration:** real UTC/context calculation, touch pan/pinch, centre reticle, azimuth/altitude, geometric horizon/cardinal guides, layers and selection. Selected target and current view remain separate. Search opens an overlay/secondary route; choosing an object focuses that object in the same context.
4. **Phone pointing:** explicit Start tracking → available OS-fused pose with a declared reference → calibrated/aligned view. Touch input exits tracking visibly. Stop streams on pause/disposal; reject stale/non-finite/out-of-order data. Sensor data never travels to the backend.
5. **Calibration:** show a figure-eight illustration and concise instructions to move gently in an open area, away from magnetic accessories/cases if necessary. Completion means the guide was read, not that accuracy was measured. Check sensor quality and support known-direction/known-target alignment. A single yaw offset is not full camera/lens calibration; invalidate it on source/location/session changes.
6. **Camera:** request only on explicit opt-in; audio disabled; preview only, no photo/video recording or upload. Match rear optical axis, display rotation and preview crop. FOV/intrinsics absent → visibly approximate overlay with a usable FOV adjustment and residual acceptance still open. Close on pause/revocation and do not auto-reopen after late permission completion.
7. **Object discovery:** tap or centre selection → short bilingual summary/direction → expandable science/source/image detail. Search accepts both languages/IDs, distinguishes constellation from galaxy and preserves context on back. Missing media/conditions are explicit.
8. **Audio:** a credited, redistribution-compatible ambient track is bundled for offline repeat playback after Start exploring. Settings and an accessible quick mute control stop it immediately. Persist only the mute preference; pause on background, interruption and audio-focus loss. No background service, microphone or streaming dependency.
9. **Account:** same existing Bearer API, confirmation/reset flow and account-language preference. Personal records require verified authentication and remain in PostgreSQL; native credential storage must be platform secure storage. No public content cache contains tokens/private inventory or a personal offline write queue.

## Architecture and context contracts

- `lib/sky/domain`: observer/time context, vector/pose/projection, layer state and picking; no widgets/network dependencies.
- `lib/sky/data`: canonical catalogue geometry, native calculation adapter and local sensor/camera/audio/permission boundaries.
- `lib/sky/presentation`: full-screen batched painter, floating controls, onboarding, calibration, location, layers/settings and selection.
- Native calculation: pin Astronomy Engine **2.1.19 / 61dc07020aaa6885d2c7f688a4d82beaf6edb9ef**, retain upstream MIT texts and hashes; narrow bulk C ABI through Dart FFI. Android NDK/CMake, iOS C target and a host test library use the same source. No calculation request per rendered star/frame.
- Native pose: Android rotation vector and iOS Core Motion candidates; device-to-ENU basis, rear optical axis, display rotation, timestamps, reference (`true`, `magnetic`, `aligned`, `unknown`) and accuracy status travel together. Arbitrary/game orientation is never labelled true north. A geomagnetic model must have a known valid epoch before automatic declination correction is accepted.
- Scientific state: UTC instant, source/model revision, observer latitude/longitude, explicit ellipsoidal/assumed-0-m elevation and airless apparent body-centre definition. Keep the existing 2000–2035 model window and polar azimuth restriction. Proper motion/parallax/aberration for stars and precession/nutation for catalogue directions must match the existing Web model.
- Calculate in a bounded worker/isolate; coalesce refreshes and reject obsolete generation results. Draw current camera/pose at display rate separately from slower ephemeris refresh. Float64 scientific state; bounded labels/sprites and resource lifetime.
- Virtual perspective and wide-angle exploration use documented projections. Camera mode uses optical perspective; no terrain occlusion. Zenith/nadir, roll, seam and landscape rotations require deterministic projection tests.
- Shared backend contracts remain unchanged. Offline astronomy, rendering, base catalogue and audio work without network; content/account/optional service failures do not blank the sky.

## Visual and interaction contract

Use the existing `#3C3F43`, `#9EA1A6`, `#8B2333`, `#C9B6A6`, `#F7F1E6` palette and supplied logo. A black sky is the canvas; grey translucent controls and burgundy selection/accents preserve brand identity. No permanent topbar or sidebar. Safe-area-aware compact controls move for landscape; minimum 48 logical-pixel touch targets, semantics, large text and EN/TR must work. Reticle/compass must not be the only accessible means of identifying a target.

Initial layers: stars/solar-system, deep-sky, constellation lines/names, constellation artwork, azimuth grid, equatorial grid, horizon/cardinals and optional atmospheric appearance. Camera is a mode, not a terrain layer. No mobile landscape toggle. Each layer's drawing/rights/definition must be implemented before appearing as an active control. Night/red presentation must not change science. Milky Way imagery requires a registered celestial projection and its own rights; do not use a random rotating background as astronomical data.

## Delivery and acceptance gates

| Stage | Deliverable | Required exit evidence |
|---|---|---|
| SKY-01 | This contract, first-launch/permission state model and canonical native calculation bridge | Source/revision/hash record; existing JPL/Astropy fixtures and invalid-context/ABI checks; permission-denial paths |
| SKY-02 | Full-screen virtual sky as home; catalogue moved behind search; touch/selection/layers | Actual catalogue and nine solar-system bodies; picking/frame consistency, portrait/landscape/large text, no network requirement |
| SKY-03 | Android/iOS pose, visible compass, calibration guide and known-reference alignment | Synthetic axes/roll/wrap/lifecycle tests; unavailable/reference/accuracy distinctions; no stale/revoked stream application |
| SKY-04 | Optional rear preview and projection/FOV controls | No audio/recording/upload, manifest inspection, lifecycle cleanup; optical centre/edge residuals on physical devices |
| SKY-05 | Licensed offline ambience and persistent mute | Exact source/licence/hash/credit; repeated playback, focus/background/interruption tests; no foreground audio service |
| SKY-06 | Same-account/language and existing mobile feature parity | Synthetic shared-account journeys, confirmation/reset, secure refresh/revocation, Tonight/calendar/glossary/server notebook and error matrix |
| SKY-07 | Registered Milky Way/planet/art/path/optional satellite expansion | Per-asset rights and coordinate registration; physical visual/performance checks; satellites need fresh GP/OMM+SGP4 and uncertainty states |
| SKY-08 | Release acceptance | Physical S23/iPhone 15, iOS build/signing, 16 KB Android review, accessibility, privacy/account deletion, offline/update recovery, measured frame time/memory/thermal/energy and owner-authorized release |

Research proposes 60 Hz / ~16.7 ms frame time, ≤3 s first usable sky and p95 ≤150 ms search on agreed devices; these remain proposed/unmeasured budgets. Emulator/debug/UI success is not physical pointing, camera alignment or performance acceptance. Record actual outcomes separately; never close stages by changing tolerances or hiding known polar failures.

## Sources and implementation status

Primary references: [Android position sensors](https://developer.android.com/develop/sensors-and-location/sensors/sensors_position), [Core Motion reference frames](https://developer.apple.com/documentation/coremotion/cmattitudereferenceframe), [camera lifecycle](https://pub.dev/packages/camera), [foreground geolocation](https://pub.dev/packages/geolocator), [Astronomy Engine pinned C source](https://github.com/cosinekitty/astronomy/tree/61dc07020aaa6885d2c7f688a4d82beaf6edb9ef/source/c), [NOAA WMM](https://www.ncei.noaa.gov/products/world-magnetic-model), [audio playback](https://pub.dev/packages/just_audio). Accessed 4 November 2026. Prior [research catalogues](research/mobile/README.md) remain the detailed source register; mobile ground recommendations there are superseded by K-050.

Implementation starts after this plan. Subsequent measured results belong in a separate evidence record. No stage, platform build, physical pointing or store acceptance is asserted merely by this document.
