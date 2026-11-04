# 10 — Experiments, acceptance and delivery catalogue

**K-050 implementation update:** [Evidence](../../mobile-sky-first-evidence.md) now records partial native pose, a Canvas baseline, a C bridge with frozen-reference/JS parity checks, approximate camera and offline audio/content. MOB-EXP-02–06 therefore have implementation evidence; none is fully physically accepted. iOS, shared native accounts and complete UX/release acceptance remain open. [SKY-01–08](../../mobile-sky-first-plan.md) is the current delivery sequence.

**K-049 implementation update:** [The first Flutter foundation](../../mobile-foundation.md) now exists. M-R1 / MOB-EXP-01 is **partial**: SDK/graph/permissions are recorded and Android debug build passed; iOS, release/profile and native-library/16 KB verification remain open. The bundled offline catalogue and integrity/API/widget checks provide partial evidence for MOB-EXP-06/07/08, not full lifecycle/account/accessibility acceptance. MOB-EXP-02–05 are not run. M-0 and all physical-pointing gates remain open. The development ID is `com.yelorastudio.yorungez`, unregistered; the earlier no-scaffold statements below are historical.

**Status:** proposed implementation sequence and measurable exit evidence. At the research baseline, all experiments below were **not run**. **Traceability:** K-039/048, existing FR/UJ/AC scope.

## Development sequence

Research now prepares mobile engineering while the next implementation work continues on Web/PWA and shared foundations. Do not require every future catalogue or telescope feature before allowing a focused mobile prototype; do not label the whole Web product accepted because a prototype starts.

| Stage | Deliverable | Exit evidence |
|---|---|---|
| M-R0 — Research baseline | This library, package/source records, confirmed Flutter/free/ad-free direction | Links/IDs/status consistency; open technical questions visible |
| M-R1 — Toolchain and contract | Pinned SDK/Dart/Android/iOS matrix, narrow interfaces, API schema sample | Resolved graph; Android and iOS build; native licensing/permission inventory |
| M-R2 — Pointing/renderer/calculation experiments | One real-sky scene, OS-fused pose adapter, C calculation binding and camera projection | Device measurements and scientific reference results; justified choices |
| M-0 — First vertical mobile slice | Offline anonymous sky → search → object detail → pointing; same online account/language | EN/TR S23/iPhone journeys; no network dependency for pose/render |
| M-1 — Existing feature parity | Tonight, calendar, glossary, server notebook and optional content packs | Defined FR/UJ/AC parity matrix; online/offline/error flows accepted |
| M-2 — Release readiness | Account lifecycle, signing, privacy/rights, accessibility, performance and store materials | Physical acceptance and review checklist passed; owner-authorized release |

These stage IDs organise mobile work; they do not renumber, close or remove existing requirements. Initial app folder/package IDs remain to be agreed at scaffold time; no native app was created here.

## Experiment cards

### MOB-EXP-01 — Reproducible Android/iOS toolchain

Resolve a minimal dependency set against one stable Flutter/Dart pair. Check selected OS floors, Java/Kotlin/AGP/Gradle/NDK, Xcode and plugin/native package compatibility. Build release/profile artefacts for target devices, inventory native libraries and verify 16 KB Android compatibility. **Exit:** repeatable Android and macOS iOS build, exact versions recorded. A registry snapshot alone fails this gate.

### MOB-EXP-02 — OS pose and north-reference adapter

Implement the normalized pose contract with Android rotation-vector and iOS Core Motion candidates. Test source availability, true/magnetic/relative references, unit/axis conventions, screen rotation, pauses and interruptions. **Exit:** deterministic synthetic tests plus documented physical direction/elevation/drift results. Raw sensor samples or screenshots alone do not establish an error bound.

### MOB-EXP-03 — Renderer comparison

Implement the same camera path and catalogue subset in the Canvas/shader baseline and one GPU candidate. Add the third/native option only if a concrete requirement remains unmet. **Exit:** comparable first-frame, frame-time, memory, visual and thermal evidence, with a written choice and fallback. Do not select solely from promotional demos or package popularity.

### MOB-EXP-04 — Astronomy C bridge and parity

Compile the exact chosen upstream C revision for Android/iOS and expose a narrow typed ABI. Run repository scientific fixtures under matching frame/refraction options and compare against current C#/JS. **Exit:** frozen independent references, preserved exceptional cases and declared model window. Do not weaken tolerances to make a port pass.

### MOB-EXP-05 — Camera projection

Use local rear preview, lens identity and available intrinsics/FOV. Match sensor/display/video time, crop and orientation. Use several independent references across the view after calibration; reset on lens/format changes. **Exit:** centre/edge residuals and latency for both devices, a clear approximate mode when metadata is absent, reliable camera shutdown. A well-aligned single calibration target is insufficient by itself.

