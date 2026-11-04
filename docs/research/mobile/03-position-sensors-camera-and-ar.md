# 03 — Position, sensors, camera and AR catalogue

**Status:** primary-source findings and proposed native contract; no native device results. **Traceability:** FR-01/02/05, UJ-06, K-047/048.

## Candidate components

| Component | Candidate | Evidence and adoption gap |
|---|---|---|
| Foreground location | `geolocator` | Wraps Android/iOS location services; test fix age, precision, accuracy and elevation semantics. Reverse geocoding is separate. |
| Raw sensor diagnostics | `sensors_plus` | Exposes raw/processed individual sensor streams; it does not document a complete north-referenced camera-attitude API. |
| Simple compass helper | `flutter_compass` | Heading API; insufficient as the sole pose source. Snapshot release is from November 2024, requiring maintenance/API review. |
| Main pointing source | Owned Kotlin/Swift adapter | Prefer OS-fused attitude, reference/accuracy metadata and timestamps over a new raw-IMU fusion implementation. |
| Camera preview | Official `camera` plugin | Good preview candidate; validate access to the lens/crop/timing metadata needed by astronomy overlays. |
| Native messages | Pigeon; FFI for suitable native buffers/math | Typed control APIs; choose streaming transport after measuring overhead. |

Primary package evidence: [geolocator](https://pub.dev/packages/geolocator), [sensors_plus](https://pub.dev/packages/sensors_plus), [flutter_compass](https://pub.dev/packages/flutter_compass), [camera](https://pub.dev/packages/camera), [Pigeon](https://docs.flutter.dev/interop/pigeon). Versions/licence metadata are in [the snapshot](package-snapshot.json).

## Android and iOS pose sources

Android provides rotation-vector sensors and device/world transformations. The game rotation vector deliberately omits magnetic north and can drift; it must not be labelled true-north orientation. Sensor availability differs by device. [Android position sensors](https://developer.android.com/develop/sensors-and-location/sensors/sensors_position), [motion sensors](https://developer.android.com/develop/sensors-and-location/sensors/sensors_motion).

iOS Core Motion provides fused device motion and selectable arbitrary, magnetic-north and true-north frames. Query frame availability and choose explicitly. Core Location separately exposes magnetic/true headings and heading accuracy; valid true heading depends on location updates. [Processed Core Motion](https://developer.apple.com/documentation/coremotion/getting-processed-device-motion-data), [reference frames](https://developer.apple.com/documentation/coremotion/cmattitudereferenceframe), [CLHeading](https://developer.apple.com/documentation/corelocation/clheading).

**Proposed normalized sample:** quaternion/matrix, documented device-to-ENU transform, monotonic sample time, wall-clock correlation, orientation source, north reference (`true`, `magnetic`, `relative`, `unknown`), reported accuracy if available, display rotation, capability status and tracking quality. Use one canonical handedness and quaternion component order. Do not infer orientation accuracy from GPS accuracy.

Use matrices/quaternions through the high-rate path; derive azimuth/altitude for display. Tests must cover rear optical axis, screen-up, portrait/landscape, handedness, poles, quaternion sign equivalence and 359°→0° transitions. Filters need time-aware interpolation and bounded latency; smoothing cannot remove a wrong reference frame.

## True north and alignment

WMM2025 is a candidate for converting explicitly magnetic orientation to a geographic reference; WMMHR2025 is a separate higher-resolution option. Both require model/date/input validation. NOAA provides code, coefficients and test data; the model is not a correction for a nearby magnet. The documented WMM2025 expiry is 31 December 2029. [NOAA WMM](https://www.ncei.noaa.gov/products/world-magnetic-model), [WMMHR](https://www.ncei.noaa.gov/products/world-magnetic-model-high-resolution).

Recommended hierarchy: valid OS true-north attitude → explicitly magnetic attitude plus validated declination model → relative attitude plus a real reference. Do not apply declination twice. Unknown source/reference remains visibly uncertain. Keep manual known-target alignment available, invalidate it when its reference changes, and distinguish yaw-only alignment from full pose/lens calibration. A saved universal offset is not justified across locations, lenses and sensor resets.

## Location quality

Request precise foreground location only when useful; support denied/approximate permission and manual coordinates. Track source, timestamp and horizontal/vertical accuracy separately. A place label or Google Maps-style geocoder does not improve the sensor's coordinate accuracy. Earth elevation needs a documented datum; barometric pressure alone is not absolute elevation. Avoid continuous GPS updates unless the active experience needs them, and stop on pause.

The offline product must say whether a location is a current device fix, manual selection or an earlier explicitly retained public example. Current personal-location persistence rules are not changed by this catalogue.

## Camera projection and local processing

The official camera plugin requires application-managed lifecycle handling. Its setup examples include microphone usage for audio-capable features; Yorungez's preview should use audio disabled and should not request audio merely by copying a generic example. Verify merged Android permissions and actual iOS prompts. [Camera lifecycle and permissions](https://pub.dev/packages/camera).

Android Camera2 exposes lens intrinsics/distortion metadata with device-dependent availability. iOS exposes a format's horizontal `videoFieldOfView`, which can be unknown. A field-of-view scalar alone does not settle crop, digital zoom, image stabilization, orientation or camera switching. [Android camera characteristics](https://developer.android.com/reference/android/hardware/camera2/CameraCharacteristics), [iOS field of view](https://developer.apple.com/documentation/avfoundation/avcapturedevice/format/videofieldofview).

Recommended pipeline: identify physical rear lens/format → determine image orientation and preview crop → obtain usable intrinsics or calibrated FOV → map the sky direction to that optical frame → project into the visible viewport. Re-evaluate on zoom, format/lens switch and resize. Measure centre and edge residuals against several independent sky references. If metadata is missing, retain an approximate/manual mode with its uncertainty visible.

Preview is local, optional and independent of basic sky exploration. No default video recording, upload, audio capture or raw pose logging. Stop camera/sensors on background, interruption, revoked permission and disposal; late permission results must not restart an abandoned session.

## ARCore / ARKit assessment

Basic sky pointing is orientation plus astronomy and does not inherently require SLAM, plane detection, cloud anchors or geospatial localization. ARCore tracks visual features; an untextured/dark sky is not a reason to assume robust world tracking. Device certification and capability checks apply. [ARCore fundamentals](https://developers.google.com/ar/develop/fundamentals), [supported devices](https://developers.google.com/ar/devices).

Apple geotracking depends on supported geographic areas and internet-delivered localization imagery. It does not meet the global/offline baseline by itself. [ARGeoTrackingConfiguration](https://developer.apple.com/documentation/arkit/argeotrackingconfiguration).

AR frameworks remain optional experiments for useful local context, not the compulsory sky engine. Image-based star identification/plate solving is a separate future research topic with camera exposure, extraction, index and validation requirements. No such recognition capability is claimed for Yorungez or inferred from competitor marketing.

**Acceptance required:** S23 and iPhone 15 pose correctness, calibration residuals, lens/crop agreement, temporal lag, drift, portrait/landscape, pause/resume and permission recovery. See [experiment catalogue](10-experiments-acceptance-and-delivery.md).
