# Updating SunBright

[Project overview](../../README.md) · [All guides](README.md)

Use the instructions for how you installed SunBright. For first-time setup, see [installation](INSTALL.md) or [building from source](BUILD.md).

## Update a downloaded copy

Open **Settings → General → Updates → Check for Updates…**. SunBright shows the available release and its notes, or tells you that you are up to date. Choose to download and install the update in the update window. Installation briefly quits and relaunches SunBright; the boost turns Off before installation, and your saved brightness, app rules, schedule, and other preferences are retained. macOS may request permission to replace an app in Applications.

Checks happen only when you press the button. There are no scheduled checks, silent downloads, or silent installations. You can cancel an update and keep using your current version. Download and verification failures leave the installed app in place and are reported in the update window.

In-app updating requires an installed app built with the project's update feed and public signing key. Unconfigured builds and `swift run` show why updating is unavailable. The release maintainer must complete the [one-time update publishing setup](RELEASING.md#one-time-updater-setup) before shipping an update-enabled app.

### First update-enabled version and manual updates

Older versions, including the original 0.2.0 release, do not contain the updater. Install the first update-enabled version manually once. You can also use this process whenever in-app updating is unavailable:

Quit SunBright using the power button in its menu. Download the new versioned ZIP from the maintainer's GitHub Releases, extract it, replace the old copy in Applications, and reopen it. Preferences are retained, but mode starts Off. Replacing the file without quitting does not update the running process.

## Update a source build for testing

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
