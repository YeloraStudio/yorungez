# Flutter mobile foundation — K-049

**K-050 implementation update:** The owner subsequently replaced catalogue-as-home with the [full-screen mobile sky plan](mobile-sky-first-plan.md). [New evidence](mobile-sky-first-evidence.md) records the native C bridge, sky scene, onboarding, pose/alignment, camera and audio. The initial slice below remains a dated K-049 snapshot, not the current feature inventory.

**4 November 2026.** The owner authorized starting the Flutter Android/iOS application after the research baseline. This supersedes the earlier instruction to prepare mobile without creating an app. Web/PWA development and its outstanding acceptance work remain in scope; the existing backend is unchanged.

## Delivered slice

The application is in [src/Yorungez.Mobile](../src/Yorungez.Mobile/README.md). It is free to use and advertising-free. The initial slice establishes routing, feature/data/domain boundaries, a typed API boundary, paired English/Turkish resources, the grey/burgundy theme and the existing brand icons. English is the session default. This is an offline catalogue foundation, not the completed mobile planetarium.

| Area | Implemented evidence | Remaining boundary |
|---|---|---|
| Public catalogue — FR-03 | 5,073 stars, 88 constellations and 107 deep-sky objects; identity/alias search and detail | The nine solar-system bodies, Milky Way feature, full atlas and observer calculations are not in this slice |
| Public offline — FR-09 / UJ-07 | Base data and three credited archival images bundled at build time; checksums/schema/counts/coordinates validated off the UI isolate | No remote pack/update system or optional downloads; hashes detect corruption, not independent publisher authenticity |
| Images and rights | M31, M42 and Sirius retain canonical source bytes and per-image credit/licence; offline data notices and software-licence viewer | Missing photographs have an explicit unavailable state; broad photo/description coverage remains open |
| Shared API | HTTPS origin validation, language header, typed `/api/v1/status` response and separate transport/timeout/server/protocol failures | No mobile authentication or personal inventory UI yet |
| Languages — FR-11 | EN/TR resources, localized numbers, in-app language selection | Selection is session-only until account-backed language synchronization is implemented; this does not replace the existing Web account preference |
| Scientific context — FR-05 | Reference coordinates explicitly labelled J2000; unknown values remain unknown | No live observer direction, local ephemeris, event calculation or physical-pointing claim |

No precise location, sensor stream, camera capture, token or personal record is collected by this slice. Personal notes/favourites/observations/places remain verified-account/server-owned. No persistent personal database, durable draft, offline write queue or token preference has been introduced. Existing browser cookie/BFF/CSRF behaviour remains unchanged.

## Reproducible toolchain

- Flutter **3.41.6**, revision `db50e20168db8fee486b9abf32fc912de3bc5b6a`; Dart **3.11.4**. Recorded in the app README and `.flutter-version`; the installed global SDK was not upgraded.
- Android minimum **24**, compile/target **36**, AGP **8.11.1**, Kotlin **2.2.20**, Gradle **8.14**, JDK **17**; local Android debug build succeeded.
- iOS minimum **15**, Swift scaffold; building requires macOS/Xcode. No local iOS compilation, signing or physical iPhone acceptance is claimed.
- Development identifier **`com.yelorastudio.yorungez`** is not a store registration. Android release signing is unconfigured; debug signing is confined to debug builds.
- Resolved app graph is in `pubspec.lock`: Riverpod **3.3.2**, go_router **17.5.0**, Dio **5.11.1**, crypto **3.0.8**, intl **0.20.2**. The research registry snapshot is separate and does not override these SDK-compatible pins.
- Android uses INTERNET only. No camera, microphone, location, motion, background or notification permission is added before its implemented feature.

The [asset staging tool](../src/Yorungez.Mobile/tool/stage_assets.dart) reads canonical repository sources, checks their recorded digests and stages ignored copies without downloading data. It strips unimplemented art metadata from the DSO subset and retains actual data licence texts. Generated assets, local SDK paths, build outputs, emulator screenshots and signing material remain outside Git. [Third-party inventory](../THIRD_PARTY_NOTICES.md) separates original Apache-2.0 code from package/data/image terms.

## Verification

On the Windows development host:

- `flutter analyze --no-pub`: no issues.
- `flutter test --no-pub`: **13 passing tests** covering the real bundle, catalogue identity and bilingual aliases, corrupt bytes, incompatible epoch, API origin/response/failure boundaries and two widget journeys.
- Widget journeys cover offline M31 search/detail/source/J2000 context at 390×844 and Turkish menu/language switching at 320×640 with 2× text.
- `flutter build apk --debug --no-pub`: successful local development APK. It is not a store release.

On the owned API 35 x86_64 Android emulator, Wi-Fi and mobile data were disabled before a cold app launch. The catalogue opened with 5,268 objects; M31 detail displayed its bundled photograph, credit/licence and J2000 context. Switching to Turkish translated the menu and service view. The manual status check displayed a recoverable connection error offline and succeeded after emulator connectivity was restored. The Turkish software-licence screen opened. These observations do not establish sensor accuracy, physical GPS, iOS compatibility, frame-time/energy budgets or store readiness. The emulator uses 4 KB pages; no 16 KB acceptance is claimed.

All delivered UI translation keys matched; app/workflow YAML and Android/iOS XML parsed. Checks found no missing targets among 481 local links in 27 changed/new Markdown documents. Seven sampled generated/local/signing paths were ignored by Git. The publication guard passed against an isolated review index containing the proposed public files (825 files); no matched private values were printed and the real staging index was unchanged. Diff whitespace checks passed. This is a publication hygiene check, not a comprehensive security or transitive-licence certification.

The new [mobile workflow](../.github/workflows/mobile.yml) pins the official Flutter revision, restores the lockfile, stages assets and runs format/analyze/test/Android debug build for mobile-related paths. An unsigned macOS iOS build is available by explicit workflow dispatch. This workflow has **not yet run on GitHub**; existing Web/API CI and deployment are unchanged.

## Next evidence gates

Research does not block scaffolding. It leaves three implementation experiments that must produce evidence before claiming a live, aligned sky:

1. **Local astronomy bridge and parity** — a narrow Astronomy Engine C binding candidate, same frozen JPL/Astropy cases and declared frame/refraction/time window as the existing implementation. Preserve known polar exceptions and existing tolerances.
2. **Native pose adapter** — Android OS-fused rotation vector / iOS Core Motion candidates with explicit north reference, axis/display transforms, timestamps, lifecycle and stale-data handling. Physical S23/iPhone measurements remain necessary.
3. **Renderer comparison and optional camera** — compare the same real catalogue/camera path before selecting the rendering backend; calibrate lens/FOV/crop/orientation/timing separately from compass heading.

Shared Bearer authentication/secure credential storage and account-language synchronization follow as their own verified slice. Tonight, Calendar, glossary, notebook and broader public content then follow the existing requirements. The [experiment catalogue](research/mobile/10-experiments-acceptance-and-delivery.md) remains the detailed acceptance plan: M-R1 is partial, M-0 is not complete. No Web acceptance criterion is closed merely because the mobile foundation builds.
