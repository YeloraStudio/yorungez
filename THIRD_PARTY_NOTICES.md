# Third-party dependency inventory

## Flutter foundation — 4 November 2026

Exact direct/transitive app versions are in [pubspec.lock](src/Yorungez.Mobile/pubspec.lock). Licence texts were inspected in the locally resolved package archives; this table is a direct-dependency inventory, not a complete native release SBOM.

| Component | Resolved version | Licence |
|---|---|---|
| Flutter SDK / flutter_localizations | 3.41.6, revision db50e20168db8fee486b9abf32fc912de3bc5b6a | BSD-3-Clause; SDK/package notices retained by Flutter's bundled licence registry |
| flutter_riverpod | 3.3.2 | MIT |
| go_router | 17.5.0 | BSD-3-Clause |
| dio | 5.11.1 | MIT |
| crypto | 3.0.8 | BSD-3-Clause |
| intl | 0.20.2 | BSD-3-Clause |
| flutter_launcher_icons (development asset exporter) | 0.14.4 | MIT |
| camera | 0.12.0+2 | BSD-3-Clause; official Flutter package licence inspected locally |
| geolocator | 14.1.2 | MIT |
| just_audio | 0.10.6 | MIT |
| shared_preferences | 2.5.6 | BSD-3-Clause |
| ffi | 2.2.0 | BSD-3-Clause |
| audio_session | 0.2.4 | MIT |

The native Sources screen exposes the generated Flutter software-licence registry and separately staged HYG/OpenNGC/d3-celestial/Astronomy Engine notices. K-050 now builds the pinned MIT C source recorded in [its manifest](third-party/astronomy-engine/source/c/manifest.json), using an original Apache-2.0 wrapper; native pose adapters are original Kotlin/Swift code. Twelve bundled archive images retain their canonical per-file rights below. [Cylinder Four by Chris Zabriskie](data/audio/README.md) is unchanged author-hosted CC BY 4.0 audio with source/hash/attribution. No AR, personal database or credential-storage package is adopted. Shared preferences store only notice version and mute. Preserve transitive/native notices and perform release-specific review before store distribution. [Current evidence](docs/mobile-sky-first-evidence.md); [initial foundation snapshot](docs/mobile-foundation.md).


**TECH-04C:** [GeoNames CC BY 4.0 attribution and modifications](third-party/geonames/NOTICE.md), [source/derived SHA manifest](data/places/manifest.json). USNO numeric primary-phase/rise-set facts retain URLs, retrieval/hash and time-precision attribution in [events](data/events/README.md) and [observing references](tests/ReferenceData/Observing/README.md). These are factual data, not copied website prose or Stellarium calendar assets/code.

**TECH-04B addition:** Stara Lesna Meadows original photographic PNG, Ľubomír Hambálek, [upstream source and licence discrepancy](third-party/stara-lesna/NOTICE.md), [SHA manifest](data/catalog/landscape-manifest.json). Listing: CC BY-SA 4.0; supplied archive readme: CC BY 4.0; both retained. No Stellarium runtime code imported; WebGL scene and compass adapter are Yorungez code, original Yorungez code is Apache-2.0 (K-029 / ADR-0014).

Recorded 2026-10-31. This inventory records selected components; it does not replace upstream license texts. Original Yorungez code/documentation is Apache-2.0; third-party material retains its own terms. Package artifacts retain their license metadata. Redis/PostgreSQL/Mailpit are separate local development services. TECH-02B/03 adds the initial HYG/d3-derived catalogue and Next.js frontend; data licenses are separate from runtime code.

