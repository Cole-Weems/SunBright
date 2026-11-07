# Build and run SunBright

[Project overview](../../README.md) · [All guides](README.md)

Requires **macOS 13 or later**, **Xcode 15 or later** (Swift 5.9+), and an HDR/EDR-capable display for the brightness effect. Liquid Retina XDR and Pro Display XDR are intended hardware targets; actual hardware compatibility still needs validation. Standard SDR displays remain unchanged.

Run these steps on your Mac. Building from source requires a local copy of the repository; the commands below include cloning it.

## 1. Install the developer tools

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

Adjust that path if you installed Xcode elsewhere. No Homebrew packages are required. macOS builds resolve the pinned Sparkle updater package automatically through Swift Package Manager; the portable Linux core has no third-party dependencies. The app packaging scripts also use Python 3 (`python3 --version`).

## 2. Clone the repository

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

## 3. Build and launch

From inside the `SunBright` repository directory, run:

```sh
bash scripts/build-app.sh
open dist/SunBright.app
```

Wait for the build script to print `Built …/dist/SunBright.app` before opening the app. The script builds for your Mac’s architecture, creates `dist/SunBright.app`, and applies a local ad hoc signature.

SunBright runs in the **menu bar**, without a Dock icon. Click the sun icon, select **On**, and adjust the brightness slider. Use **Off**, **Option–Command–B**, or the power button in the menu to disable the boost or quit. SunBright starts Off each time it launches.

For later launches, open `SunBright.app` in the checkout’s `dist` folder using Finder, or repeat the `open` command from the repository directory. You can close Terminal after launching the app bundle. For later source updates, follow [Updating SunBright](UPDATING.md#update-a-source-build-for-testing).

If you see “No such file or directory” for the script, check that Terminal is inside the cloned repository. If `open` cannot find the app, resolve the build error first. If the app reports no HDR-capable display or unavailable HDR headroom, see the [current limitations](LIMITATIONS.md).


For development commands and checks, see [development and validation](DEVELOPMENT.md).
