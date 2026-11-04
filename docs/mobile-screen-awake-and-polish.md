# Mobile screen-awake and visual polish — K-052

Owner feedback, **5 November 2026**: the S23 test app entered automatic screen sleep after roughly 15 seconds without touch; stacked actions lacked space; onboarding brand marks needed soft corners; centre dwell should be one second. This correction supersedes the K-051 timing while preserving the immersive discovery scope.

## Implementation

- A narrow original Flutter/platform channel applies Android `FLAG_KEEP_SCREEN_ON` and iOS `UIApplication.isIdleTimerDisabled` while the sky/onboarding screen is active. A screen-based override is separate from audio playback or a background CPU wake lock. No new package, permission or persistent preference is added.
- Flutter serializes activation/release and releases on inactive/background/dispose. Android separately checks Activity resume/pause; iOS separately observes active/inactive notifications. A delayed request must not keep a background app's display awake. Manual device locking remains under the user's control.
- The default monotonic reticle dwell is **1,000 ms**, with existing identity, hysteresis, interruption/context/reference/pause reset and one-shot behaviour. EN/TR help text and the current contract reflect the new duration.
- Vertical action groups now have **12 logical pixels** between primary/secondary buttons: foreground/manual location, onboarding, manual-coordinate application/example, calibration and previous-step actions. Secondary sidebar navigation has 8-pixel gaps. Existing spaced icon controls and single-button screens were inspected.
- All onboarding steps use a 16-pixel rounded clip around the 76-pixel brand mark. Existing sidebar/catalogue rounded marks and original logo masters remain intact.
- Test build advances to **0.1.0+2**, retaining the same application ID and local test-signing identity for installation over the previous S23 package.

## Verification

The 39-test Flutter suite passed, including one-second boundary/interruption tests, delayed activation/disposal and foreground lifecycle checks, plus existing EN/TR narrow/landscape/large-text layouts. Android x86_64 debug and S23 ARM64 profile builds passed; final Flutter analysis has no issues. On the running Android emulator, the target Activity had `KEEP_SCREEN_ON` set and the display remained awake after the no-touch interval. The profile APK signature and increasing ABI-specific version code (2001 → 2002) were verified against the previous S23 test package, so it can be installed as an update. After final mock-handler cleanup, all eight focused wake/dwell/onboarding tests passed again. iOS changes are prepared in the existing native adapter but require macOS/Xcode and physical validation; they are not labelled built here. The S23's actual no-touch/return-from-background behaviour must be confirmed with the updated APK.

Astronomy, source data, coordinates/time, public ISS lifetime, account ownership and the remaining native feature-parity plan are unchanged. No new scientific test claim, production API release, commit/push/deployment or store publication follows from this UI/lifecycle patch.

## Primary platform references

- [Android: keep the screen on](https://developer.android.com/develop/background-work/background-tasks/awake/screen-on): Activity-scoped flag, clearing the flag and normal background behaviour.
- [Apple: isIdleTimerDisabled](https://developer.apple.com/documentation/uikit/uiapplication/isidletimerdisabled): foreground display with little touch input and resetting the idle-timer override when no longer needed. The official Markdown representation was read when the HTML view required JavaScript.