| Component | Pinned version | License evidence |
|---|---|---|
| Serilog.AspNetCore (and Serilog logging dependencies) | 10.0.0 integration; transitive pins in API lockfile | Apache-2.0; [upstream licence](https://github.com/serilog/serilog-aspnetcore/blob/v10.0.0/LICENSE), NuGet package licence metadata |
| MediatR | 12.5.0 | Apache-2.0, verified in downloaded NuGet metadata and [tagged LICENSE](https://raw.githubusercontent.com/LuckyPennySoftware/MediatR/v12.5.0/LICENSE) |
| CosineKitty.AstronomyEngine (C#), astronomy-engine (JS probe + Web Worker) | 2.1.19 | MIT verified in package metadata and [upstream license](https://raw.githubusercontent.com/cosinekitty/astronomy/v2.1.19/LICENSE); preserved [LICENSE](third-party/astronomy-engine/LICENSE) and [upstream record](third-party/astronomy-engine/UPSTREAM.json) |
| ASP.NET Core / EF Core / Microsoft caching and testing packages | 10.0.14 package line | MIT, package metadata; [ASP.NET Core](https://github.com/dotnet/aspnetcore/blob/main/LICENSE.txt), [EF Core](https://github.com/dotnet/efcore/blob/main/LICENSE.txt) |
| Npgsql / Npgsql EF provider | 10.0.3 | PostgreSQL license, downloaded package metadata; [Npgsql license](https://github.com/npgsql/npgsql/blob/main/LICENSE) |
| System.IdentityModel.Tokens.Jwt | 8.23.0 | MIT, downloaded package metadata; [source license](https://github.com/AzureAD/azure-activedirectory-identitymodel-extensions-for-dotnet/blob/dev/LICENSE.txt) |
| MailKit (with MimeKit dependency) | 4.18.2 MailKit | MIT, downloaded package metadata; [MailKit license](https://github.com/jstedfast/MailKit/blob/master/LICENSE) |
| PostgreSQL server | 18.6-alpine | [PostgreSQL license](https://www.postgresql.org/about/licence/) |
| Redis server | 8.10.3-alpine | AGPLv3 option selected from Redis 8's [AGPLv3/RSALv2/SSPLv1 alternatives](https://redis.io/legal/licenses/); no modified Redis distribution |
| Mailpit local email sink | v1.32.0 | [MIT](https://github.com/axllent/mailpit/blob/develop/LICENSE) |
| Next.js / React + React DOM | 16.4.3 / 19.3.1 | MIT package metadata and bundled LICENSE texts; exact graph in `src/Yorungez.Web/package-lock.json` |
| Sharp (explicitly pinned brand format exporter / asset validation; previously a locked Next.js dependency) | 0.35.5 | Apache-2.0 package metadata/LICENSE; original native dependency notices remain in installed artifacts. TECH-09 renders the project-owned SVG/PNG brand masters. |
| TypeScript; Node/React type definitions | 5.9.3; 22.20.5 / 19.3.0 | TypeScript Apache-2.0, type definitions MIT; development-only package metadata/LICENSE files |
| HYG Database | 4.1, commit c7f7f883fe678cc7680169a50ccd7dcc49b060ce | [CC BY-SA 4.0 license notice](third-party/hyg/LICENSE.md); David Nash / Astronexus. Derived star data remains CC BY-SA 4.0; [source hashes, attribution and modifications](data/catalog/README.md) |
| d3-celestial constellation line/name data only | commit 7e720a3de062059d4c5400a379146a601d9010e0 | [BSD-3-Clause](third-party/d3-celestial/LICENSE), copyright Olaf Frohn; IAU/Wikipedia naming-source attribution retained. No d3 runtime/other star data/artwork imported |
| Astropy, astropy-iers-data, NumPy, PyERFA | 8.0.2 / 0.2026.10.19.0.52.1 / 2.5.4 / 2.0.1.5 | Isolated validation tools, BSD-3-Clause package metadata/licenses; [locked versions](scripts/science/requirements-reference.lock.txt). Not production Python dependencies |
| packaging; PyYAML (reference environment) | 26.3; 6.0.3 | packaging BSD-2-Clause/Apache-2.0, PyYAML MIT, package metadata; validation-only |
| Leaflet | 1.9.4 | [BSD-2-Clause](third-party/leaflet/LICENSE); optional user-opened Earth picker. OSM attribution/cache policy applies separately |
| @js-temporal/polyfill | 0.5.1 | [ISC](third-party/temporal/LICENSE); explicit IANA local-time / UTC / DST handling |
| geo-tz (server only, comprehensive/all data) | 8.1.10 | [MIT](third-party/geo-tz/LICENSE.md) code; timezone-boundary-builder geographic data under ODbL, derived from OSM. Server data stays out of browser bundles; full npm lock records transitives |
| OpenNGC data | commit be3cd6c5498806a2fbb2f7e0452ef802dbb02be0 | [CC BY-SA 4.0](third-party/openngc/LICENSE.txt), Mattia Verga and contributors; 107 Messier matches reformatted; manifest records source/content hashes |
| Stellarium Western artwork | commit 014fbb5e59233d133c22f9811af96b67d05a95c9 | Johan Meuris, Free Art License; [upstream and licence notice](third-party/stellarium-art/NOTICE.md), 85 unmodified images. No Stellarium engine code imported |
| Wikipedia extracts / Wikimedia Commons Sun photograph | pinned revisions in sun-content.json | Text: Wikipedia contributors, CC BY-SA 4.0. Photograph: Matúš Motlo, CC BY-SA 4.0. Per-item source/revision/licence/credit/hash retained in [data record](data/catalog/README.md); archive image, not live photography |

| Additional object photographs | 11 source JPEG previews pinned in [object-media.json](data/catalog/object-media.json) | Moon: Gregory H. Revera CC BY-SA 3.0; Mars: ESA/MPS/OSIRIS team CC BY-SA 3.0 IGO; M31: Lviatour CC BY-SA 2.5; Sirius: NASA/ESA/H. Bond/M. Barstow CC BY 3.0 retained alongside the file's public-domain declaration; other planetary/M42 files retain their individual public-domain declarations and credits. [Full per-file credit/licence table and discrepancy](data/catalog/README.md#tech-11d--object-archive-photographs). No blanket NASA exemption or Apache-2.0 relicensing. |

| Milky Way panorama preview | ESO `eso0932a`, supplied screensize JPEG | ESO/S. Brunier, CC BY 4.0; unchanged 155,879-byte preview, visible credit, original source/rights/date/hash in [sky-features.json](data/catalog/sky-features.json). Restricted full-resolution original excluded. [Source](https://www.eso.org/public/images/eso0932a/) / [rights](https://www.eso.org/public/outreach/copyright/). |

Docker image digests are in `compose.yaml`. Direct .NET pins are in `Directory.Packages.props`; resolved graphs including tests are in `packages.lock.json` (restore `--locked-mode`). Frontend/probe graphs are in their own npm lock files. Preserve upstream copyright/license/NOTICE files when packaging components; produce a release-specific complete transitive inventory before distribution. This initial prototype inventory does not approve all future source/data licenses.

MediatR 12.5.0 is an explicit older Apache-2.0 pin chosen to meet the requested no-paid-license foundation. It is not a noncommercial-only license. Later releases require a fresh licensing and maintenance assessment; automated major-version migration must not silently change this decision.

Numeric NASA/JPL Horizons observer ephemerides are retained as validation facts with request URLs, retrieval times, response signatures and hashes in [reference data](tests/ReferenceData/Horizons/README.md). They are not redistributed as an astronomical image/star catalogue or as Yorungez-authored observations. [Method and limitations](docs/astronomi-denemesi.md). JavaScript probe dependencies use `tools/science-js/package-lock.json`; the Web uses its own lock with the same Astronomy Engine 2.1.19 MIT pin. Astropy/ERFA produces [frozen stellar numeric references](tests/ReferenceData/Stars/README.md) only. Stellarium Web Engine, Aladin and Skyfield runtimes remain uninstalled candidates. Separately, 85 Stellarium skyculture illustrations are redistributed under Johan Meuris’s Free Art License with source/attribution; this does not import Stellarium AGPL engine code. Astropy also produces the [72 frozen DSO references](tests/ReferenceData/DeepSky/README.md).


**K-051 mobile additions (4 November 2026):** [Current implementation evidence](docs/mobile-immersive-discovery-evidence.md). path_provider 2.1.6 is a direct BSD-3-Clause dependency for a non-personal expiring public orbital packet; the previous UI-preferences-only statement is superseded only for this explicit public cache. Native personal storage remains absent.

- [ESO/S. Brunier 360° large JPEG](data/sky/manifest.json): CC BY 4.0, exact source/hash, runtime projection/low-pass/brightness/latitude weighting. This 6000×3000 publicly supplied image is separate from the earlier Web preview; the restricted 800-million-pixel original is excluded.
- Existing 85 Johan Meuris Free Art License 1.3 figures and their original catalogue anchors now also ship in the mobile client. Cultural illustration and true astronomical vectors remain distinct.
- [Vallado SGP4 source/verification/use permission](third-party/sgp4/NOTICE.md): unmodified official C++ source, exact archive/file hashes; authors permit personal/commercial use with citation. No named upstream software licence is inferred and these files are not relabelled MIT/Apache-2.0.
- [WMM2025 NOAA/NCEI public-domain source/coefficients/test values](third-party/wmm2025/NOTICE.md), with model validity and deterministic numeric transcription. Original Yorungez wrappers remain Apache-2.0.
- [Original EN/TR mobile summaries and derived Latin names](data/catalog/mobile-object-info.json): NASA factual source links and the same SHA-pinned d3-celestial name source/notice. No competitor brief/art/music asset is copied.

## Native account and external-browser plugins

- flutter_secure_storage **11.2.0**, BSD-3-Clause, German Saprykin and contributors. [Exact package licence](third-party/flutter-account-plugins/flutter_secure_storage.LICENSE); [upstream package](https://pub.dev/packages/flutter_secure_storage). Only rotating refresh credentials use platform-secure storage; no personal inventory is stored by this plugin.
- url_launcher **6.3.3**, BSD-3-Clause, The Flutter Authors. [Exact package licence](third-party/flutter-account-plugins/url_launcher.LICENSE); [upstream package](https://pub.dev/packages/url_launcher). User-initiated HTTPS links open in the external browser.
- The resolved application lockfile pins platform implementations. Flutter's generated software licence page retains their bundled package notices; the two direct plugin licences are also copied into the offline public source-notice asset.
