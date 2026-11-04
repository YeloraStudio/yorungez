# 09 — Licensing, privacy, operating cost and distribution

**Status:** dated engineering/release research; exact selected distributions require review before adoption. **Traceability:** K-029/042/048, FR-07–09/11.

## Product economics

The mobile product is **free to use and advertising-free**, as selected by the owner. No advertising network, paid sky tier or subscription is proposed. This does not make development, store distribution or public data hosting cost-free.

| Item | Research finding / planning treatment |
|---|---|
| Apple distribution account | Apple lists USD 99 per membership year, with regional pricing and eligibility-based waivers |
| Google Play developer account | Google lists a USD 25 one-time registration fee; account-type/verification/testing requirements apply |
| iOS builds | macOS and Xcode required; choose owned Mac or a budgeted Mac runner/service |
| Android builds | Supported desktop runner with pinned Java/SDK/NDK/Gradle; native binaries increase compatibility testing |
| Images/star/survey packs | Storage and transfer costs scale with pack size and update frequency |
| Backend/mail | Existing hosting, operations and email remain operating responsibilities |
| Hosted data providers | Free quotas and service eligibility are not unlimited service guarantees |

Primary pricing/build sources: [Apple membership](https://developer.apple.com/programs/enroll/), [Play Console](https://support.google.com/googleplay/android-developer/answer/6112435?hl=en), [Flutter iOS release](https://docs.flutter.dev/deployment/ios), [Android release](https://docs.flutter.dev/deployment/android). Prices are a dated observation, not a Turkish invoice estimate.

Suggested bandwidth model: `downloads × compressed pack bytes + changed-pack downloads + API/image traffic`. Report assumptions and cache hit rates; a user's optional 8K pack should not silently become every user's launch download. Prefer owned/licensed static packages and bounded refresh over a paid API call for every phone movement.

Open-Meteo's free hosted service is explicitly non-commercial with request limits. A free/ad-free app is not a blanket determination of a studio's eligibility. Resolve eligibility or an alternative before depending on it; keep basic sky use independent. [Provider terms](https://open-meteo.com/en/terms).

## Licence boundaries

| Layer | Treatment |
|---|---|
| Original Yorungez code/docs | Existing Apache-2.0 decision remains |
| Flutter/Dart packages | Inspect exact release, all native/transitive dependencies and notices; registry metadata is only preliminary evidence |
| Astronomy Engine | MIT upstream; retain attribution and exact selected revision |
| HYG/OpenNGC derivatives | Their CC BY-SA data obligations remain; do not relabel them as Apache-2.0 |
| Survey/photo/art assets | File/survey-specific rights, creators and changes; offline redistribution must be permitted |
| SQLite | SQLite deliverable is public domain; Dart wrapper licence is separate |
| Existing server Redis | Current compose uses Redis 8; current upstream offers RSALv2/SSPLv1/AGPLv3 choices, not a blanket BSD licence |
| PostgreSQL | Separate PostgreSQL licence; stays a server component |

Evidence: [Yorungez licence decision](../../adr/0014-acik-kaynak-yayin-ve-apache-2.md), [package snapshot](package-snapshot.json), [Astronomy Engine licence](https://github.com/cosinekitty/astronomy/blob/master/LICENSE), [HYG licence](https://github.com/astronexus/HYG-Database/blob/main/LICENSE), [OpenNGC](https://github.com/mattiaverga/OpenNGC/blob/master/README.md), [SQLite](https://www.sqlite.org/copyright.html), [Redis licence overview](https://redis.io/de/legal/licenses/), [PostgreSQL](https://www.postgresql.org/about/licence/).

Redis is an independently deployed service; this research does not conclude that using its protocol automatically relicenses Yorungez, and does not change the deployed service. Record the chosen distribution/terms in the existing infrastructure review. MediatR remains pinned to the existing 12.5.0 decision; mobile research is not permission for a licence-changing upgrade.

Stellarium desktop, its AGPL Web Engine and its mobile product are distinct licensing subjects. They are reference products rather than an assumed Apache-compatible asset supply. Retain the existing comparison's restrictions and per-file credits. [Earlier research](../../arastirma-stellarium-skyview-2026-11-04.md).

## Privacy architecture

Recommended mobile baseline: local camera preview and pose processing; foreground, purpose-specific location; no raw sensor/video/precise-location analytics; no advertising identifiers or advertising SDK. Personal inventory remains account-owned on the server under current rules. Default diagnostics should use coarse capability/error labels and request IDs without credentials, notebook content or coordinates.

Native manifests must reflect actual behaviour. Do not copy a plugin's full example permissions if the feature only needs preview or foreground location. Review merged Android permissions, iOS usage descriptions, required-reason APIs and third-party privacy manifests. Apple documents `PrivacyInfo.xcprivacy`; Google requires Data safety declarations covering SDKs as well as app code. [Apple manifest documentation](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files), [Google Data safety](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en).

Free/ad-free does not mean “no data collected”: account email/name, server inventory, security sessions and explicitly stored places still need truthful disclosure. A future crash-reporting service needs a separate data-flow/retention decision; it is not part of this candidate stack by default. Device permission denial must leave useful manual exploration.

## Native publication requirements to prepare

Store accounts, final package/bundle IDs, publisher identity, signing ownership, application icons/screenshots, EN/TR descriptions, support/privacy URLs, age/content declarations and a device support policy are release inputs. None was registered or submitted during this research.

Account creation brings a concrete release dependency: Apple requires account deletion within the app; Google also requires an in-app path and an external web request resource. Existing notebook trash/restore is not the same as deleting an account and its associated data. This was previously deferred in Web priorities, so it remains a **mobile release gate**, not a new feature being implemented now. [Apple review 5.1.1](https://developer.apple.com/app-store/review/guidelines/), [Google deletion requirement](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en).

Validate native dependencies for Android 16 KB page-size compatibility and selected target SDK/ABI requirements, especially astronomy, SQLite and renderer binaries. Recheck current store deadlines at release instead of freezing them from old advice. [Android page-size guidance](https://developer.android.com/guide/practices/page-sizes).

## CI and signing proposal

Extend existing GitHub CI with path-scoped Dart analysis/tests, generated-contract checks, scientific native parity, Android builds and a macOS iOS build. Keep Web/API gates intact. Store signing keys, provisioning credentials, store API credentials and private environment settings outside source control. Document key recovery/rotation and signing-account ownership before distribution.

Use internal Android testing and TestFlight for measured acceptance before production submission. A green build or simulator screenshot is not evidence of magnetic/lens accuracy. No new hosted CI subscription, cloud account, analytics service or store fee was purchased by this research.
