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
- [ ] Review the draft release’s ZIP, checksum, notes, and intended audience before publishing. A private repository’s releases remain restricted.