### MOB-EXP-06 — Offline public content lifecycle

Start offline on first install with the base package; install an optional pack; interrupt it; exhaust space; supply incompatible/corrupt data; restart during activation; remove optional data; reconnect. **Exit:** a working verified base, bounded resource use, correct source/licence display and no personal cache/queue added. Test signed-manifest authenticity independently from file-hash corruption detection if remote updates are enabled.

### MOB-EXP-07 — Shared API/account/language

Generate/review a client contract sample. Use one test account across Web and native clients; test confirmation/reset links, rotating refresh, concurrent 401s, revocation, account switch, preferred language and revision conflict. **Exit:** stable contracts and correct failure/recovery; no personal data in URL/log/offline packs. Mobile contract tests need a dedicated synthetic environment.

### MOB-EXP-08 — Native UX/accessibility and release

Run the catalogue 08 tasks in EN/TR on TalkBack/VoiceOver, large text and both orientations. Exercise account deletion before publication; inspect privacy/signing/distribution artefacts. **Exit:** documented acceptance and remaining limitations, not an inferred “100% accessible” label.

## Proposed measurement worksheet

Record app/build/model/package revisions; OS/device; render backend; lens/format; permission and reference mode; test environment and method. No public raw location/video log is required. Use synthetic coordinates for reproducible automated tests; physical observers can retain private context locally.

| Metric | Proposed measurement | Budget status |
|---|---|---|
| Celestial computation residual | Frozen vectors/events under matched definitions | Existing scientific tolerances retained unless a reviewed model change justifies new ones |
| Physical pointing residual | Angular separation between reference direction and normalized reported direction | Measure median, upper percentile and worst case; final threshold not yet selected |
| Calibration transfer/drift | Return to other targets after several turns and minutes | Proposed test, not passed |
| Sensor-to-present latency | Timestamped capture/render correlation; independent camera method where needed | Establish method and budget in experiment |
| Frame time | UI/raster/GPU distributions, dropped frames, refresh-rate context | 60 Hz implies roughly 16.7 ms/frame; target is proposed, device modes vary |
| Cold first sky | Launch to usable base sky with no network | Proposed target ≤3 s on agreed reference devices; unmeasured |
| Search response | Indexed public catalogue, language/alias corpus | Proposed target p95 ≤150 ms on agreed dataset/device; unmeasured |
| Memory/energy | Peak resident/native/GPU memory, battery delta and thermal behaviour over 15–30 min | Baseline first; limits chosen from measured safe operation |
| Offline pack lifecycle | Full disk/interruption/corruption/compatibility tests | Must preserve a usable verified base |
| API reachability/recovery | Offline/captive portal/timeout/5xx/401/conflict matrix | Correct state and bounded retries, not false save success |

Proposed numerical targets are initial engineering hypotheses, not owner-approved service guarantees or results. They must not be copied into marketing as achieved performance. [Flutter performance guidance](https://docs.flutter.dev/perf/best-practices), [integration tests](https://docs.flutter.dev/testing/integration-tests).

## Device matrix

The owner has a Samsung Galaxy S23 and an iPhone 15. Start with native release/profile builds on each. Add at least one lower-capability Android device and a supported iOS floor case before making broad device claims. Emulator/simulator tests are useful for logic/UI/storage, but not substitutes for real magnetometer, optics, heating and energy tests.

Compare competitors on the same physical device/time/reference, recording edition and version. Keep compass/model/lens errors separate. A competitor screen is not an independent scientific authority. Retain manual controls and explicit uncertainty when hardware is missing or disturbed.

## Web/PWA work that directly prepares mobile

Continue source-backed object completeness and visuals; improve shared data/identity/units and source freshness; prepare a versioned API/content contract; deepen Tonight/event validation; finish current device/error journeys. The existing PWA follow/camera work remains useful within browser capabilities but is not the end target of the native research.

Keep P1/P2 features visible without forcing all of them into M-0. Telescope control, giant catalogue packs, plate solving, geospatial AR anchors, equipment profiles, widgets and notification delivery remain separately scoped. Paid or advertising-based monetization is not introduced.

## Open decisions before application scaffolding

- Access to a macOS/Xcode build-and-test environment; store-account ownership when distribution approaches.
- Exact stable SDK/toolchain and plugin versions after actual resolution/build.
- Renderer choice and fallback from experiment evidence.
- Astronomy ABI/port choice and source pin.
- Pose reference/camera metadata contract and calibration acceptance thresholds.
- Minimum supported devices/OS versions and measured resource budgets.
- Offline timezone/name scope and approved survey/image package rights.

The general personal-data storage contract remains unchanged; adding persistent offline personal inventory would require its own explicit decision. This list records preparation work and does not require the owner to answer every item before further Web/shared development proceeds.
