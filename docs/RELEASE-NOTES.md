SunBright is an experimental macOS 13+ menu bar utility for Apple Silicon Macs.

- Estimated brightness targets in nits, with a selectable SDR reference.
- Manual HDR pause and configurable automatic pause while selected media apps run.
- App rules, daily schedules, and a global Option–Command–B toggle.
- Optional Launch at Login in General settings, with macOS registration status, approval guidance, and error recovery. Login launch starts in the menu bar with brightness boost Off; saved rules and targets are retained.
- Check for Updates in General settings. Update-enabled builds show release notes, verify signed downloads, and install and relaunch with your preferences retained and brightness boost Off. Checks and installations are user initiated.

Download the **SunBright versioned ZIP** under Assets, extract it, and move SunBright.app to Applications. This download supports Apple Silicon (M-series) Macs only; it does not run on Intel Macs. Do not download GitHub's automatically generated Source code archive unless you intend to compile it.

This build is ad hoc signed and **not notarized by Apple**. macOS may block the first launch. Only open a build from a source you trust, using macOS's per-app approval in System Settings → Privacy & Security → Open Anyway when available. No Apple developer membership is needed for this build; installation is less seamless than a Developer ID signed, notarized release.

Brightness values are estimates, not measurements. Actual output depends on your display and macOS headroom. Automatic media-app pause is not HDR-content detection; it also pauses for idle selected apps and SDR playback. QuickTime Player, TV, and VLC are selected by default. Add browsers or other players in HDR Pause settings as needed.

To update an update-enabled build, use Settings → General → Check for Updates. Older builds without that button need one manual update: quit SunBright, replace the old app with the newly downloaded app, and reopen it. Preferences are retained and activation starts Off. Physical HDR display behavior still requires testing on supported hardware.
