# SunBright

A native macOS menu bar tool that boosts everyday SDR content using your display’s HDR headroom.

This is the first, experimental iteration. It uses temporary, click-through Metal overlays; turning it off or quitting removes the effect. SunBright does not write gamma tables, change display profiles, modify system files, or change the system brightness setting.

## Included

- Menu bar controls with **Off**, **On**, and **Auto** modes.
- A 100–200% brightness multiplier, capped by each display’s current HDR headroom.
- Global **Option–Command–B** toggle, without Accessibility or Input Monitoring permissions.
- Per-app activation based on the foreground app’s bundle identifier.
- A daily schedule, including windows that cross midnight.
- An optional power adapter requirement.
- Saved preferences, per-display status, and cleanup on sleep, session changes, display disconnection, and quit.

SunBright starts **off** on every launch. Your brightness, app rules, and schedule are saved; activation is never saved.

## Build and run

Requires **macOS 13 or later**, **Xcode 15 or later** (Swift 5.9+), and an HDR/EDR-capable display for the brightness effect. Liquid Retina XDR and Pro Display XDR are intended hardware targets; actual hardware compatibility still needs validation. Standard SDR displays remain unchanged.

```sh
bash scripts/build-app.sh
open dist/SunBright.app
```

The script builds for your Mac’s architecture, creates `dist/SunBright.app`, and applies a local ad hoc signature. Click the sun in the menu bar to begin. You can also open `Package.swift` in Xcode or use `swift run SunBright` during development.

For distribution, supply `SUNBRIGHT_SIGNING_IDENTITY` with your Developer ID Application identity when building, and notarize the resulting app separately. The local build is not a notarized release.

## Controls and automation

| Control | Behavior |
| --- | --- |
| Off | Removes all overlays and pauses automation. |
| On | Boosts supported connected displays, subject to the power adapter rule. |
| Auto | Boosts when an enabled app rule **or** the daily schedule matches. |
| Option–Command–B | Toggles manually. Select Auto again to resume automation. |
| Quit | Removes all overlays and exits. |

In **Settings → App Rules**, add applications with the native app picker. Rules match exact bundle identifiers. Switching away from a matching app removes that trigger; a matching schedule can still keep the boost on. Opening SunBright’s own settings preserves the last foreground app.

In **Settings → Schedule**, choose a start and end time, enable the schedule, and select **Auto**. Times follow your Mac’s local clock, with an inclusive start and exclusive end. An end earlier than the start continues into the following day. Equal times create an empty window.

## How the effect works

Each supported display gets a one-pixel EDR trigger and a full-screen multiply-compositing layer. The layers use floating-point Metal surfaces in extended linear sRGB. The multiplier follows the display’s current headroom, up to the selected value and a 2× cap. macOS retains control of the display’s output.

The implementation follows the documented [Metal EDR configuration](https://developer.apple.com/documentation/metal/performing-your-own-tone-mapping) and the publicly described [EDR plus multiply-overlay technique](https://yogeshvar.github.io/maxnits.html). It is an independent implementation with no third-party runtime dependencies. No screen capture is performed.

## Current limitations

- The app has not yet been built or exercised on macOS hardware. Core tests and Swift syntax checks have been run on Linux; the macOS CI job is supplied for native compilation and packaging.
- Brightness depends on available HDR headroom, system brightness, display mode, and macOS’s thermal and power management. The slider is a requested multiplier, not a guaranteed luminance or nit value.
- The single trigger pixel may be visible on displays without rounded corners. Multiply compositing, protected video, screen sharing, Mission Control, full-screen Spaces, and mixed-display setups need hardware checks before release.
- The shortcut is fixed in this iteration. SunBright reports a registration conflict and keeps menu controls available.
- Login launch, configurable shortcuts, per-display selection, and a signed/notarized release are future work.

## Development and validation

```sh
swift test
bash scripts/build-app.sh  # macOS only
```

`SunBrightCore` contains the portable activation, scheduling, and preference model. `SunBright` contains the AppKit/SwiftUI interface, global hot key, power/session integration, and Metal renderer. On Linux, the package exposes only the core and its tests.

GitHub Actions tests the core on Linux and tests/builds/packages the app on macOS. For the remaining physical-display checks, see [the validation checklist](docs/VALIDATION.md).
