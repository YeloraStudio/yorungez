# Native sensor compatibility and one-time notice — K-058

Owner request: 6 November 2026. The native APK tracks correctly on the owner's S23 and several other recent phones, but reportedly remains fixed on a Galaxy A04s. The A04s is not available for physical testing. Detect the actual platform capability, explain unsupported tracking once, and keep useful touch exploration available.

## Evidence and diagnosis

[Samsung's Galaxy A04s specification](https://www.samsung.com/africa_en/smartphones/galaxy-a/galaxy-a04s-black-beauty-32gb-sm-a047fzkdafa/) lists accelerometer, fingerprint, virtual light and virtual proximity sensors. It does not list a gyroscope or geomagnetic sensor. This supports a missing-hardware explanation for the reported behaviour; it is not a measurement of the owner's particular phone or firmware.

[Android's position-sensor documentation](https://developer.android.com/develop/sensors-and-location/sensors/sensors_position) distinguishes geomagnetic and game rotation vectors. A geomagnetic rotation vector can work without a gyroscope; a game rotation vector does not provide a north reference. Therefore the app must query the available north-referenced provider, rather than blacklist a model, price bracket or every phone without a gyroscope. GPS location alone does not determine the phone's viewing direction.

The existing adapter already rejected an absent provider, but the Flutter consumer could wait indefinitely when a provider registered without producing usable samples. A generic stream failure also did not distinguish unsupported hardware from a temporary failure.

## Runtime contract

| Condition | Behaviour |
|---|---|
| Android offers rotation vector or geomagnetic rotation vector | Use the existing fused pose stream; preserve magnetic/true reference, quality and alignment gates. |
| iOS offers device motion and a true/magnetic north attitude frame | Use the existing Core Motion adapter. |
| Platform explicitly reports no compatible provider | Stop following, close camera overlay, disable unavailable tracking/camera actions and show one localized, scrollable explanation with **Got it**. |
| Capability query fails or takes over 3 seconds | Stop following with the retryable sensor-unavailable state; do not claim missing hardware. |
| No usable first sample, or an established stream stalls for 8 seconds | Release the stream, stop following and show a retryable no-data explanation. |
| Stream closes or reports a temporary error | Release it and return to touch exploration; no automatic retry loop. |
| App backgrounds or tracking stops while a probe is pending | Cancel tracking; ignore late results. A hidden screen cannot consume its notice. |

The existing **2-second pose freshness** rule remains stricter than the 8-second shutdown deadline. Stale pose cannot continue steering the sky while the watchdog waits. Malformed, stale, duplicate/out-of-order and quality-zero packets do not extend that deadline. Fresh quality-zero samples may still show the existing calibration guidance. Relative/game orientation is not promoted to north-referenced tracking.

The one-time explanation follows the app language (English default, Turkish supported). Touch exploration, object search, object focus, location-based astronomy and account features remain available. Camera overlay requires supported orientation; a camera or a permission grant cannot replace missing north-referenced hardware. No new sensor permissions or backend API changes are needed.

## Persistence and privacy

Only `sky.trackingNoticeVersion = 1`, a non-personal UI acknowledgement, is stored locally. It is written after the explanation is actually presented, not when an unseen capability result arrives. It suppresses the explanation on subsequent launches of the same installation; clearing app data/reinstalling may reset it. If optional storage fails, the running app still suppresses repeat presentations within that session.

Capability is queried afresh on a new screen/app session; the stored acknowledgement does not disable hardware. There is no persistent device model, capability inventory, coordinate, pose, calibration, personal record or telemetry event. Transient failures do not consume the hardware explanation.

## Verification and remaining acceptance

Regression coverage includes explicit unsupported capability without registering a listener, bounded probes/first-sample/stalled streams, packet validation, stream closure/error, cancellation, repeat suppression across app scopes, notice deferral while hidden, EN/TR narrow/landscape large-text presentation, manual pan/search and retry after a silent stream.

Local validation passed: **95 Flutter tests**, clean analysis/formatting, document-link/requirement coverage and all four frozen native science suites (astronomy, night planning, SGP4 and WMM2025). Android/iOS CI and publication outcomes are recorded by the [mobile workflow](https://github.com/YeloraStudio/yorungez/actions/workflows/mobile.yml) and delivery PR.

Host/emulator tests and an unsigned iOS build do not establish physical A04s, S23 or iPhone pointing accuracy. Physical testing remains open: check that an unsupported phone shows the explanation only once, touch exploration works after dismissal/restart, and a supported phone still follows real orientation after background/resume.
