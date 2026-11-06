# Current limitations

[Project overview](../../README.md) · [All guides](README.md)

- GitHub Actions verifies the native macOS build, the core tests, release packaging, and the local app signature on a `macos-15` runner. Physical HDR display behavior remains unverified.
- Brightness depends on available HDR headroom, system brightness, display mode, and macOS’s thermal and power management. The slider is an estimated nits target, not a measured or guaranteed luminance.
- The single trigger pixel may be visible on displays without rounded corners. Multiply compositing, protected video, screen sharing, Mission Control, full-screen Spaces, and mixed-display setups need hardware checks before release.
- The shortcut is fixed in this iteration. SunBright reports a registration conflict and keeps menu controls available.
- Login launch, configurable shortcuts, per-display selection, a notarized release, and an automatic updater are future work.
