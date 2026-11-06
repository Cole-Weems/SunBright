# Updating SunBright

[Project overview](../../README.md) · [All guides](README.md)

Use the instructions for how you installed SunBright. For first-time setup, see [installation](INSTALL.md) or [building from source](BUILD.md).

## Update a downloaded copy

Quit SunBright using the power button in its menu. Download the new versioned ZIP, extract it, replace the old copy in Applications, and reopen it. Preferences are retained, but mode starts Off. Replacing the file without quitting does not update the running process. There is no automatic in-app updater yet.

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
