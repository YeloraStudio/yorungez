# Immersive mobile discovery contract — K-051

**K-052 correction (5 November 2026):** Dwell is now one second; foreground screen-awake, consistent action spacing and rounded onboarding marks are required. [Feedback implementation](mobile-screen-awake-and-polish.md) supersedes the earlier timing.

**Owner instruction: 4 November 2026.** This is a required continuation of [K-050](mobile-sky-first-plan.md), not an optional wish list. Deliver the complete experience over verified increments, preserving every item below. Flutter Android/iOS, the same .NET backend, open-source code, free/ad-free use, EN/TR/default-English, brand assets/palette, offline capability and server-owned personal records remain fixed.

## Durable reference archive

All **14 owner-provided screenshots** from K-050/K-051 were copied byte-for-byte from temporary attachments into `.local/design-references/skyview-lite-2026-11-04/`. Its `manifest.json` records reference IDs, byte counts and SHA-256 hashes. This ignored local archive preserves the visual references across sessions; the public plan preserves their interpretation and acceptance criteria. They are reference material, not licensed app assets. No competitor artwork/music/code is copied into the product or public repository.

| New reference | Required observation |
|---|---|
| K051-01 — Moon | Recognizable larger lunar disc; centre dwell; AZ/EL; soft solid/dotted apparent path; “Moon / Natural satellite of the Earth” |
| K051-02 — Orion | Registered figure and connecting lines; horizon/cardinal guide; concise constellation/above-horizon description |
| K051-03 — Mars | Default recognizable planetary imagery; selected object grows slightly; nearby Jupiter remains visible; “Fourth planet from the Sun” |
| K051-04 — ISS | A recognizable station symbol at a computed direction; brief bilingual identity; a genuine orbit-derived track |
| K051-05 — Jupiter/Leo | Jupiter texture and size emphasis; Leo figure/lines; “Largest planet in the Solar System” |
| K051-06 — Hadar | Catalogue-based stellar glow, “Star in Centaurus”, a calculated apparent path, compass and rich galactic background |
| K051-07 — cosmic field | Continuous, spatially registered 360-degree galactic dust/star/cloud colour over phone rotations; no arbitrary repeated background |

## Binding requirements

| ID | Requirement | Acceptance evidence |
|---|---|---|
| IM-01 | Closed-by-default **real sidebar**, with location/status/actions inside. Remove floating mute/location from the sky. Music and language controls are at the bottom of the sidebar. | Portrait/landscape, large text, scroll/back behaviour; both languages; mute remains immediate/persistent |
| IM-02 | Hold a target in the centre reticle for **1 second** to select it automatically. Use angular/reticle geometry, stable IDs, monotonic time and hysteresis. | No early selection; reset on target/context/mode/reference loss, pause or interrupted dwell; no repeated triggers every sensor sample |
| IM-03 | Show name and a short, correct EN/TR description after dwell, with selected-target AZ/EL near the reticle. | Jupiter/Moon/Mars/Orion/Leo/Hadar and generic catalogue identities; exact same calculation context as selection |
| IM-04 | Animate a soft apparent-sky track after dwell. Distinguish past/future where shown and expose its time interval/definition accessibly. | Same observer/model/time window; no fabricated line or star heliocentric orbit; frozen positional checks along sampled curves |
| IM-05 | Solar-system objects have recognizable licensed imagery by default, and slightly enlarge during selection. Preserve meaningful Moon/Sun/planet size differences. | Stable direction/identity/picking; smooth scale animation; retain a clear statement about illustrative enlargement versus physical angular radius |
| IM-06 | Lunar/planet phase and illuminated-side handling must be consistent with the selected instant wherever phase is rendered. | New/full/quarter/limb geometry and projection tests; do not label an archive photograph the current phase |
| IM-07 | Famous stars have their catalogue colour/magnitude glow and contextual short descriptions; sourced archive media is available where licensed. | Hadar/Centaurus and other known aliases; unresolved point appearance is not a fabricated resolved stellar surface |
| IM-08 | Constellation connecting lines and recognizable figures are registered to actual catalogue stars; Orion and Leo are required examples. | Reuse independently licensed existing art/data; check anchor registration, portrait/landscape/roll and figure identity. Keep toggles and offline credits |
| IM-09 | Render a rich, continuous **360-degree sky**, with registered Milky Way/dust/nebular/galaxy colour and brightness variation. | Verified source rights, celestial projection/orientation/seams, known landmarks and resource budgets; source composite brightness is not claimed naked-eye visibility |
| IM-10 | Remove manual zoom-in/zoom-out interaction and ordinary zoom controls. Main exploration follows the phone at a coherent view/lens FOV. | No pinch zoom; selection enlargement does not alter the observer/context or imitate optical zoom. Advanced lens calibration is separate from ordinary exploration |
| IM-11 | Preserve useful discovery with unsupported/denied sensors through explicit search/manual fallback, without claiming live physical pointing. | Reference/accuracy/denial states visible; no relative/magnetic orientation silently labelled true north |
| IM-12 | Add ISS identity, a recognizable original/licensed symbol and bilingual description, using real propagated orbital data. | NORAD 25544 identity, source/epoch/freshness/model provenance, SGP4 reference vectors, observer conversion, stale/unavailable and offline-expiry behaviour |
| IM-13 | Strengthen shared backend/content ingestion only where needed; calculation/rendering stays local and fast. Python can prepare/independently verify public datasets. | Typed public data contracts, validated/cached source ingestion, source health and provenance; no server request per sensor frame or unnecessary location transmission |
| IM-14 | Complete current numerical, permission/lifecycle, audio and publication checks while extending the experience. | No regressions in K-050 model/polar/ownership rules; meaningful EN/TR/native/renderer tests; physical S23/iPhone and iOS build gates remain explicit |

