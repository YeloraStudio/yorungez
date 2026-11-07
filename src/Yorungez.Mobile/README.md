# Yorungez mobile

Flutter Android/iOS sky-first client of the existing .NET backend. Free to use and advertising-free. English defaults; all delivered interfaces also support Turkish. Existing brand assets and grey/burgundy palette are retained.

Native orientation now probes actual OS support, explains missing tracking once per installation, and bounds silent sensor streams while retaining touch exploration. See [K-058 compatibility and acceptance](../../docs/mobile-sensor-compatibility.md).

Foreground sky/onboarding now prevents automatic display sleep and releases the override on inactivity/background/exit; see [K-052 physical-phone feedback](../../docs/mobile-screen-awake-and-polish.md).

## Current working slice

Native Tonight/Calendar now reuse canonical offline events and the shared solver, with explicit device/manual IANA local time plus UTC, standard visibility intervals and event-to-simulation/live navigation. Verified accounts can schedule/cancel server email reminders; future push remains disabled until APNs/FCM and consent are implemented. [Delivery, API and verification](../../docs/mobile-night-calendar-reminders.md). [Native icon exports](../../data/branding/mobile/manifest.json) and [English store showcase](../../data/store/google-play/en-US/README.md) preserve the owner logo.

Home is a full-screen, phone-first calculated sky. First launch explains privacy and optional foreground GPS/rear camera, supports manual coordinates/an explicit Istanbul example, and gives calibration guidance. Search is secondary. [Binding requirements](../../docs/mobile-immersive-discovery-plan.md) and [implementation evidence / open gates](../../docs/mobile-immersive-discovery-evidence.md) are the current contract.

- Offline catalogue: 5,073 stars, 88 constellations, 107 deep-sky objects, nine solar bodies and ISS identity (5,278 total; a station direction requires fresh elements).
- Pinned Astronomy Engine C/FFI, one bounded serial worker, optional one-second reticle dwell, bilingual name/brief/target AZ/EL and animated calculated apparent tracks. Dwell defaults on and can be switched off in Settings.
- Source-based stellar glow, nine illustrative solar photos with computed disc phase, selected enlargement, 85 spherical constellation figures/lines and a registered 360° ESO galactic background. Settings offers virtual sky pinch and button zoom, off by default at 60°. Both controls are device-local.
- Closed sidebar with location/UTC/layers and music/language at the bottom. Licensed Cylinder Four looping ambience and immediate persistent mute.
- Android/iOS native pose adapters, current WMM2025 magnetic-declination correction when applicable, sensor/reference/freshness gates and manual known-reference calibration. Physical accuracy is not yet accepted.
- Optional audio-free rear-camera preview. Lens/crop/FOV alignment remains approximate until physically measured.
- Same .NET backend, including a new public cached ISS OMM endpoint; local pinned SGP4, a finite-life public offline packet and an original station glyph. The public ISS route was deployed with K-053.

Shared API sign-in, registration/verification-email requests, profile and server notebook reads/note/favourite writes are implemented. Account language, music and sky layers follow the shared API; anonymous language/mute are non-personal UI preferences. Only a rotating refresh credential uses platform-secure storage; access tokens, personal records/drafts, coordinates, pose and alignment stay in memory. There is no personal local database or offline write queue. [Account integration, evidence and limits](../../docs/mobile-account-integration.md).

## Toolchain and run

Pinned Flutter **3.41.6** (`db50e20168db8fee486b9abf32fc912de3bc5b6a`), Dart **3.11.4**. See `.flutter-version` and `pubspec.lock`. Android minimum **24**; iOS minimum **15**. Android application ID is `com.cnonestudio.yorungez`; earlier owner APKs use `com.yelorastudio.yorungez` and are installed separately. Android release signing is unconfigured.

From this directory:

```sh
flutter pub get --enforce-lockfile
dart run tool/stage_assets.dart
flutter gen-l10n
flutter run -d <device-id>
```

The deterministic staging tool verifies canonical source/data/image/audio hashes and creates ignored `assets/generated/` copies without downloading scientific data. Do not hand-edit generated assets. Normal native builds compile the checked-in pinned C source. Regenerate branded icons with `dart run flutter_launcher_icons` only after a reviewed brand-master change.

For the host reference/ABI tests, install GCC, Python and Node, then restore the existing pinned JS comparison package explicitly:

```sh
npm ci --prefix ../../tools/science-js --ignore-scripts --no-audit --no-fund
python tool/check_science.py
python tool/check_planning.py
python tool/check_satellite.py
python tool/check_magnetic.py
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --debug --no-pub
```

The host script writes only ignored `.local/mobile-science` output; tests use that library by default. `YORUNGEZ_SKY_LIBRARY` can identify an explicitly built host library. Debug APKs are local test artifacts, not store releases. iOS uses the same C wrapper/source in the Runner target and requires macOS/Xcode for `flutter build ios --no-codesign`; the current unsigned iOS build passed on the macOS runner in [K-055 mobile CI](https://github.com/YeloraStudio/yorungez/actions/runs/42122469454). Physical iPhone/Keychain and release-signing acceptance remain open.

Android declares foreground location and optional camera; microphone, background-location and external-storage permissions are absent. iOS permission explanations are paired EN/TR. Stop/restart/denial/device behaviour still needs physical acceptance.

## Boundaries and next stages

The validated first model remains **2000–2035**, airless apparent body centres, explicit assumed-0-m/reference-ellipsoid elevation and the existing polar-azimuth restriction. Layers do not change celestial positions. Above the geometric horizon does not establish naked-eye visibility. Marker sizes/glow are schematic; the renderer is a baseline pending physical/profile measurements.

Equatorial-grid/glossary, complete observation/place editing parity and release readiness remain planned. Surface textures and apparent-size enlargement are illustrative; the photographic background is not astrometric point data. Native pointing accuracy, lens/crop calibration, physical iOS/secure-store behaviour, accessibility and device performance are not accepted by host/emulator checks.

The public API origin defaults to `https://api.yorungez.com`; override via `--dart-define=API_BASE_URL=https://your-test-api.example.com`. Origins require HTTPS and no credentials/path/query. No secret or environment file is bundled. Offline calculation/rendering/content/audio do not depend on this connection. Native authentication uses the existing Bearer contract, serialized refresh rotation and platform-secure storage. New account exploration-preference schema/routes require deployment before connected music/layer saving is available.

[End-to-end plan](../../docs/mobile-sky-first-plan.md) · [Current evidence and remaining gates](../../docs/mobile-immersive-discovery-evidence.md) · [Research catalogues](../../docs/research/mobile/README.md) · [Original foundation snapshot](../../docs/mobile-foundation.md) · [Third-party inventory](../../THIRD_PARTY_NOTICES.md).

Original code is Apache-2.0. Astronomy Engine, catalogue data, images and music retain their separate licences; source/data/software notices are accessible offline.
