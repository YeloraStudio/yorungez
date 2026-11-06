# Mobile launcher and native launch artwork — K-056

Owner feedback: 6 November 2026. The app itself is working well; restore the earlier cosmic launcher artwork and correct the icon shown during native startup. This supersedes K-055's flat Android adaptive/monochrome launcher choice. Keep the existing logo masters, in-app branding and store showcase unchanged.

## Change

The K-055 Android 8+ adaptive resource took precedence over the existing photographic cosmic launcher PNGs. Its foreground was the flat vector emblem on a solid grey tile. Android 12 startup also referenced that launcher, so both surfaces showed the unwanted flat treatment.

- Retain the existing cosmic source `data/branding/source/app-icon-fullbleed.png` and its native density exports. Replace the flat adaptive foreground with the full cosmic artwork in the adaptive background, with transparent foreground. The central viewport preserves the original image; mirrored outer pixels fill Android's 25% layer overscan. Android applies its launcher mask without the legacy-icon white frame or an extra zoom into the logo. The flat foreground/monochrome density assets are removed; themed monochrome treatment is no longer supplied by the app.
- Use a separate source-derived circle-masked cosmic image for native startup. Android 12+ has transparent padding around the central 192/288 safe circle; earlier Android launch backgrounds centre a 168dp image. The existing dark window background stays consistent through the first Flutter frame.
- Fill the existing iOS launch-image catalogue at 168/336/504 pixels, with a 168-point storyboard resource. Existing iOS app-icon catalogue pixels are unchanged.
- `tool/export_icons.mjs` reproduces the native launch assets from the owner master and records their hashes. `flutter_launcher_icons.yaml` deliberately omits the flat adaptive overrides. The standalone flat export files remain historical brand derivatives, not active Android launcher resources.
- Owner test build is **0.1.0+5**, ARM64 profile, Android versionCode **2005**, signed with the same development certificate so it can update the previous owner APK.

The [Android splash-screen specification](https://developer.android.com/develop/ui/views/launch/splash-screen/) describes the transparent 288dp canvas / central 192dp circle used here. This is a native resource change; it adds no startup delay or new runtime permission.

The adaptive overscan follows [AdaptiveIconDrawable's layer bounds](https://developer.android.com/reference/android/graphics/drawable/AdaptiveIconDrawable). It is decorative owner artwork; it is separate from the app's scientifically registered sky imagery.

## Verification

Android x64 debug and ARM64 profile builds passed. The isolated Android API 34 emulator displayed the restored launcher artwork and the separate cosmic native splash during a recorded cold launch, then opened the normal onboarding screen. The original signed-in emulator was not modified.

The adaptive background's central 512px viewport was compared pixel-for-pixel with the resized original artwork; it matches. iOS launch PNGs were verified at 168/336/504px with alpha. Existing iOS app-icon pixels, source masters and in-app code are unchanged. APK versionCode 2005 and APK Signature Scheme v2 were verified; its signer matches the previous owner build. Owner APK SHA-256: `339bc914e328693825cd3f46ae8985b28816899ee069238561e59e11cae2d822`.

Current Android/macOS build and publication results are recorded by the [mobile verification workflow](https://github.com/YeloraStudio/yorungez/actions/workflows/mobile.yml) and linked delivery PR. Store signing and physical iOS appearance remain separate from an unsigned build. This resource-only correction does not modify astronomy or account behaviour.