## Scientific and rendering decisions

An object's visible daily path is a **topocentric apparent track** over labelled UTC times. It is different from its physical orbit. Stars/DSOs mainly move across the local sky through Earth rotation; solar-system ephemerides add their own motion. Constellation figures are cultural illustrations registered to stellar anchors, not physical objects in space.

ISS needs fresh public GP/OMM elements and a matching validated SGP4 propagator. Store provenance/epoch/retrieval/validity independently from the observer. Prefer a shared .NET public-source catalogue/cache endpoint and local propagation; an offline element set has a finite useful age. Missing/stale data yields an explicit unavailable state, never a decorative station at an invented direction. Satellite reference-frame/time/Earth-rotation conventions must match test vectors.

Existing archive object photos can supply **illustrative** recognizable sprites, with separate documented rights and enlargement. Accurate centre vectors remain independent from sprite size/animation. The Moon's phase/bright-side mask needs a time-dependent calculation. Famous stars can be rendered as source-based coloured point/glow profiles; genuinely resolved photographs and their source conditions belong in credited detail views.

Use the existing independently licensed constellation artwork and catalogue-anchor geometry; do not import a competitor runtime. A 360-degree sky texture must have an established celestial coordinate registration and compatible rights. A random AI-generated nebula or repeated cosmetic noise cannot stand in for real sky structure. Source imagery, illustrated visibility and scientific point coordinates remain distinguishable.

[Current delivered code, evidence and remaining gates](mobile-immersive-discovery-evidence.md). Do not use the presence of implementation as physical/store acceptance.

## Implementation order and dependencies

1. **IM-A — durable scope + cleanup:** archive references, update AGENTS/requirements/roadmap/traceability; finish pending audio-race/lifecycle checks from K-050.
2. **IM-B — discovery interaction:** sidebar/pinned controls, fixed-FOV primary mode, monotonic dwell controller, bilingual summary catalogue, reticle AZ/EL and cancellable selection animation.
3. **IM-C — visual registration:** licensed sprite loader/cache, lunar phase mask and size policy; constellation mesh/anchors and default visual layers; registered 360-degree galactic source with landmark tests.
4. **IM-D — calculated tracks:** bounded local worker trajectory requests, matching time/context, cached selected-target geometry and progressive reveal. Validate actual sample coordinates and cancellation/races.
5. **IM-E — ISS/data pipeline:** primary-source rights/format/freshness research, shared backend ingestion/cache contract, local SGP4/observer adapter, reference vectors, bounded offline public data and station symbol.
6. **IM-F — acceptance:** Android builds/device viewport checks, EN/TR/landscape/large-text and interrupted dwell, no-microphone/no-storage permissions, model/reference fixtures, performance/resource profiling, physical calibration and iOS verification. Publish/merge/deploy only with existing owner approval rules.

These increments may share work, but no incomplete requirement is silently dropped or labelled delivered. Keep an evidence/status table by IM ID. Register any source failure and an alternative with actual rights/registration evidence. Extend shared contracts without introducing personal local persistence, paid licensing or advertising.

## Session handoff rule

Read this contract and K-050 evidence at the start of subsequent mobile work. Keep the latest owner corrections in AGENTS/decision records, retain the exact reference manifest privately, and report delivered versus open IM items. An emulator screenshot or a point catalogue is not the completion criterion for this immersive experience.
