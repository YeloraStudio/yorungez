# Sky-first mobile implementation evidence — K-050

**K-051 follow-up:** [Current immersive implementation/evidence](mobile-immersive-discovery-evidence.md) supersedes the historical manual-zoom, deferred-art/track/satellite and manual-only Android alignment baseline below. Physical/iOS and remaining app-parity gates remain open.

**4 November 2026.** See the [end-to-end delivery plan](mobile-sky-first-plan.md). This record describes the first working implementation, not complete mobile, physical-pointing or store acceptance.

## Implemented

- `/` now opens a full-screen virtual sky, with no mobile terrain. The catalogue is a secondary search route and returns a selected object to the same observer/time context.
- First launch provides paired EN/TR privacy/rationale, foreground GPS or manual-coordinate choice, optional camera preparation, figure-eight guidance and Start exploring. A clearly labelled Istanbul example can be selected explicitly; it is never represented as a device fix. Return launch remembers notice version and mute preference only, obtains a fresh already-permitted location when available, and offers manual entry otherwise.
- The actual canonical 5,073 stars, 88 constellation anchors, 107 deep-sky objects and nine solar-system bodies produce **5,277 selectable identities**. Twelve canonical source-credited archive photographs are bundled for detail, including the Sun/Moon/planets and M31/M42/Sirius. Archive images are not live camera captures.
- The serial isolate calls a bulk C ABI around pinned, unmodified Astronomy Engine 2.1.19. The same wrapper/source builds as an Android NDK library, iOS C target and host reference-test library. Normal builds/tests stage local sources/assets without downloading astronomical data.
- Source-backed star space motion, annual/topocentric parallax, first-order annual aberration, precession/nutation, DSO reference rotation and airless topocentric solar-system positions match the existing model definitions. Refresh is bounded/coalesced separately from touch/pose painting; obsolete observer generations are discarded. The 2000–2035 model window and polar restriction remain.
- Batched Canvas baseline provides source-based stars/glow, solar-system markers, DSO markers, constellation lines/names, azimuthal grid, horizon/cardinals, optional atmospheric appearance, centre reticle, touch pan/pinch, picking, focus and a view-consistent compass rose. Sizes/glows are schematic. It is a baseline for measured renderer comparison, not the final performance selection.
- Native Android rotation-vector and iOS Core Motion adapters expose matrix/display rotation/reference/quality/timestamps. Invalid, stale, out-of-order or unreliable samples cannot silently become a geographic view. Android currently supplies **magnetic north**: known true-north or visible-target session alignment is required. No expired/unknown platform declination model is automatically trusted. iOS requests an available true-north frame, with magnetic fallback explicitly marked; physical iPhone verification remains open.
- Optional rear-camera preview disables audio and recording. Camera mode uses optical perspective with adjustable approximate FOV; no sky vectors are applied over the camera until tracking has an aligned reference. Preview closes on background/disposal. Lens/intrinsic/crop calibration remains open and is labelled approximate.
- “Cylinder Four” by Chris Zabriskie, *Cylinders* (2014), is bundled unchanged for offline repeat playback. Local volume is low; mute is immediate and retained as a non-personal UI preference. Playback uses an ambient iOS audio session and pauses on application background; physical interruption/loop-boundary listening remains acceptance work. [Asset provenance](../data/audio/README.md).
- Live object detail shares the calculation frame/UTC instant and shows direction, altitude and solar-system distance/of-date coordinates separately from J2000 catalogue fields. Missing media/conditions remain explicit. The existing API/BFF/backend architecture is unchanged; mobile authentication and server inventory are subsequent delivery work.

## Actual numerical results

`python src/Yorungez.Mobile/tool/check_science.py` compiled the host C library, verified upstream hashes and used the frozen repository fixtures. No reference data was downloaded or tolerance changed.

| Comparison | Count | Largest residual | Retained limit |
|---|---:|---:|---:|
| JPL airless positions, including event-grid sample positions | 1,166 | 0.33545831 arcmin | 1 arcmin |
| Astropy stellar samples | 144 | 0.30757847 arcmin | 1 arcmin |
| Astropy deep-sky samples | 72 | 0.42752501 arcmin | 1 arcmin |
| C / pinned JavaScript solar-system coordinate parity | 1,166 | 1.42109 × 10⁻¹³ degrees | 10⁻⁷ degrees |

The two original near-pole cases (`near-north-pole-neptune`, `near-south-pole-venus`) remain explicitly excluded by the product azimuth boundary, not relabelled passing. Four invalid C inputs (polar location, non-finite time, out-of-window time, wrong output length) were rejected. These are position comparisons; native event-search/crossing APIs were not implemented or newly accepted.

## Application checks

- **24 Flutter tests passed**, including real bundled identities/images, corruption/epoch rejection, HTTP boundaries, C ABI marshalling, serial-isolate overlap/disposal, optical/rear-axis/display/roll/wrap math, source/freshness rejection, UI-only preference keys, search/detail, first-launch EN/TR and real-native-scene portrait/landscape layout with 2× text.
- `flutter analyze --no-pub`: no issues. Android debug APK build succeeded with the native C library and resolved platform plugins.
- On the owner's running API 35 x86_64 emulator, Computer Use observed privacy → explicit Istanbul example → calibration → Start exploring → full-screen calculated sky. Stars, Saturn/Neptune, the horizon and a visibly magnetic/alignment-needed status appeared. User touch input then changed the view; automated desktop input was stopped so the owner could inspect it.
- The emulator reports **4 KB pages**. Neither an emulator name containing `16k` nor an NDK linker option establishes complete 16 KB release compatibility. Physical S23/iPhone and signed release checks remain open.
- Final Android APK inspection verified no microphone, background-location or external-storage permission. Unneeded transitive storage permissions were explicitly removed. No camera/motion/GPS OS permission prompt was accepted by desktop automation.

The prepared mobile CI adds frozen-reference/JS parity before Flutter tests and Android build. It has not run remotely in this work. Existing Web/API/deployment workflows were not invoked; no commit, push, deployment or store upload is claimed.

## Remaining delivery gates

| Plan stage | Current state |
|---|---|
| SKY-01 | Numerical host/native ABI and source evidence implemented; iOS/target-ABI and full native context/lifecycle acceptance still open |
| SKY-02 | First full-screen real-data scene/search/layers/touch implementation and automated layouts present; physical interaction/performance and broader layer/visual coverage open |
| SKY-03 | Native adapters, quality/reference gates and explicit alignment present; valid-epoch automatic Android declination and measured S23/iPhone direction/elevation/drift acceptance open |
| SKY-04 | Optional audio-free local preview and approximate optical projection implemented; physical lens/crop/FOV/latency calibration open |
| SKY-05 | Licensed asset/repeat/mute/lifecycle implementation present; physical listening, audio focus/interruption and long session acceptance open |
| SKY-06 | Same backend/status boundary retained; native secure authentication, account language, Tonight/calendar/glossary/server notebook parity not implemented |
| SKY-07 | Registered Milky Way imagery, textured/phase-correct planet rendering, constellation artwork, equatorial grid, tracks and freshness-aware SGP4 satellites remain planned |
| SKY-08 | iOS build/signing, physical devices, accessibility, measurements, privacy/store and owner-authorized release remain open |

Figure-eight guidance is assistance, not a measured calibration certificate. Known-reference yaw alignment is session-only and does not determine camera intrinsics. No physical error bound, all-device support, live ISS track, camera recognition or “finished app” claim follows from these checks.
