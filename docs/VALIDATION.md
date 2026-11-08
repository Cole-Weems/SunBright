# First-iteration validation

## Verified in the Linux workspace

- Swift 6.0.3 compiles the portable `SunBrightCore` module and its XCTest suite.
- The tests cover activation priorities, manual overrides, exact app matching, app/schedule OR semantics, battery gating, suspension, schedule boundaries, overnight windows, preference round trips, and invalid preference data.
- Swift’s frontend parses all macOS sources successfully. This is a syntax check, not a macOS SDK type check.
- The app bundle’s property list parses, the packaging script passes `bash -n`, and Git whitespace checks pass.

## Verified in macOS CI

On November 5, 2026, the [macOS CI run for commit `61443c9`](https://github.com/Cole-Weems/SunBright/actions/runs/42104636730) passed on the supported `macos-15` runner:

```sh
swift test
bash scripts/build-app.sh
codesign --verify --strict dist/SunBright.app
```

- All 28 core tests passed, and the macOS application sources compiled.
- The release app bundle built successfully; its property list and ad hoc signature verified.
- The workflow uploaded the `SunBright-macOS` app artifact.

The original macOS jobs were canceled before starting because `macos-14` was retired on November 2, 2026. The workflow now uses `macos-15`, and the overlay panel calls the designated `NSPanel` initializer required by the macOS SDK.

These checks establish native build and packaging compatibility. The physical-display checks below remain unperformed.

## Physical-display checklist

Run on a Mac with an HDR-capable display and, if available, an SDR external display. Record the macOS version, display model, display mode, and architecture with the results.

- [ ] In the packaged app, compare the Settings header, menu popover, General tab, brightness controls, and menu-bar icon with the Finder app icon. Check light and dark appearances and verify the active dot and tooltip still reflect boost state. Rebuild with changed source artwork and confirm these surfaces follow it after relaunch.

- [ ] Launch the app bundle. Only the menu bar sun appears; mode starts Off and brightness stays unchanged.
- [ ] Select On with an estimated target above the SDR reference. Confirm SDR content becomes brighter, colors and blacks remain correct, pointer behavior is normal, and the estimated display readouts reflect the available headroom.
- [ ] Move between the SDR reference and the 1600-nit target. At the reference value, no overlays remain. A display with limited headroom must not exceed its current limit.
- [ ] Select Off and quit separately. Compare against the starting appearance and verify the system brightness slider and selected display profile are unchanged.
- [ ] Force quit while boosted. Confirm the windows disappear and the original appearance returns without launching SunBright again.
- [ ] Trigger Option–Command–B from another app. Repeat while Auto is active and while waiting. Manual mode must toggle Off even if paused by the battery rule.
- [ ] Occupy the shortcut in a second app before launching SunBright. Confirm the conflict message and working menu controls.
- [ ] Add Safari and another app. Confirm exact foreground matching, disabling/removing rules, duplicate handling, and turning off when switching away outside the schedule.
- [ ] Open SunBright settings during an app rule. Confirm the last external app remains the rule’s foreground reference.
- [ ] Test a short daytime schedule and an overnight schedule. Confirm inclusive start, exclusive end, local-time behavior, and no activation for equal start/end times.
- [ ] Enable the power adapter rule, unplug, and reconnect. Confirm overlays are removed on battery and restored only if the selected mode still requests them.
- [ ] Sleep/wake the displays and Mac, switch users, and disconnect/reconnect an HDR display while boosted. Confirm cleanup, correct window positions, and no stranded overlays.
- [ ] Move between desktops and full-screen apps. Check Mission Control, screenshots, screen sharing, HDR video, and protected playback for white rectangles or other compositing artifacts.
- [ ] Test SDR-only, mixed HDR/SDR, mirrored, and scaled displays. SDR and secondary mirrored outputs must not receive an extra overlay.
- [ ] Relaunch after changing preferences. Confirm preferences persist and mode is Off.

If compositing produces a solid white surface, visible artifacts, or an unexpected image, turn SunBright Off or quit. Treat that display/macOS combination as unsupported until its rendering behavior is fixed; a successful core test run does not validate the display effect.

## Nits, pause, and distribution update

The portable suite now includes ten additional tests for nits conversion/clamping, legacy preference migration, reference and media-rule normalization, HDR pause precedence, background player handling, and resuming the selected mode. The initial macOS CI evidence above applies to the first iteration; the updated native and Apple Silicon packaging checks run on the current branch.

- [ ] Confirm estimated nits, changed SDR references, and the absence of claims of measured output.
- [ ] Verify manual pause removes overlays and restores the selected mode when cleared.
- [ ] Verify selected media apps pause both On and Auto, including idle and background apps; quitting all selected apps resumes only the current rules.
- [ ] Verify disabled/removed media rules, browsers added as media apps, and the default QuickTime/TV/VLC rules.
- [ ] Download the packaged ZIP on an Apple Silicon Mac; confirm the executable contains only the arm64 architecture. Verify extraction retains executable permissions and the app launches after the user’s per-app approval if allowed by macOS policy.
- [ ] Quit and replace an older app with the updated build; confirm the version and preserved preferences.
- [ ] Complete hardware checks and review release notes before pushing a version tag; matching tags now publish automatically. Check the published ZIP, checksum, and generated change notes, and confirm a retry updates the same tag’s downloads. A private repository’s releases remain restricted.

## In-app updates

The Settings update control uses Sparkle 2.10.1. macOS unit tests use a fake updater to check manual-only requests, availability during an update, disabled/unbundled configuration, startup failures, and turning boost Off without changing saved preferences before installation. Python tests validate build-time feed and public-key configuration. The macOS CI job generates a real signed feed with an ephemeral test key and rejects an archive after its bytes are changed. These checks do not replace an installation test between two released app versions.

Before the first update-enabled release, complete the [publishing setup](guides/RELEASING.md#one-time-updater-setup), then test two builds with the same bundle identifier, feed URL, and public key and increasing build numbers:

- [ ] Install the older build in Applications. Open Settings → General and press Check for Updates; confirm the newer version and its release notes appear. Confirm launching the app alone causes no update check or update-permission prompt.
- [ ] Cancel the dialog and a download. Confirm the app remains usable and preferences and boost mode are unchanged.
- [ ] Accept an update while boosting. Confirm the overlays disappear before installation, the app relaunches once, the displayed version changes, and brightness starts Off with saved rules, schedule, targets, and login registration retained.
- [ ] Check again at the newest version and confirm the up-to-date message. Test offline and unavailable-feed errors and retry after restoring connectivity.
- [ ] Confirm the download and appcast are accessible without GitHub authentication. Check that only compiled artifacts and reviewed notes are in the public download repository.
- [ ] Test macOS authorization for replacing the app in Applications, a read-only installation location, and first-launch approval with the actual signing method. Record Mac model, macOS version, installation path, and signing method.

## Launch at Login

`SunBrightTests` runs on macOS with an injected service; it never changes the runner’s login items. It covers default registration, enable/disable, repeated and concurrent requests, approval cancellation, errors/retry, unbundled execution, missing-item recovery, external changes, and startup remaining Off with saved rules and each login status. Native compilation and these tests require the macOS CI job; Linux runs only the portable core suite.

The following integration checks remain unperformed. Record the macOS version, Mac model, installation path, signing method (ad hoc or Developer ID), and results. Test macOS 13 and a current supported version where available. Use an app bundle in Applications rather than `swift run`.

- [ ] With a fresh user/profile, launch SunBright. Confirm Launch at Login is off, only the menu bar sun appears, and brightness stays unchanged. Launching the app does not add it to Login Items.
- [ ] Enable Launch at Login. Compare the displayed status with System Settings → General → Login Items (or Login Items & Extensions). If approval is required, the toggle stays off, the status says approval required, and Open Login Items Settings leads to the relevant pane. Approve it and confirm the toggle updates without relaunching.
- [ ] Cancel a pending request and confirm the registration is removed. Test registration/unregistration errors where reproducible; the actual status must remain visible alongside actionable recovery text and allow retry.
- [ ] Quit and reopen. Confirm registration persists and no new registration request or approval is issued just by starting the app.
- [ ] Sign out and back in with the item enabled. Confirm exactly one SunBright process, no settings/popover window, no focus change, and mode Off with no overlays. Repeat after quitting in On and Auto modes with matching saved app/schedule rules; retain all preferences without restoring activation.
- [ ] Turn Launch at Login off, quit, and sign out/in. Confirm SunBright does not start. Repeat after disabling it externally through System Settings; the running app must reflect the change and must not undo it on refresh or restart.
- [ ] With SunBright already running, open its app bundle again, then run its `Contents/MacOS/SunBright` executable directly. Confirm only one menu bar item/process remains and existing mode/rules are unaffected.
- [ ] Disable login launch, quit, move the app, open the new copy, and enable it. After sign-in, verify only the new copy runs. Quit and replace that copy with an updated build at the same path; check status and sign-in again. Check for stale old paths in Login Items, especially with ad hoc signatures.
- [ ] Run with `swift run SunBright`. Confirm the control explains that an installed app bundle is required and does not attempt registration.
- [ ] Enable boost after a login launch; verify Off, normal quit, sleep/wake, and HDR/media pauses still remove and restore overlays according to the existing rules.

## Issue 9: brightness during full-screen swipes

The reporter confirmed that PR #10 did not eliminate the dim interval during
three-finger swipes. It retained the existing window levels: both surfaces below
the screen-saver level, with the HDR trigger below the multiply window.

The follow-up moves the multiply window to `CGShieldingWindowLevel()` and the
trigger one level above it, restores `fullScreenAuxiliary` alongside
`canJoinAllApplications`, and reasserts ordering on existing surfaces when Spaces
change. Current headroom caps and the activation/pause rules still apply.
`OverlayPanelTests` checks actual panel levels, full-screen eligibility, and
nonactivating/click-through behavior using plain layers without showing the
windows or requiring Metal. These tests do not prove that WindowServer keeps
EDR active throughout a swipe. Keep issue 9 open until the physical checks pass.

Run `swift test` and `bash scripts/build-app.sh --apple-silicon` on macOS before
performing these checks. Record Mac model, macOS version, display model,
connection, display mode, and whether Stage Manager is enabled.

- [ ] Choose On, a target above the SDR reference, and disable media-app pause (or use apps outside its list). Open two apps in separate full-screen Spaces. Confirm brightness remains boosted throughout repeated three-finger swipes in both directions.
- [ ] Swipe slowly, hold between Spaces, and cancel the swipe. Confirm the effect covers the display throughout, with no dim interval, white flash, or exposed overlay edges.
- [ ] Repeat between a desktop and a full-screen app and through Mission Control, with Stage Manager both off and on where applicable.
- [ ] Repeat with Control–Left/Right Arrow and swipes past the first/last Space that return to the same Space. Compare against the prior build under identical conditions.
- [ ] While boosted, change resolution/scaling and rearrange or disconnect/reconnect an external display. Confirm surfaces fit the current display frames and disconnected displays leave no windows behind.
- [ ] Repeat in Auto with both foreground apps matching. Then use a nonmatching app outside the schedule and confirm boosting stops as intended. A rule-driven disable is expected, unlike the interruption in On mode.
- [ ] Confirm Off, HDR pause, sleep, and quit still remove the effect, including immediately after a canceled swipe. Restore any media-app pause preferences changed for this check.
