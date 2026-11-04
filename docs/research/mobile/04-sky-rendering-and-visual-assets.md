# 04 — Sky rendering and visual-asset catalogue

**K-050 update:** The owner explicitly excluded mobile terrain. The [sky-first plan](../../mobile-sky-first-plan.md) supersedes ground/photographic-horizon candidates in this research snapshot. A real-data Canvas reference scene is now implemented; physical/profile renderer selection and registered survey/art/planet visuals remain open.

**Status:** candidate comparison; renderer selection requires a device experiment. **Traceability:** FR-02/03/05/09, A-005/009.

## Required behaviour

The renderer must support a real catalogue, continuous phone pose, touch exploration, object picking, readable labels, wide-angle sky projection, photographic horizon, atmosphere/day-night transitions, grids and constellation layers. Camera mode uses the actual optical projection; wide-angle virtual exploration can use a different projection. Scientific directions, illustrative ground, archival object images and simulated visual effects must remain distinguishable.

Do not implement a planetarium as thousands of independently rebuilding Flutter widgets. A catalogue entry is scientific data, not a widget. Batch visible geometry, cache invariant data and keep the camera transform separate from catalogue loading.

## Candidate approaches

| Approach | Why evaluate it | Main uncertainty | Recommendation |
|---|---|---|---|
| `CustomPainter` / Canvas, batched sprites/vertices and fragment shaders | Small dependency footprint; control of stereographic/perspective projection, labels and hit testing | Dense catalogue, wide-view atmosphere and fill-rate cost | Build the reference implementation first |
| Flutter GPU with a dedicated sky layer | Lower-level buffers/pipelines and direct control of draw batching | Version/backend requirements, development burden and device fallbacks | Compare after baseline data/pose contract exists |
| `flutter_scene` | Higher-level GPU scene/asset pipeline; current package supports Android/iOS | Astronomy-specific projection, point rendering and unwanted general-engine complexity | Shortlisted experiment, not automatically selected |
| `thermion_flutter` / Filament | Native rendering option and material/texture infrastructure | Binary/toolchain size, custom material compatibility and astronomical point/label integration | Alternative experiment if the first two miss budgets |
| Owned native Metal/Vulkan/OpenGL layer exposed as a Flutter texture | Maximum integration control | Highest dual-platform maintenance, lifetime/synchronization and test cost | Fallback only after measured need |
| Embedded Web renderer | Reuse potential | Keeps the browser rendering/integration boundary the owner wants to move beyond | Reference/fallback research only; not the proposed primary mobile sky |

Flutter's shader documentation describes compiled fragment effects; it does not provide an entire 3D astronomy engine. Impeller is the underlying renderer on current supported iOS and selected Android configurations; renderer availability still varies. [Fragment shaders](https://docs.flutter.dev/ui/design/graphics/fragment-shaders), [Impeller](https://docs.flutter.dev/perf/impeller).

Flutter GPU is a low-level rendering API, distinct from a scene engine. Scene's current documentation requires Flutter 3.47+ and explicit Flutter GPU configuration. An older introductory article's platform status should not be substituted for current package requirements. [Flutter GPU API](https://api.flutter.dev/flutter/flutter_gpu/), [Scene](https://pub.dev/packages/flutter_scene).

Thermion uses Filament and documents matching native material/compiler versions. Its platform and architecture support must match our actual build targets. [Thermion](https://pub.dev/packages/thermion_flutter). Neither package's feature list establishes sky accuracy, sensor latency or S23/iPhone performance.

## Proposed rendering pipeline

1. Read versioned catalogue positions and metadata off the UI path.
2. Compute/refresh celestial directions under one documented model context.
3. Cull by view and magnitude, selecting a bounded density appropriate to zoom.
4. Apply current device/view rotation at display rate; batch stars, grid/constellation geometry and labels.
5. Composite atmosphere/ground or the optional camera background according to mode.
6. Resolve picking against the same projected frame, with stable object IDs and a sensible touch radius.

Use double precision for scientific state and CPU transforms where needed; convert local render buffers to the supported GPU representation intentionally. Large coordinates and low-precision uniforms must not silently define scientific accuracy. Timestamp a render frame so cards and picking do not refer to another observer/time context.

## Visual-data tiers

| Asset | Proposed treatment |
|---|---|
| Bright stars | Existing source-backed catalogue first; validate colour/magnitude mapping and completeness |
| Fainter stars | Optional spatial/magnitude chunks; do not allocate a billion-entry array |
| Milky Way / deep-sky survey | Astrometrically registered survey/HiPS candidate with per-survey rights |
| Ground panorama | Existing licensed photograph; resolution tiers and bounded decode/GPU memory |
| Planet surfaces | Licensed textures with geometry/phase appropriate to scope; archive imagery stays labelled |
| Constellation lines/art | Existing independent data/art licences, culture and identity metadata |

HiPS uses hierarchical HEALPix tiles to load detail progressively. It is a data organisation standard, not a survey licence. Baseline interoperability can target the stable 1.0 Recommendation while tracking newer work separately. [IVOA HiPS 1.0](https://www.ivoa.net/documents/HiPS/20170519/REC-HIPS-1.0-20170519.pdf).

An 8192×4096 RGBA8 texture alone occupies 128 MiB before mipmaps and other copies; the 4096×2048 equivalent is 32 MiB. These are arithmetic estimates, not measured app memory. Optional high-resolution downloads, GPU limits, mip levels, decode buffers and background/resume behaviour must be budgeted. Increasing resolution does not improve catalogue coordinates.

## Renderer decision experiment

Use identical source data, camera path and reference projections across candidates. Test: horizon and zenith, dense Milky Way view, extreme zoom, labels/card over camera, day/night atmosphere, landscape transparency, rotation and resume. Record startup-to-first-sky time, frame-time distribution, sensor-to-present latency, peak memory, texture failures and 15–30 minute thermal behaviour. Use release/profile builds; debug frame rate is not acceptance evidence.

Start with the current catalogue, then controlled larger real-data subsets with recorded provenance. Synthetic stress datasets may test capacity, but must be labelled and must not enter the public sky. Adopt the simplest renderer that meets the agreed visual and device budgets. [Flutter performance guidance](https://docs.flutter.dev/perf/best-practices).
