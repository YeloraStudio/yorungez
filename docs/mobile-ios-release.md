# iOS release with Fastlane — K-064

**7 November 2026.** The owner requested configuring the existing mobile application for an iOS release using Fastlane. This extends K-053/K-054 to native release preparation and delivery. Existing scientific, privacy and physical-device acceptance requirements remain. Scope: FR-01/02/03/08/09/10/11, UJ-01 and the existing mobile account/sky contracts; no new requirement IDs.

## Delivery state

The existing Runner project is retained, with display name **Yorungez**, bundle identifier `com.yelorastudio.yorungez`, iOS 15 minimum, EN/TR permission explanations and the original supplied icons. No replacement app was generated. On 7 November the owner authorized reuse of their existing app's App Store Connect API key and specifically required the renewed distribution certificate. Team ownership was verified through Apple; the owner created [the Yorungez App Store Connect record](https://appstoreconnect.apple.com/apps/6831956323/testflight/ios).

An App Store provisioning profile was created for this exact bundle and the renewed distribution certificate expiring **5 November 2027**. The local private configuration points to the existing `.p8` file outside this repository. Fastlane passes the selected certificate's SHA-1 identity selector to Xcode and obtains its SHA-256 fingerprint from the same Keychain. The IPA verifier checks the actual signer and provisioning profile against the SHA-256 fingerprint and verifies the bundle and version before upload. Signing settings use Runner-specific variables so Swift package resource targets are not assigned an application provisioning profile.

Fastlane **2.241.2**, Ruby **4.0.9** and the resolved Gemfile lock are checked in. The owner's existing Flutter 3.47.9 / Dart 3.13.7 workspace and lockfile are now matched by `.flutter-version` and mobile CI (revision `c197ca5199e9ee5661e865596c9c07294dfab51c`). The SDK installed on the machine was not upgraded. Host science check scripts omit GCC-only static-runtime flags on macOS so Apple's Clang can compile the same pinned native sources; reference inputs and tolerances are unchanged.

| Lane | Behavior |
|---|---|
| `ios verify` | Enforce Flutter pin and dependency lock, stage hash-verified public assets, generate localizations, analyze, restore the locked JS comparator, run offline science checks and all Flutter tests, build unsigned release. No Apple account access. |
| `ios archive` | Same preparation and checks, explicit marketing/build numbers, archive and export using an installed Apple Distribution identity and App Store provisioning profile. Output is under ignored `build/ios/distribution/`. |
| `ios beta` | Archive, then authenticate with a team App Store Connect API key and upload that exact IPA. Does not invite external testers or submit App Review. Processing and selecting internal testers remain in App Store Connect. |
| `ios submit` | Select the explicit already-uploaded version/build for App Review. Existing reviewed store metadata/screenshots are retained. Release remains manual after Apple approval. |

`verify` and `archive` run the host scientific and Flutter suites; they do not establish physical acceptance. The `submit` lane is prepared but must not be run while the store blockers below remain unresolved.

## Local setup

Use the pinned Ruby through a version manager or an already matching installation. On this Mac the matching Ruby is at `/opt/homebrew/opt/ruby/bin`; system Ruby 2.6 cannot run this bundle. Dependencies are installed under the repository's ignored `.local/ios-gems`, not system Ruby.

From `src/Yorungez.Mobile`:

```sh
export PATH="/opt/homebrew/opt/ruby/bin:$PATH" # this Mac; adapt to your Ruby installation
export BUNDLE_PATH="$PWD/../../.local/ios-gems"
export FASTLANE_SKIP_UPDATE_CHECK=1
export FASTLANE_OPT_OUT_USAGE=1
bundle install
bundle exec fastlane lanes
bundle exec fastlane ios verify
```

Fastlane accepts `FLUTTER_BIN` to select the pinned SDK without changing the global installation. `DEVELOPER_DIR` can select the Xcode installation. Apple currently requires the iOS 26 SDK or later for uploads; the inspected local Xcode is 27.2. Check Apple's requirements again at upload time.

To rerun the science/application checks separately (also executed by the lanes):

```sh
npm ci --prefix ../../tools/science-js --ignore-scripts --no-audit --no-fund
python3 tool/check_science.py
python3 tool/check_satellite.py
python3 tool/check_magnetic.py
flutter test --no-pub
```

Copy `fastlane/.env.example` to ignored `fastlane/.env`, then fill local values:

| Variable | Required value |
|---|---|
| `IOS_TEAM_ID` | The owning Apple Developer team, not the App Store issuer ID. |
| `IOS_PROFILE_NAME` | Name of the installed App Store distribution provisioning profile for this team and exact bundle ID. Its certificate/private key must be available in the local keychain. |
| `IOS_SIGNING_CERT_SHA1` | Exact uppercase 40-character Xcode identity selector for the selected renewed distribution certificate. An unavailable private key or a missing or ambiguous corresponding SHA-256 fingerprint stops the lane. |
| `IOS_VERSION` | Explicit `major.minor.patch` store version; example file starts at `0.1.0`. |
| `IOS_BUILD_NUMBER` | Positive, previously unused build number for this upload. Example `4` is a candidate, not a reservation in Apple. |
| `ASC_KEY_ID`, `ASC_ISSUER_ID` | Team App Store Connect API-key identifiers. |
| `ASC_KEY_PATH` | Absolute path to its private `.p8` file outside Git. Never paste key contents into source or chat. |

