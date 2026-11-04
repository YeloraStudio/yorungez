# Yorungez mobile research library

**K-051 update:** [Immersive contract](../../mobile-immersive-discovery-plan.md) and [implementation/evidence](../../mobile-immersive-discovery-evidence.md) supersede older artwork/track/satellite/declination candidates where explicitly implemented. Historical research and physical/iOS/parity limits remain.

**K-050 implementation update:** [Sky-first plan](../../mobile-sky-first-plan.md) and [actual evidence](../../mobile-sky-first-evidence.md) now supersede catalogue-home, no-native-binding and mobile-ground candidates. The implementation has a resolved graph and a real-data/native-C scene, while iOS/physical/rendering/account-parity gates remain open. Research baseline statements below remain historical.

**Implementation update — K-049:** The owner subsequently authorized Flutter development. [Foundation evidence](../../mobile-foundation.md) and [app setup](../../../src/Yorungez.Mobile/README.md) record the resolved SDK/dependencies, Android debug build and first offline catalogue slice. Statements below about no application or package solver describe the research baseline, not the current implementation. iOS, live-sky, pose and rendering acceptance remain open.

**Research date:** 4 November 2026. **Product direction:** K-048. **Repository baseline:** `07bdc3a`.

The owner selected **Flutter for an installable Android and iOS application**, sharing the existing .NET backend. The application will be free to use and advertising-free, with online and offline capabilities. Web/PWA development continues, but this research primarily prepares the mobile application. Flutter is the selected client framework; the renderer, astronomy binding and sensor adapters remain engineering decisions to validate.

This is a research and implementation-readiness library. No Flutter application, resolved dependency graph, native binary, device benchmark or store submission was produced in this work.

## Catalogues

| Catalogue | Question answered |
|---|---|
| [01 — Architecture and ownership](01-architecture-and-product-contract.md) | What is fixed, what is shared, and what belongs on the device? |
| [02 — Flutter stack and dependency candidates](02-flutter-stack-and-dependencies.md) | Which packages are candidates, under which versions/licences, and with which gaps? |
| [03 — Position, sensors, camera and AR](03-position-sensors-camera-and-ar.md) | How can pointing match the real sky, and what must be native? |
| [04 — Sky rendering and visual assets](04-sky-rendering-and-visual-assets.md) | Which rendering approaches should be compared before committing? |
| [05 — Astronomy, time and scientific validation](05-astronomy-time-and-validation.md) | Which calculations run offline, and how do we establish correctness? |
| [06 — Data and service catalogue](06-data-and-service-catalogue.md) | Where do stars, images, events, places and observing conditions come from? |
| [07 — Offline packages, API and identity](07-offline-packages-api-and-identity.md) | What works offline, how is content updated, and how does the same account work? |
| [08 — UX, languages and accessibility](08-ux-languages-and-accessibility.md) | How do we preserve the product experience across devices and languages? |
| [09 — Licensing, privacy, operating cost and distribution](09-licensing-privacy-cost-and-distribution.md) | What can be redistributed, what costs money, and what is required to publish? |
| [10 — Experiments, acceptance and delivery](10-experiments-acceptance-and-delivery.md) | What evidence is needed to start and deliver the mobile application? |
| [Source register](sources.md) | Which primary sources support the findings, and what could not be verified? |
| [Package metadata snapshot](package-snapshot.json) | What did pub.dev report on the research date? |

The [earlier competitor study](../../arastirma-stellarium-skyview-2026-11-04.md) remains a dated reference. Its recommendation to defer framework selection is superseded by the owner's Flutter decision. Its competitor feature, privacy and evidence limits still apply.

## Status language

- **Confirmed direction:** owner instruction or existing product contract.
- **Observed:** repository inspection or a primary source, as dated here.
- **Recommended candidate:** an engineering recommendation, requiring compatibility and implementation review.
- **Experiment required:** feasibility, accuracy or performance is unresolved.
- **Deferred:** useful later, outside the initial mobile slice.
- **Unavailable evidence:** a source could not be read; no assumption fills the gap.

An observed package version is not a version pin. The snapshot contains top-level registry metadata for 28 candidates, including publication timestamps, SDK constraints, archive hashes and registry-detected licences. It is neither an SBOM nor a transitive/native licence audit. No package solver was run.

## Principal findings

1. A heading-only compass package does not supply the complete rear-camera pose contract. A small Kotlin/Swift adapter around OS-fused orientation is the leading candidate.
2. A camera preview and precise astronomical overlay have separate requirements. Lens selection, intrinsics/FOV, crop, orientation, reference frame and timing must agree.
3. The renderer is the main unproven dependency. Compare a batched Canvas/shader baseline with Flutter GPU/Scene and a native-renderer option using the same sky dataset and devices.
4. Astronomy Engine's C implementation is a strong offline binding candidate because the backend/Web already use the same project. Port equality is still a test obligation.
5. Public offline content is compatible with existing policy. Persistent offline notes/favourites/observations are **not newly authorized** by general offline support; personal writes continue to require the server.
6. `timezone` documentation reports bundled **2025c**, while the IANA page reports **2026f** on this date. Package currency does not establish data currency; resolve the actual packaged tzdb before adoption.
7. CelesTrak now documents six-digit catalogue identifiers; modern GP/OMM ingestion should be evaluated rather than a TLE-only design.
8. Free and advertising-free distribution still has developer-account, build, hosting and bandwidth costs. These belong in the operating plan, without charging users or adding advertising.

Evidence for findings: [sensor catalogue](03-position-sensors-camera-and-ar.md), [rendering catalogue](04-sky-rendering-and-visual-assets.md), [time catalogue](05-astronomy-time-and-validation.md), [data catalogue](06-data-and-service-catalogue.md), [cost catalogue](09-licensing-privacy-cost-and-distribution.md).

## How this library is maintained

Keep source facts, recommendations and measured outcomes separate. Refresh time-sensitive versions, service terms and store rules before adoption or release. Record a source URL, access date, exact selected revision, licence, alternatives, remaining risk and an acceptance experiment for every adopted dependency. Update source records when evidence is unavailable or contradictory. Do not download a catalogue, mirror a survey or install a package merely because it appears here.

The next work after this research remains Web/PWA development that strengthens shared astronomy, content, API and user journeys. Mobile experiments are prepared in catalogue 10; the research does not silently claim that Web acceptance is complete.

## Documentation verification

On 4 November 2026, local checks found ten numbered catalogues, 28 package records matching the version/licence table, 84 unique source-register IDs, and no missing targets among 352 checked local links across this library and the updated plan/index records. JSON parsing and `git diff --check` passed. Percent-encoded local paths were decoded during link validation.

These are documentation consistency checks. They do not verify all external links, certify licences, resolve the Flutter dependencies, execute a build, or establish scientific/device acceptance. Source access failures remain recorded in [the register](sources.md).
