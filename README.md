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

Run these steps on your Mac. Building from source requires a local copy of the repository; the commands below include cloning it.

### 1. Install the developer tools

Install [Xcode](https://developer.apple.com/xcode/) version 15 or later, choosing a version compatible with your macOS version. Open Xcode once, accept its license, and let it finish installing its required components.

Open **Terminal** and check that the tools are available:

```sh
xcode-select -p
swift --version
git --version
```

Swift must report version 5.9 or later. If the tools are missing or Terminal is using a different Xcode installation, select the installed Xcode and repeat the checks:

```sh
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

Adjust that path if you installed Xcode elsewhere. No Homebrew packages or third-party Swift dependencies are required.

### 2. Clone the repository

The first iteration is on the **`work` branch**, so clone that branch explicitly:

```sh
mkdir -p ~/Developer
cd ~/Developer
git clone --branch work https://github.com/Cole-Weems/SunBright.git
cd SunBright
```

If the repository is private, your GitHub account must have access. Authenticate Git with that account before cloning. If you already use the GitHub CLI, you can run `gh auth login` and `gh auth setup-git` first. A GitHub account password cannot be used as the password for an HTTPS Git clone; use your configured Git credential manager or a personal access token instead.

If you already cloned SunBright, use your existing checkout instead of cloning again. Commit or stash any local edits before switching branches:

```sh
cd ~/Developer/SunBright
git fetch origin
git switch work
git pull --ff-only origin work
```

Use your checkout’s actual path if it is outside `~/Developer`.

### 3. Build and launch

From inside the `SunBright` repository directory, run:

```sh
bash scripts/build-app.sh
open dist/SunBright.app
```

Wait for the build script to print `Built …/dist/SunBright.app` before opening the app. The script builds for your Mac’s architecture, creates `dist/SunBright.app`, and applies a local ad hoc signature.

SunBright runs in the **menu bar**, without a Dock icon. Click the sun icon, select **On**, and adjust the brightness slider. Use **Off**, **Option–Command–B**, or the power button in the menu to disable the boost or quit. SunBright starts Off each time it launches.

For later launches, open `SunBright.app` in the checkout’s `dist` folder using Finder, or repeat the `open` command from the repository directory. You can close Terminal after launching the app bundle. Rebuild after pulling source updates; quit a running copy before rebuilding and reopening it.

If you see “No such file or directory” for the script, check that Terminal is inside the cloned repository. If `open` cannot find the app, resolve the build error first. If the app reports no HDR-capable display or unavailable HDR headroom, see the compatibility limitations below.

### Development and distribution alternatives

To run directly from source during development, use `swift run SunBright` from the repository directory and keep Terminal open; press **Control–C** to stop that process. To work in Xcode, run `open Package.swift` from the same directory.

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

- GitHub Actions verifies the native macOS build, all 28 core tests, release packaging, and the local app signature on a `macos-15` runner. Physical HDR display behavior remains unverified.
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