For a new machine, install the associated App Store profile and selected distribution certificate/private key using the owner's Apple account. Existing certificates are not revoked or replaced. The profile and certificate must belong to the confirmed Yorungez team. The renewed identity on this Mac is named `iPhone Distribution`; matching uses its fingerprint rather than the generic `Apple Distribution` name, which would select the older certificate. API keys authenticate uploads; they do not replace distribution signing credentials.

```sh
bundle exec fastlane ios archive # signed IPA only
bundle exec fastlane ios beta    # fresh archive + TestFlight upload
# After processing, physical acceptance and store readiness:
bundle exec fastlane ios submit  # uses IOS_VERSION and IOS_BUILD_NUMBER exactly
```

Every upload needs a new build number. Archive settings override version/signing for that build without rewriting the checked-in Xcode signing settings or `pubspec.yaml`. Keep the IPA/archive/dSYM together for diagnostics. Do not mistake an unsigned `Runner.app` for a distributable IPA. A Swift or asset-packaging change requires a full rebuild, not hot reload.

## Required work before public App Store submission

1. **Account deletion:** PR #37 added the bilingual, password-confirmed deletion flow with session revocation and server-owned record cleanup. Verify the account settings link and end-to-end deletion against the shared backend from the new iOS build.
2. **Privacy and support:** validate the K-057 public privacy pages and the support destination for store use; complete Apple's privacy answers from actual account/notebook/network behavior and dependencies. Audit required-reason APIs and the final archive's privacy manifests. Do not claim “no data collected” because sensor processing is local: the account backend holds personal data.
3. **Store record:** confirmed developer/team, bundle record, app name/SKU, free price, territories, category, updated age-rating questionnaire, content rights, export-compliance answers and agreements. These are not inferred from source code. Encryption compliance must be assessed before setting `ITSAppUsesNonExemptEncryption`; no guessed declaration was added.
4. **EN/TR metadata and real screenshots:** use actual iPhone/iPad application captures at Apple's required sizes, appropriate descriptions of calculated versus illustrative imagery, working links and source/licence attributions. Current Runner supports iPad; either test that declared support or make a deliberate supported-device decision before upload.
5. **Physical iPhone:** foreground location permission/denial, real compass and calibration/stale samples, camera permission/preview, audio interruption/mute, background/resume, secure refresh/sign-out, account language and server inventory, offline imagery and portrait/landscape. Simulator fallback is not physical pointing evidence.
6. **App Review access:** if needed, arrange a dedicated verified review account and accurate reviewer notes through private configuration/App Store Connect. Do not commit credentials. Confirm the shared API is running the account/preferences contracts used by this binary.

The first practical delivery target is an internal TestFlight build; team, signing profile and app credentials are now configured locally. Public publication is not complete until the store work, Apple review and release finish. Existing Web/API deployment workflows remain separate; no signing secrets have been added to GitHub and no automatic store upload was attached to a push.

## Verification record

- Fastlane dependency installation and lane discovery succeeded locally with Ruby 4.0.9 / Fastlane 2.241.2.
- An intentional check against the previous Flutter 3.41.6 pin rejected the mismatched 3.47.9 SDK before any build/upload; the pin and CI were then aligned with the current workspace.
- `bundle exec fastlane ios verify` passed end to end: locked dependency resolution, asset staging, localization generation, analysis, science/application tests and an unsigned Release `Runner.app` with Xcode 27.2. All 106 assets in that release bundle matched their manifest hashes.
- Full Flutter suite: **67 tests passed** on the aligned toolchain. Native reference checks passed: **1,166 solar + 144 stellar + 72 deep-sky** comparisons, **1,166 JS parity** samples, **63 SGP4** comparisons and **12 WMM2025** comparisons. Both documented polar exclusions remain. Upstream Clang warnings remain in pinned vendor code; vendor bytes were not edited. Android build and physical iPhone checks were not rerun in this release-preparation session.
- Missing signing-team input is rejected before archive/upload. Documentation links and `git diff --check` passed.
- Before the upload retry, six upstream commits through `6d044ac` were integrated. The combined lockfile passed enforced resolution with Flutter 3.47.9. All **97 Flutter tests**, host scientific/planning checks and Dart formatting passed on that source. The capability protocol was retained and unsupported errors were delivered through the event stream.
- **7 November upload:** `bundle exec fastlane ios beta` completed successfully for **0.1.0 (4)** after integrating upstream `6d044ac`. Signed archive/export and exported-IPA verification passed using the owner-selected renewed distribution certificate. Apple's upload service accepted the package for app **6831956323**. The first API check had not yet listed the build; processing, tester availability, App Review and public release are separate from successful upload. No external invitations or App Review submission were made.

## Official references

- [Fastlane build_app and signing/export options](https://docs.fastlane.tools/actions/build_app/)
- [Fastlane TestFlight upload](https://docs.fastlane.tools/actions/upload_to_testflight/)
- [Fastlane App Store submission](https://docs.fastlane.tools/actions/upload_to_app_store/)
- [Fastlane App Store Connect API authentication](https://docs.fastlane.tools/app-store-connect-api/)
- [Apple SDK upload requirements](https://developer.apple.com/news/?id=ueeok6yw)
- [Apple in-app account deletion requirement](https://developer.apple.com/help/app-review/guideline-reference/5-1-1-account-deletion)
