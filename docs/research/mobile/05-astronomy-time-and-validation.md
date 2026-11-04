# 05 — Astronomy, time and scientific-validation catalogue

**Status:** recommended calculation approach; no new scientific acceptance. **Traceability:** FR-01–05/08, existing science strategy and frozen references.

## Calculation candidates

| Candidate | Best role | Constraint / recommendation |
|---|---|---|
| Astronomy Engine C through Dart FFI | Offline Sun/Moon/planet calculations and supported events | Leading candidate: same upstream as current C#/JS; preserve exact model revision and establish native port equality |
| A Dart translation or third-party astronomy package | Pure Dart distribution | Audit provenance, algorithms, maintenance, licence and independent tests; no Dart port is selected by this research |
| Astronomy Engine Kotlin | Android-only alternative | Does not provide an equivalent iOS implementation by itself |
| ERFA / IAU SOFA | Precise coordinate/time routines when justified | Additional scope and licence/integration obligations; not a substitute for every planetary ephemeris |
| Astropy / Skyfield in Python | Build-time ingestion and independent scientific references | Keep outside the phone's interactive render path; avoid adding a Python server request per view frame |
| JPL Horizons | Independent reference samples and selected prepared data | Respect service policy; not a required online dependency for ordinary sky pointing |

Astronomy Engine lists C, C#, JavaScript, Python and Kotlin implementations, with solar-system/event and coordinate-transform APIs. Upstream targets approximately one arcminute; that statement does not replace our feature-specific tests or establish camera accuracy. [Upstream scope](https://github.com/cosinekitty/astronomy), [MIT licence](https://github.com/cosinekitty/astronomy/blob/master/LICENSE).

FFI bindings can be generated around a narrow C ABI, using Flutter's current `package_ffi`/build-hook approach. Pin source, generated binding and native build settings; verify every target ABI. [Flutter C interop](https://docs.flutter.dev/interop/bind-native-code). No native binding has been built here.

The binding experiment must verify struct layout, enum/status mapping, ownership/lifetime, error propagation and reentrancy of the exact selected C implementation. A package being written in C is not proof that concurrent calls are safe. Prefer a bounded worker and batched scientific results; do not cross the ABI separately for every star on every display tick. App pause/resume must not leave native buffers referenced by a disposed renderer.

SOFA defines standard fundamental-astronomy routines under its own licence. ERFA is a related alternative whose exact licence/revision also needs recording. Astropy provides the independent coordinate pipeline already used by this repository. [SOFA](https://www.iausofa.org/), [ERFA licence](https://github.com/liberfa/erfa/blob/master/LICENSE), [Astropy coordinates](https://docs.astropy.org/en/stable/coordinates/).

## Scientific context contract

Every result should be reproducible from model/version, object ID, UTC instant, observer coordinates/elevation datum and calculation options. Record frame and epoch, units, topocentric/geocentric meaning, geometric/apparent definition and refraction choice. Never compare differently defined results simply because both expose `altitude`.

Handle stars/DSOs separately from solar-system ephemerides: source epoch, proper motion, uncertainty, catalogue-specific magnitudes and extended-object geometry matter. Missing distances/radii are missing, not zero. Broad features such as the Milky Way cannot be reduced to a fabricated point target or a single rise/set time.

Recommended scheduling separates slow model/catalogue work from rapid view rotation. Cache results by scientific context and invalidate on observer/time/model change. Worker outputs need generation IDs to reject late results. Use a persistent isolate for repeated heavy work rather than spawning a worker for each sensor event. [Dart isolates](https://dart.dev/language/isolates).

## Time, zones and offline operation

UTC is the canonical selected instant. Display local civil time with an IANA zone and the date's offset; a fixed GMT offset cannot describe all global/historical time. Preserve explicit Live versus Simulation modes and a return-to-now control. Local-time gaps and repeated times need validated conversion and explicit resolution, matching the current Web contract.

The `timezone` package handles named-zone rules; it does not itself resolve a coordinate to its zone or discover the device's zone. Its documentation currently states bundled **2025c**, while IANA publishes **2026f**. The actual dependency archive and generated database must be checked before use: a newer package version alone does not prove fresh rules. [Dart timezone package](https://pub.dev/packages/timezone), [IANA source](https://www.iana.org/time-zones).

Coordinate-to-zone lookup is a separate data/geometry service. Options are the shared service initially, or a licensed offline boundary subset with tested border/ocean behaviour. Device timezone and selected observer timezone can differ. UTC fallback should be explicit while lookup is unavailable. No timezone-boundary dataset or new mobile service was selected here.

Do not equate UTC, UT1, TT and an engine's internal time argument. Review leap-second/Earth-orientation assumptions with the selected model and declared accuracy scope; civil tzdb updates are not an astronomy ephemeris update. Horizons documents time/frame choices and is suitable for matching reference definitions. [Horizons manual](https://ssd.jpl.nasa.gov/horizons/manual.html).

## Events and observing conditions

Keep global event instant, local geometric visibility and actual observing conditions separate. Lunar phase, conjunction, close angular approach, occultation, eclipse and meteor-shower activity need event-specific definitions. A conjunction in ecliptic longitude is not automatically the smallest apparent separation seen by an observer.

USNO supplies documented lunar-phase and other astronomy services; retain the existing frozen reference archive. [USNO API](https://aa.usno.navy.mil/data/api). Extend event families with independent reference cases and meaningful tolerances before exposing them.

For satellites, GP elements require their matching propagation model and freshness handling. Skyfield documents rapidly ageing element sets and SGP4-specific limitations. A downloaded element set must not be advertised as an exact indefinite offline track. [Skyfield satellite documentation](https://rhodesmill.org/skyfield/earth-satellites.html).

## Acceptance inherited and still required

The repository currently limits its validated first model to 2000–2035 and withholds azimuth near the declared polar boundary. Existing JPL, Astropy and event comparisons retain their documented failures/assumptions. They are reference inputs for a native port, not evidence that it already passes. [Current science evidence](../../astronomi-denemesi.md), [catalogue validation](../../harita-ve-katalog-denemesi.md), [calendar evidence](../../gozlem-cizelgesi-ve-takvim.md).

Required native checks: C#/JS/C-binding equality under matching options; independent fixed references; UTC/zone edge cases; epoch/proper-motion examples; low-horizon/refraction variants; polar/no-rise/no-set states; Moon parallax; extreme zoom projection; and model-version rejection. A correct celestial vector and a correctly aligned physical phone are separate acceptance results.
