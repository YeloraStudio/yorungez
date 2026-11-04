# 02 — Flutter stack and dependency candidates

**Status:** researched shortlist, not an installed or solver-validated stack. **Traceability:** K-048, FR-01–12.

## Platform and toolchain

Use a pinned stable Flutter SDK with its bundled Dart SDK, Android SDK/NDK/Gradle/JDK toolchain, and macOS/Xcode for iOS. Record exact versions and hashes when the first experiment is created. Do not mix a beta rendering requirement into an otherwise stable application without an explicit decision.

The current Flutter platform page describes Flutter 3.47 with Android API 24+ and iOS 15+ support. These are framework support statements, not our final app support promise. Package requirements can raise either the compiler or OS floor. [Supported platforms](https://docs.flutter.dev/reference/supported-platforms), [SDK archive](https://docs.flutter.dev/install/archive), [iOS setup](https://docs.flutter.dev/platform-integration/ios/setup).

The selected SDK patch/Dart pairing remains unresolved: the release archive is dynamically populated, and a direct release-metadata request returned 404 here. No “latest stable installed” claim is made. Several current candidates require Dart `^3.12.0`; Scene requires Flutter `>=3.47.0`. `sensors_plus` also documents Java/Kotlin/AGP/Gradle constraints. Resolve these together and commit the application's lockfile only after actual Android and iOS builds succeed. [Registry snapshot](package-snapshot.json), [sensor requirements](https://pub.dev/packages/sensors_plus).

## Recommended stack by responsibility

| Responsibility | Recommended starting candidate | Reason / limit |
|---|---|---|
| Shared UI | Flutter + Dart | Owner-selected; native Android/iOS host integration remains available |
| Feature state and dependency injection | Riverpod | Supports asynchronous repositories and testing; keep high-rate pose outside broad widget rebuilds |
| Navigation | `go_router` | Route/back stack, account redirects and verified-link journeys |
| HTTP | Dio | Cancellation, timeouts and interceptors; `http` is a smaller alternative |
| DTOs | Dart immutable types + JSON generation | Generated serialization where justified; OpenAPI and generated-client experiment still required |
| General offline index | Drift + SQLite | Relational search, migration and transactions; public content only under current policy |
| Large assets | Versioned files plus manifest | Avoid loading images/catalogues into arbitrary key-value storage |
| Credentials | `flutter_secure_storage` | Platform secure storage candidate; configure lifecycle/backup behaviour |
| Position | `geolocator` | Foreground location and explicit quality metadata |
| Phone pose | Owned typed native adapter | OS-fused attitude and camera-axis contract; raw sensors are auxiliary |
| Camera | Official `camera`, extended if necessary | Start with local preview; optical metadata is a separate acceptance requirement |
| Astronomy | Astronomy Engine C + FFI experiment | Shared scientific model, offline calculation; not yet integrated |
| Rendering | Canvas/shader baseline, compared with GPU options | Largest unresolved technical choice |
| Languages/time | SDK localization + `intl` + reviewed tzdb | Full EN/TR; timezone package freshness must be verified |
| Tests | Dart/Flutter test + widget/golden/integration tests | Scientific fixtures and physical-device measurements supplement UI tests |
| Diagnostics | Existing safe backend telemetry; local opt-in diagnostics | No advertising SDK or mandatory behavioural analytics needed |

Package capabilities: [Riverpod](https://pub.dev/packages/flutter_riverpod), [router](https://pub.dev/packages/go_router), [Dio](https://pub.dev/packages/dio), [Drift](https://pub.dev/packages/drift), [secure storage](https://pub.dev/packages/flutter_secure_storage), [serialization](https://docs.flutter.dev/data-and-backend/serialization/json). High-level selection reasons are engineering recommendations, not source claims of universal superiority.

## Dated package inventory

The following versions and SPDX identifiers were retrieved from the **pub.dev package and metrics APIs on 4 November 2026**. “Licence” is the registry classifier result for that version, not a full archive/transitive audit. Each package link identifies its primary project page; [JSON evidence](package-snapshot.json) includes publication time, constraints, repository URL and archive SHA-256.

| Package | Observed version | Registry licence | Proposed role / decision |
|---|---|---|---|
| [camera](https://pub.dev/packages/camera) | 0.12.2 | BSD-3-Clause | Primary camera-preview candidate; test lifecycle and intrinsics gap |
| [geolocator](https://pub.dev/packages/geolocator) | 14.1.2 | MIT | Primary location candidate; foreground-only initial scope |
| [sensors_plus](https://pub.dev/packages/sensors_plus) | 7.1.1 | BSD-3-Clause | Raw sensor diagnostics; not the complete pose solution |
| [flutter_compass](https://pub.dev/packages/flutter_compass) | 0.8.1 | MIT | Simple heading comparator; review maintenance before use |
| [flutter_riverpod](https://pub.dev/packages/flutter_riverpod) | 3.4.3 | MIT | Recommended state/DI candidate |
| [flutter_bloc](https://pub.dev/packages/flutter_bloc) | 9.1.1 | MIT | State-management alternative; do not introduce both by default |
| [go_router](https://pub.dev/packages/go_router) | 18.1.2 | BSD-3-Clause | Recommended navigation candidate |
| [dio](https://pub.dev/packages/dio) | 5.11.1 | MIT | Recommended HTTP candidate |
| [http](https://pub.dev/packages/http) | 1.6.0 | BSD-3-Clause | Smaller HTTP alternative |
| [drift](https://pub.dev/packages/drift) | 2.35.3 | MIT | Public catalogue/index database candidate |
| [sqlite3](https://pub.dev/packages/sqlite3) | 3.8.0 | MIT | Dart/native SQLite binding candidate; wrapper/native licences differ |
| [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) | 11.2.0 | BSD-3-Clause | Refresh credentials; not personal catalogue storage |
| [timezone](https://pub.dev/packages/timezone) | 0.11.2 | BSD-2-Clause | Zone conversion candidate; verify actual bundled tzdb |
| [intl](https://pub.dev/packages/intl) | 0.20.3 | BSD-3-Clause | Locale formatting; selected Flutter SDK may constrain version |
| [json_annotation](https://pub.dev/packages/json_annotation) | 4.12.0 | BSD-3-Clause | DTO annotations if generation adopted |
| [json_serializable](https://pub.dev/packages/json_serializable) | 6.15.2 | BSD-3-Clause | DTO code generation candidate |
| [freezed_annotation](https://pub.dev/packages/freezed_annotation) | 3.1.0 | MIT | Optional immutable-model annotation |
| [freezed](https://pub.dev/packages/freezed) | 4.0.3 | MIT | Optional model generator; validate annotation/builder compatibility |
| [vector_math](https://pub.dev/packages/vector_math) | 2.4.4 | BSD-3-Clause | Math utilities; verify required precision and conventions |
| [ffigen](https://pub.dev/packages/ffigen) | 23.0.0 | BSD-3-Clause | Generate narrow C ABI bindings |
| [pigeon](https://pub.dev/packages/pigeon) | 29.1.0 | BSD-3-Clause | Typed native pose/camera control contract |
| [crypto](https://pub.dev/packages/crypto) | 3.0.8 | BSD-3-Clause | Content digests; hashing alone does not authenticate a publisher |
| [connectivity_plus](https://pub.dev/packages/connectivity_plus) | 7.3.2 | BSD-3-Clause | Connectivity hints; never proof of API reachability |
| [path_provider](https://pub.dev/packages/path_provider) | 2.1.6 | BSD-3-Clause | Locate OS-managed app content directories |
| [flutter_scene](https://pub.dev/packages/flutter_scene) | 0.24.3 | MIT | Renderer experiment; review optional engine dependencies separately |
| [thermion_flutter](https://pub.dev/packages/thermion_flutter) | 0.6.1 | Apache-2.0 | Filament renderer alternative; native material/build compatibility |
| [permission_handler](https://pub.dev/packages/permission_handler) | 13.0.2 | MIT | Optional permission coordination; avoid duplicate competing permission flows |
| [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) | 22.3.3 | BSD-3-Clause | Deferred local-reminder experiment; not an initial mandatory dependency |

## Admission and maintenance gates

For each adopted component: resolve a compatible SDK/dependency graph; inspect the selected release's source/LICENCE and transitive/native dependencies; review platform manifests, privacy manifests and permissions; build all target ABIs; run relevant tests; retain notices; and document the fallback if support disappears. Automated registry scores and download counts are not accuracy, privacy or maintenance guarantees.

Use the smallest justified dependency set. SDK widgets/localization, Dart types and built-in test facilities may remove the need for extra packages. Do not add BLoC and Riverpod, two HTTP layers, multiple permission owners or an entire 3D/physics/audio stack without a concrete need. Optional Scene integrations must be checked independently of the core package's MIT label.

Recheck metadata before the first app scaffold and before store submission. No listed package was installed, upgraded in the Web app, or approved for redistribution by this documentation work.
