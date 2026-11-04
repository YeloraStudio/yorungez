# Primary-source register

**Access date:** 4 November 2026 unless stated otherwise. **Method:** official documentation, maintainer repositories, official package-registry APIs and repository inspection. No competitor app was run, no native benchmark was measured, and no complete dataset was ingested.

Descriptions are concise research notes, not reproductions of the source documents. Recommendations in the catalogues are Yorungez engineering analysis. Source availability is not a redistribution licence. Time-sensitive facts must be refreshed before adoption.

## Flutter and platform integration

| ID | Primary source | Evidence used / limit |
|---|---|---|
| FL-01 | [Flutter platform integration](https://docs.flutter.dev/platform-integration/ios/apple-frameworks) | Flutter APIs can delegate to native platform frameworks; examples are not blanket package endorsements |
| FL-02 | [Supported platforms](https://docs.flutter.dev/reference/supported-platforms) | Current page describes Flutter 3.47 support; final app floor remains unresolved |
| FL-03 | [SDK archive](https://docs.flutter.dev/install/archive) | Stable/beta/main distinction; dynamically loaded patch table did not establish an exact chosen SDK |
| FL-04 | [C FFI bindings](https://docs.flutter.dev/interop/bind-native-code) | Current package_ffi/build-hook workflow |
| FL-05 | [Pigeon](https://docs.flutter.dev/interop/pigeon) | Typed native interfaces and communication options; transport must match use case |
| FL-06 | [Impeller](https://docs.flutter.dev/perf/impeller) | Renderer/platform availability and fallbacks |
| FL-07 | [Fragment shaders](https://docs.flutter.dev/ui/design/graphics/fragment-shaders) | Shader asset compilation and Flutter effects API |
| FL-08 | [Flutter GPU API](https://api.flutter.dev/flutter/flutter_gpu/) | Low-level rendering API, distinct from a complete sky engine |
| FL-09 | [Dart isolates](https://dart.dev/language/isolates) | Compute isolation and persistent-worker tradeoffs |
| FL-10 | [Flutter performance](https://docs.flutter.dev/perf/best-practices) | Rendering/UI profiling guidance; no Yorungez measured result |
| FL-11 | [Integration tests](https://docs.flutter.dev/testing/integration-tests) | Official application integration-test route |
| FL-12 | [JSON serialization](https://docs.flutter.dev/data-and-backend/serialization/json) | Typed/manual/generated serialization options |
| FL-13 | [Localization](https://docs.flutter.dev/ui/internationalization) | SDK localization, resources and locale-aware formatting |
| FL-14 | [Accessibility](https://docs.flutter.dev/ui/accessibility) | Semantics and physical screen-reader/large-text acceptance guidance |
| FL-15 | [Android App Links](https://docs.flutter.dev/cookbook/navigation/set-up-app-links) | Domain association and app-link routing |
| FL-16 | [iOS Universal Links](https://docs.flutter.dev/cookbook/navigation/set-up-universal-links) | Domain association and native deep-link routing |
| FL-17 | [iOS development setup](https://docs.flutter.dev/platform-integration/ios/setup) | Xcode/native testing setup |
| FL-18 | [iOS release](https://docs.flutter.dev/deployment/ios) | macOS/Xcode, signing and distribution preparation |
| FL-19 | [Android release](https://docs.flutter.dev/deployment/android) | Signing, package/build and release preparation |

## Package registry evidence

[package-snapshot.json](package-snapshot.json) records **28 packages**. For each package `NAME`, metadata was read from `https://pub.dev/api/packages/NAME` and classifier data from `https://pub.dev/api/packages/NAME/metrics`. The exact URLs, versions, publication times, constraints and reported archive hashes are included per record. All 28 fetches succeeded and the classifier versions matched the observed versions in this snapshot.

The human-readable package/version/licence/role table is in [catalogue 02](02-flutter-stack-and-dependencies.md). Metadata from a registry is not equivalent to a security audit, native dependency review, real-device support result or licence opinion.

Additional documentation examined:

| ID | Primary source | Evidence used / limit |
|---|---|---|
| PK-01 | [camera](https://pub.dev/packages/camera) | Camera preview, lifecycle ownership and permissions; optical metadata adequacy requires testing |
| PK-02 | [geolocator](https://pub.dev/packages/geolocator) | Platform location, precision/permission considerations and separate geocoding |
| PK-03 | [sensors_plus](https://pub.dev/packages/sensors_plus) | Individual sensor streams and platform/toolchain requirements |
| PK-04 | [flutter_compass](https://pub.dev/packages/flutter_compass) | Heading scope and old observed release date |
| PK-05 | [Riverpod](https://pub.dev/packages/flutter_riverpod) | Asynchronous state/repository candidate |
| PK-06 | [go_router](https://pub.dev/packages/go_router) | Routing, redirects and deep links |
| PK-07 | [Dio](https://pub.dev/packages/dio) | HTTP cancellation/interceptors/timeouts |
| PK-08 | [Drift](https://pub.dev/packages/drift) | SQLite-backed typed relational persistence |
| PK-09 | [Drift isolates](https://drift.simonbinder.eu/isolates/) | Background database execution and ownership |
| PK-10 | [Secure storage](https://pub.dev/packages/flutter_secure_storage) | Platform credential-storage candidate; settings/migration require native tests |
| PK-11 | [timezone](https://pub.dev/packages/timezone) | Package documents 2025c data and no coordinate/device-zone discovery |
| PK-12 | [Connectivity](https://pub.dev/packages/connectivity_plus) | Network type does not establish internet/API reachability |
| PK-13 | [Flutter Scene](https://pub.dev/packages/flutter_scene) | Current feature/platform and GPU setup requirements; astronomy suitability unmeasured |
| PK-14 | [Scene maintainer README](https://github.com/bdero/flutter_scene/blob/master/packages/flutter_scene/README.md) | Upstream rendering/asset pipeline; optional subsystems need separate review |
| PK-15 | [Thermion](https://pub.dev/packages/thermion_flutter) | Filament integration and matching material/native versions |

## Device pose, camera and background work

Apple HTML documentation sometimes contains only its JavaScript shell. For the following Apple technical sources, the publisher-provided `.md` representation was read when available: processed device motion, attitude reference frames, videoFieldOfView, ARGeoTrackingConfiguration, privacy manifests and Background Tasks. Human-facing links below remain canonical.

| ID | Primary source | Evidence used / limit |
|---|---|---|
| HW-01 | [Android position sensors](https://developer.android.com/develop/sensors-and-location/sensors/sensors_position) | Reference frames, game rotation-vector drift and sensor availability |
| HW-02 | [Android motion sensors](https://developer.android.com/develop/sensors-and-location/sensors/sensors_motion) | Sensor types and capabilities |
| HW-03 | [Apple processed device motion](https://developer.apple.com/documentation/coremotion/getting-processed-device-motion-data) | OS fusion and selectable reference frames |
| HW-04 | [CMAttitudeReferenceFrame](https://developer.apple.com/documentation/coremotion/cmattitudereferenceframe) | Reference frame identity/availability |
| HW-05 | [CLHeading](https://developer.apple.com/documentation/corelocation/clheading) | True/magnetic heading and accuracy distinctions |
| HW-06 | [Android camera characteristics](https://developer.android.com/reference/android/hardware/camera2/CameraCharacteristics) | Intrinsics, distortion and device-dependent metadata |
| HW-07 | [AVFoundation video FOV](https://developer.apple.com/documentation/avfoundation/avcapturedevice/format/videofieldofview) | Format's horizontal FOV; zero denotes unknown |
| HW-08 | [ARCore fundamentals](https://developers.google.com/ar/develop/fundamentals) | Visual/inertial tracking, feature points and scene concepts |
| HW-09 | [ARCore device support](https://developers.google.com/ar/devices) | Capability/device certification limits |
| HW-10 | [Apple geotracking](https://developer.apple.com/documentation/arkit/argeotrackingconfiguration) | Supported areas and online localization imagery |
| HW-11 | [NOAA WMM](https://www.ncei.noaa.gov/products/world-magnetic-model) | Model/data, test/rights documentation and stated expiry |
| HW-12 | [NOAA WMMHR](https://www.ncei.noaa.gov/products/world-magnetic-model-high-resolution) | Separate high-resolution model |
| HW-13 | [Android task scheduling](https://developer.android.com/develop/background-work/background-tasks/persistent) | Background constraints and flexible scheduling |
| HW-14 | [Apple Background Tasks](https://developer.apple.com/documentation/backgroundtasks) | OS-managed background work; not continuous sky tracking |

## Astronomy and scientific data

| ID | Primary source | Evidence used / limit |
|---|---|---|
| SC-01 | [Astronomy Engine](https://github.com/cosinekitty/astronomy) | Supported upstream languages, scope and accuracy target; not device validation |
| SC-02 | [Astronomy Engine licence](https://github.com/cosinekitty/astronomy/blob/master/LICENSE) | MIT licence text read through GitHub connector |
| SC-03 | [IAU SOFA](https://www.iausofa.org/) | Fundamental astronomy routines and separate licence |
| SC-04 | [ERFA licence](https://github.com/liberfa/erfa/blob/master/LICENSE) | Candidate's distinct licensing; exact adoption revision unresolved |
| SC-05 | [Astropy coordinates](https://docs.astropy.org/en/stable/coordinates/) | Independent coordinate reference pipeline |
| SC-06 | [Skyfield satellites](https://rhodesmill.org/skyfield/earth-satellites.html) | SGP4/element-age limitations |
| SC-07 | [Horizons manual](https://ssd.jpl.nasa.gov/horizons/manual.html) | Time/frame/observer definitions |
| SC-08 | [JPL API policy](https://ssd-api.jpl.nasa.gov/doc/) | Controlled request concurrency, caching and service limits |
| SC-09 | [USNO API](https://aa.usno.navy.mil/data/api) | Supported service definitions/reference inputs |
| SC-10 | [CelesTrak GP formats](https://celestrak.org/NORAD/documentation/gp-data-formats.php) | Modern formats and six-digit identifier issue |
| SC-11 | [CelesTrak usage policy](https://celestrak.org/usage-policy.php) | Refresh only needed changed data and respect provider usage |
| SC-12 | [HYG licence](https://github.com/astronexus/HYG-Database/blob/main/LICENSE) | CC BY-SA 4.0 upstream data licence |
| SC-13 | [OpenNGC README](https://github.com/mattiaverga/OpenNGC/blob/master/README.md) | CC BY-SA 4.0, field provenance and M40/M45 addendum |
| SC-14 | [HiPS 1.0 Recommendation](https://www.ivoa.net/documents/HiPS/20170519/REC-HIPS-1.0-20170519.pdf) | Stable HEALPix-based progressive-survey format; not survey rights |
| SC-15 | [TAP 1.1](https://www.ivoa.net/documents/TAP/) | Catalogue service protocol |
| SC-16 | [ADQL 2.1](https://www.ivoa.net/documents/ADQL/) | Astronomical query language |
| SC-17 | [IANA tzdb](https://www.iana.org/time-zones) | Current source page reports 2026f; date-specific observation |
| SC-18 | [IMO calendar](https://www.imo.net/calendar/) | Meteor calendar candidate; reuse/ingestion agreement not established |
| SC-19 | [USGS SRTM overview](https://www.usgs.gov/centers/eros/science/usgs-eros-archive-digital-elevation-shuttle-radar-topography-mission-srtm) | Elevation candidate; local obstructions and sky brightness are separate |

## Service terms, rights and release

| ID | Primary source | Evidence used / limit |
|---|---|---|
| OP-01 | [GeoNames dump README](https://download.geonames.org/export/dump/readme.txt) | Current dump schema and CC BY 4.0 |
| OP-02 | [OSM tile policy](https://operations.osmfoundation.org/policies/tiles/) | Attribution, identification, caching and no bulk offline prefetch |
| OP-03 | [Open-Meteo terms](https://open-meteo.com/en/terms) | Hosted free-service eligibility/limits and data licence distinction |
| OP-04 | [MediaWiki API etiquette](https://www.mediawiki.org/wiki/API:Etiquette) | Identified considerate API access/caching |
| OP-05 | [Commons reuse](https://commons.wikimedia.org/wiki/Commons:Reusing_content_outside_Wikimedia) | File-specific credits/licences and derivative requirements |
| OP-06 | [NASA media policy](https://www.nasa.gov/nasa-brand-center/images-and-media/) | Media/brand/third-party distinctions |
| OP-07 | [ASP.NET OpenAPI](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/openapi/overview?view=aspnetcore-10.0) | First-party generation mechanism; actual API integration is pending |
| OP-08 | [PostgreSQL licence](https://www.postgresql.org/about/licence/) | Independent server database licence |
| OP-09 | [Redis licence overview](https://redis.io/de/legal/licenses/) | Official indexed text establishes Redis 8 licence choices; direct page later timed out |
| OP-10 | [SQLite copyright](https://www.sqlite.org/copyright.html) | SQLite deliverable public-domain status, separate from Dart wrapper |
| OP-11 | [Apple membership](https://developer.apple.com/programs/enroll/) | USD 99/year observation, regional/waiver qualifications |
| OP-12 | [Google Play registration](https://support.google.com/googleplay/android-developer/answer/6112435?hl=en) | USD 25 one-time observation and account setup |
| OP-13 | [Apple review guidelines](https://developer.apple.com/app-store/review/guidelines/) | Privacy/permission and in-app account-deletion requirements |
| OP-14 | [Google account deletion](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en) | In-app path and external deletion-request resource |
| OP-15 | [Google Data safety](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en) | App and SDK data disclosure obligations |
| OP-16 | [Apple privacy manifests](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files) | PrivacyInfo.xcprivacy and required-reason API declarations |
| OP-17 | [Android 16 KB pages](https://developer.android.com/guide/practices/page-sizes) | Native library compatibility; recheck release deadlines at submission |

## Access limitations and unresolved sources

| Source attempted | Observed result | Consequence |
|---|---|---|
| [ESA Gaia licence](https://www.cosmos.esa.int/web/gaia-users/license) and [DR3](https://www.cosmos.esa.int/web/gaia/data-release-3) | HTTP 451 | No current Gaia redistribution approval inferred; source/release/rights research stays open |
| [CDS HiPS overview](https://aladin.cds.unistra.fr/hips/) | Timeout | Use accessible stable IVOA format source; per-survey rights remain separate |
| Flutter Windows release JSON under the publisher's storage endpoint | HTTP 404 | No SDK patch/Dart pair snapshot produced; resolve via a working official archive when scaffolding |
| OpenNGC root `LICENSE` path | Requested file not retrieved | Licence statement was read in the actual upstream README instead |
| Old guessed GeoNames terms URL | Unavailable / linked to general export page | Dump README is the reviewed licence source |
| [MPCORB](https://minorplanetcenter.net/iau/MPCORB.html) | HTTP 403 | Candidate only; no parser/feed/rights adoption |
| [NASA Black Marble](https://blackmarble.gsfc.nasa.gov/) → Earthdata project | Redirect followed by HTTP 403 | A possible research lead, not an approved light-pollution layer |

Do not route around access restrictions or replace them with unverified third-party assertions. Source availability issues here do not mean a service is unavailable to all users worldwide.

## Repository evidence

### K-050 implementation follow-up sources

| ID | Primary source | Evidence used / limit |
|---|---|---|
| AUD-01 | [Cylinders — author album page](https://chriszabriskie.com/cylinders/) | Cylinder Four identity, author-hosted audio player URL and 2014 album; cover artwork is not imported |
| AUD-02 | [Author use terms](https://chriszabriskie.com/use/) | CC BY 4.0, creative/commercial reuse with attribution; exact asset/hash/credit in the audio manifest |
| AUD-03 | [just_audio](https://pub.dev/packages/just_audio) | Asset/repeat/playback/lifecycle API; resolved app version is in the app lockfile, not the older research snapshot |
| FL-14 | [Flutter UIScene migration](https://docs.flutter.dev/release/breaking-changes/uiscenedelegate) | `applicationRegistrar.messenger()` in the implicit-engine callback; no local iOS build is inferred |

The [implementation evidence](../../mobile-sky-first-evidence.md) supersedes research-baseline statements about no native app/solver/bridge. Existing access failures above remain historical observations.

Inspected baseline `07bdc3a`: root requirements/roadmap/decisions and `AGENTS.md`; API endpoint/authentication definitions; centralized .NET dependency versions; production image declarations; Web dependencies; catalogue/place/event manifests and notes; account-language, notebook, mobile-pointing, science and mobile/backend audit documents. No private environment file, credential, personal database record or precise device location was read for this research.

Useful local records: [requirements](../../urun-gereksinimleri.md), [roadmap](../../yol-haritasi.md), [decisions](../../kararlar.md), [phone tracking](../../phone-sky-tracking.md), [same-backend goal](../../web-tamamlama-ve-ortak-backend-mobil-hedef.md), [catalogue](../../../data/catalog/README.md), [events](../../../data/events/README.md), [places](../../../data/places/README.md).


### K-051 primary-source follow-up

| ID | Source | Use / limit |
|---|---|---|
| IM-S01 | [ESO panorama](https://www.eso.org/public/images/eso0932a/), [rights](https://www.eso.org/public/outreach/copyright/) | 360° celestial sphere, galactic orientation, credit, 18-megapixel supplied image and restricted-original distinction; CC BY 4.0 |
| IM-S02 | [HNSKY author's projection experiment](https://www.hnsky.org/toast_pr.htm) | Galactic CAR registration and reported local ~1° photographic distortion; no HNSKY code imported |
| IM-S03 | [CelesTrak OMM documentation and usage](https://celestrak.org/NORAD/documentation/gp-data-formats.php) | Explicit JSON query, TEME/UTC/SGP4 defaults, two-hour source cadence/backoff |
| IM-S04 | [Vallado paper/source](https://celestrak.org/publications/AIAA/2006-6753/), [author FAQ](https://celestrak.org/publications/AIAA/2006-6753/faq.php) | Official propagator/reference vectors, source-use permission, TEME output and model assumptions |
| IM-S05 | [NOAA/NCEI WMM](https://www.ncei.noaa.gov/products/world-magnetic-model), [official software](https://www.ncei.noaa.gov/products/world-magnetic-model/software-coefficients-linux) | WMM2025 validity, public-domain source, ellipsoidal height, model limitations and official test values |

Downloaded numerical source/image archives are hash-pinned; no downloaded executable was run. See current evidence for actual tests and unaccepted physical/iOS gates.
