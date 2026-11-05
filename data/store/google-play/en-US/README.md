# Yorungez — English Google Play showcase

Prepared 6 November 2026 from the existing owner logo and actual Flutter Android screens. This is a reviewable asset package; nothing has been submitted to Google Play. Store signing, listing fields, privacy/data-safety declarations and physical acceptance are separate work.

## Upload files

| Asset | File | Format |
| --- | --- | --- |
| Feature graphic | [feature-graphic.png](feature-graphic.png) | 1024×500, opaque RGB PNG |
| Store icon | [icon-512.png](icon-512.png) | 512×512, RGBA PNG, under 1 MiB |
| Eight phone screenshots | [screenshots/](screenshots/) | 1080×1920, opaque RGB PNG |
| Review sheet (not an upload) | [overview.jpg](overview.jpg) | All eight designs together |

Screenshots, in order: Jupiter, Moon, Orion, Andromeda, Tonight, Calendar, offline catalogue, account registration. Headlines and supporting copy are English. Images show implemented capabilities; push delivery, verified AR alignment and store availability are not advertised. Eight is our selected showcase count, not a claim that every listing requires eight.

[Google Play preview asset requirements](https://support.google.com/googleplay/android-developer/answer/9866151?hl=en) specify the icon/feature sizes and screenshot range. Recheck policy and Play Console validation at submission time.

## Authenticity and privacy

- [raw/](raw/) contains unmodified 1080×2268 emulator captures. These are provenance inputs, not the final portrait upload set.
- Captures use the production widgets and native astronomical solver, English UI, anonymous account state and the **public Istanbul example** (41.0082, 28.9784). No real account, personal location, camera stream or private notebook is captured.
- Sky illustrations use an explicitly labelled simulation at 2026-11-05 23:00 UTC (2026-11-06 02:00 Europe/Istanbul). Calendar shows December 2026 in Europe/Istanbul. Tonight uses the capture date's local night; a geometric window does not guarantee visibility.
- Screen content is proportionally resized and placed in a generic rounded frame; no app content, dates, coordinates, source credits or buttons are generatively replaced. The capture test also verifies calendar-to-sky UTC navigation and the return-to-live action.
- [art/](art/) contains AI-generated decorative backgrounds outside the app screen. They are promotional illustrations, not scientific sky data. [prompts.json](prompts.json) records the exact generation prompts; [manifest.json](manifest.json) records final dimensions, hashes and raw-capture hashes.
- The existing emblem is composited unchanged. The exact app-logo size exports and source hashes are in [branding/mobile](../../../branding/mobile/manifest.json). No competitor screenshot/art is redistributed.

## Reproduction

From the repository root, with the existing Web Sharp dependency installed:

```sh
node src/Yorungez.Mobile/tool/export_icons.mjs
node src/Yorungez.Mobile/tool/build_store_assets.mjs
```

Native icon generation, from `src/Yorungez.Mobile`:

```sh
dart run flutter_launcher_icons
```

For fresh captures, create a clean, isolated Android API 34 Google APIs emulator (1080×2268 Flutter surface). Do not use a person's signed-in emulator or physical phone. Replace the example device ID below with that isolated device only:

```sh
flutter build apk --debug --target-platform android-x64 --build-number=5004 --target=integration_test/store_capture_test.dart --no-pub
flutter drive --driver=test_driver/store_capture.dart --target=integration_test/store_capture_test.dart --device-id=emulator-5556 --use-application-binary=build/app/outputs/flutter-apk/app-debug.apk --no-pub
```

The host driver saves raw screenshots during capture actions; require the complete test to pass before exporting final artwork. Build 5004 is a capture-test application, never the owner/store APK. Build normal applications explicitly with `--target=lib/main.dart`. Regenerate final artwork after changing raw captures; the final compositor checks their dimensions and writes hashes. SVG layout uses the host's Arial font without redistributing a font file; rendering on another host may have different typography metrics.

## Licences and source credits

Original compositor/layout code follows the repository Apache-2.0 licence. Owner branding and generated decorative artwork are separate from third-party sky content. App screenshots preserve the source credit lines where displayed. The full offline source list remains accessible in the app.

- Galactic photographic sky: ESO / S. Brunier, CC BY 4.0.
- Western constellation illustrations: Johan Meuris / Stellarium, Free Art License.
- Andromeda photograph: Luc Viatour, CC BY-SA 2.5.
- Catalogue references include HYG (CC BY-SA 4.0), d3-celestial and OpenNGC; solver and other image licences remain unchanged.

See [THIRD_PARTY_NOTICES](../../../../THIRD_PARTY_NOTICES.md), [native immersive evidence](../../../../docs/mobile-immersive-discovery-evidence.md) and [planning/reminder delivery](../../../../docs/mobile-night-calendar-reminders.md) for exact source records, scientific limits and outstanding gates. These promotional surrounds do not relicense the depicted source imagery.
