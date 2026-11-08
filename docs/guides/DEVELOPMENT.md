# Development and validation

[Project overview](../../README.md) · [All guides](README.md)

First follow [Build and run SunBright](BUILD.md) to install the tools and clone the repository.

## Development alternatives

To run directly from source during development, use `swift run SunBright` from the repository directory and keep Terminal open; press **Control–C** to stop that process. To work in Xcode, run `open Package.swift` from the same directory.

## App icon

The source artwork is [Resources/AppIcon.png](../../Resources/AppIcon.png), a square PNG at least 1024 pixels wide. The artwork was generated with AI for SunBright. The macOS build script uses the system `sips` and `iconutil` tools to downsample the master into the standard icon sizes and embed `AppIcon.icns` in the app before signing. `CFBundleIconFile` points to that resource. Update the source PNG and rebuild the app bundle to change its icon; no generated iconset or ICNS file needs to be committed. Packaging checks the icon declaration and decodes the icon from the extracted ZIP.

In-app artwork uses the shared `AppIcon` provider, which reads `NSApplication.applicationIconImage` rather than a separate image asset or system sun symbol. Settings, the popover, tab, brightness controls, and menu bar therefore follow the bundled icon on subsequent launches. The menu bar renders a small active indicator without changing the source icon. `AppIconTests` checks that changing the current application icon changes the shared artwork and that rendering the status icon preserves the source. Bare `swift run` executions use the host's application icon; use the built app bundle to preview SunBright's artwork.

## Validation

```sh
swift test
python3 -m unittest discover -s Tests/ReleaseToolsTests
bash scripts/build-app.sh  # macOS only
```

`SunBrightCore` contains the portable activation, scheduling, and preference model. `SunBright` contains the AppKit/SwiftUI interface, global hot key, power/session integration, and Metal renderer. On Linux, the package exposes only the core and its tests.

GitHub Actions tests the core on Linux and tests/builds/packages the app on macOS. For the remaining physical-display checks, see [the validation checklist](../VALIDATION.md).

On macOS, updater tests use an injected service and do not contact GitHub or install an update. CI also builds a temporary app with an ephemeral Ed25519 key, generates and verifies a real Sparkle update feed, and checks that a tampered archive fails verification. The temporary key and app are deleted and are never uploaded. Ordinary CI app artifacts have in-app updating disabled; production release signing uses separate repository secrets.

For release packaging and distribution, see [the release guide](RELEASING.md).
