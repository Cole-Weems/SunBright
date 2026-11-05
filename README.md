# SunBright

A native macOS menu bar tool that boosts everyday SDR content using your display’s HDR headroom.

This is the first, experimental iteration. It uses temporary, click-through Metal overlays; turning it off or quitting removes the effect. SunBright does not write gamma tables, change display profiles, modify system files, or change the system brightness setting.

## Included

- Menu bar controls with **Off**, **On**, and **Auto** modes.
- Estimated brightness targets in nits, from the selected SDR reference up to 1600 nits, capped by each display’s current HDR headroom.
- Manual HDR pause and configurable automatic pause while selected media apps are running.
- Global **Option–Command–B** toggle, without Accessibility or Input Monitoring permissions.
- Per-app activation based on the foreground app’s bundle identifier.
- A daily schedule, including windows that cross midnight.
- An optional power adapter requirement.
- Saved preferences, per-display status, and cleanup on sleep, session changes, display disconnection, and quit.

SunBright starts **off** on every launch. Your brightness, app rules, and schedule are saved; activation is never saved.

## Download a prebuilt app

Versioned builds can be distributed through [GitHub Releases](https://github.com/Cole-Weems/SunBright/releases). Look for a **published** release with a `SunBright-<version>.zip` asset. A draft is visible only to maintainers and is not a public download. If no published release has an app ZIP, build from source below; GitHub’s **Source code** archives are not runnable apps.

1. Download the versioned **SunBright ZIP** under Assets, extract it, and move `SunBright.app` to **Applications**. Release builds support both Intel and Apple Silicon Macs, on macOS 13 or later.
2. Open the app from Applications. It appears as a sun in the menu bar, without a Dock icon, and starts Off.
3. These free builds are **ad hoc signed, not Developer ID signed or notarized by Apple**. macOS may block the first launch. If you trust the source, use the per-app **System Settings → Privacy & Security → Open Anyway** approval when available. See [Apple’s guidance](https://support.apple.com/en-us/102445). Managed Macs may prohibit opening unnotarized apps.

You do not need Xcode or an Apple Developer Program membership to run a prebuilt build. The repository’s visibility controls release access: if it is private, downloads require access to the repository. Public distribution needs a public repository or another public download location; this workflow does not change repository visibility.

### Update a downloaded copy

Quit SunBright using the power button in its menu. Download the new versioned ZIP, extract it, replace the old copy in Applications, and reopen it. Preferences are retained, but mode starts Off. Replacing the file without quitting does not update the running process. There is no automatic in-app updater yet.

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

### 4. Update your source build for testing

If you built SunBright from this repository, first quit the running app using the power button in its menu. If you started it with `swift run`, stop that process with **Control–C** instead. Then run:

```sh
cd ~/Developer/SunBright
git status --short
git fetch origin
git switch work
git pull --ff-only origin work
bash scripts/build-app.sh
open dist/SunBright.app
```

Use your actual checkout path. If `git status` lists local edits, commit or stash them before updating; do not discard them. Stop and resolve any Git or build error before launching the app. These commands follow the `work` testing branch so they include changes that have not yet merged into `main`.

Open **Settings** and check the version banner. This iteration is **0.2** and shows nits targets and an **HDR Pause** tab. Existing preferences are preserved; the previous multiplier is converted to an estimated nits target using a default 600-nit SDR reference. No preferences reset is required. If you copied the old app to Applications, replace that copy with the new `dist/SunBright.app` too, and launch only the intended copy.

For this update, test these behaviors:

- Move the nits slider and change the SDR reference in General settings. The target is an estimate; the display’s available headroom can limit the result.
- Enable manual HDR pause while boosting. Confirm the status says paused and the boost disappears. Uncheck it to resume your selected mode and rules.
- With automatic media-app pause enabled, open QuickTime Player, TV, or VLC. Confirm boosting pauses even when the player is idle or in the background, and resumes after all enabled selected players quit. Add your browser to HDR Pause settings if you use it for HDR playback.
- Compare normal exit, Off, sleep/wake, and quitting while paused. Physical display output still needs testing on your Mac.

### Development and distribution alternatives

To run directly from source during development, use `swift run SunBright` from the repository directory and keep Terminal open; press **Control–C** to stop that process. To work in Xcode, run `open Package.swift` from the same directory.

For a build that runs on both Intel and Apple Silicon Macs, run:

```sh
bash scripts/build-app.sh --universal
bash scripts/package-app.sh
```

The packaging script creates `dist/SunBright-0.2.0.zip` and a SHA-256 checksum alongside it. It preserves executable permissions and app metadata. For optional Developer ID signing, supply `SUNBRIGHT_SIGNING_IDENTITY` when building and notarize separately. Without it, the build is ad hoc signed and unnotarized.

### Prepare a GitHub Release

The **Prepare GitHub release** workflow tests the code, builds and verifies both architectures, packages the app, and creates a **draft** GitHub Release with the ZIP and checksum. It needs no Apple signing secrets. It does not publish the draft or make the repository public.

After merging the workflow into the default branch, maintainers can select **Actions → Prepare GitHub release → Run workflow** and choose the branch to build. Alternatively, push a version tag matching `CFBundleShortVersionString` in `Resources/Info.plist`:

```sh
# After committing and pushing the source you intend to release:
git tag v0.2.0
git push origin v0.2.0
```

For later versions, first update the app version and build number in `Resources/Info.plist`, update the visible settings version and `docs/RELEASE-NOTES.md`, then commit, test, and push a new matching tag. Do not reuse a published version or tag. The workflow fails rather than overwriting an existing release.

Review the draft’s assets and notes and test the downloaded app before publishing it in GitHub’s Releases page. Free builds retain the first-launch approval requirement. Draft creation, archive checks, and successful compilation do not validate HDR output on real displays.

## Controls and automation

| Control | Behavior |
| --- | --- |
| Off | Removes all overlays and pauses automation. |
| On | Boosts supported connected displays, subject to the power adapter rule. |
| Auto | Boosts when an enabled app rule **or** the daily schedule matches. |
| Option–Command–B | Toggles manually. Select Auto again to resume automation. |
| HDR pause | Removes overlays while preserving the selected activation mode. |
| Media-app pause | Overrides On and Auto while any enabled selected player is running. |
| Quit | Removes all overlays and exits. |

In **Settings → App Rules**, add applications with the native app picker. Rules match exact bundle identifiers. Switching away from a matching app removes that trigger; a matching schedule can still keep the boost on. Opening SunBright’s own settings preserves the last foreground app.

In **Settings → Schedule**, choose a start and end time, enable the schedule, and select **Auto**. Times follow your Mac’s local clock, with an inclusive start and exclusive end. An end earlier than the start continues into the following day. Equal times create an empty window.

## Nits targets and HDR playback

The slider defaults to **600–1600 estimated nits**. In General settings, select a **500**, **600**, or **1000 nit SDR reference** appropriate to your display and current brightness setting. SunBright converts the target into a relative multiplier and caps the rendered effect to each display’s current headroom. The reference is shared across connected displays, so mixed displays can have different actual output. These numbers are estimates, not measured or guaranteed luminance.

[Apple’s MacBook Pro specifications](https://support.apple.com/en-gb/117737) distinguish **1000 nits sustained full-screen** from **1600 nits peak HDR**; 1600 is not a promise of sustained full-screen output. SDR brightness varies by model and conditions. A target equal to the SDR reference disables the overlays.

**Pause for HDR playback** in the menu or HDR Pause settings removes all overlays until you uncheck it. It preserves your mode rather than turning automation off.

**Automatically pause while selected media apps are running** is enabled by default for QuickTime Player, TV, and VLC. Add/remove players or browsers in **Settings → HDR Pause**. Pausing applies to background players too and overrides manual On and automatic activation; quitting all selected players allows the current mode and rules to resume within about a second.

This is deliberately an **app-based safeguard, not automatic HDR-content detection**. The public display headroom API reports capability and available range, not whether another app is playing HDR; SunBright’s own overlays also request EDR. No playback inspection, screen recording, or private media APIs are used. Consequently, selected apps pause the boost for SDR video and while idle too. For HDR in an unselected app, use the manual pause or add that app. See [Apple’s EDR documentation](https://developer.apple.com/documentation/appkit/nsscreen/maximumextendeddynamicrangecolorcomponentvalue).

## How the effect works

Each supported display gets a one-pixel EDR trigger and a full-screen multiply-compositing layer. The layers use floating-point Metal surfaces in extended linear sRGB. The multiplier follows the display’s current headroom, up to the requested nits target relative to the selected SDR reference. macOS retains control of the display’s output.

The implementation follows the documented [Metal EDR configuration](https://developer.apple.com/documentation/metal/performing-your-own-tone-mapping) and the publicly described [EDR plus multiply-overlay technique](https://yogeshvar.github.io/maxnits.html). It is an independent implementation with no third-party runtime dependencies. No screen capture is performed.

## Current limitations

- GitHub Actions verifies the native macOS build, the core tests, release packaging, and the local app signature on a `macos-15` runner. Physical HDR display behavior remains unverified.
- Brightness depends on available HDR headroom, system brightness, display mode, and macOS’s thermal and power management. The slider is an estimated nits target, not a measured or guaranteed luminance.
- The single trigger pixel may be visible on displays without rounded corners. Multiply compositing, protected video, screen sharing, Mission Control, full-screen Spaces, and mixed-display setups need hardware checks before release.
- The shortcut is fixed in this iteration. SunBright reports a registration conflict and keeps menu controls available.
- Login launch, configurable shortcuts, per-display selection, a notarized release, and an automatic updater are future work.

## Development and validation

```sh
swift test
bash scripts/build-app.sh  # macOS only
```

`SunBrightCore` contains the portable activation, scheduling, and preference model. `SunBright` contains the AppKit/SwiftUI interface, global hot key, power/session integration, and Metal renderer. On Linux, the package exposes only the core and its tests.

GitHub Actions tests the core on Linux and tests/builds/packages the app on macOS. For the remaining physical-display checks, see [the validation checklist](docs/VALIDATION.md).
