# Development and validation

[Project overview](../../README.md) · [All guides](README.md)

First follow [Build and run SunBright](BUILD.md) to install the tools and clone the repository.

## Development alternatives

To run directly from source during development, use `swift run SunBright` from the repository directory and keep Terminal open; press **Control–C** to stop that process. To work in Xcode, run `open Package.swift` from the same directory.

## Validation

```sh
swift test
bash scripts/build-app.sh  # macOS only
```

`SunBrightCore` contains the portable activation, scheduling, and preference model. `SunBright` contains the AppKit/SwiftUI interface, global hot key, power/session integration, and Metal renderer. On Linux, the package exposes only the core and its tests.

GitHub Actions tests the core on Linux and tests/builds/packages the app on macOS. For the remaining physical-display checks, see [the validation checklist](../VALIDATION.md).

For release packaging and distribution, see [the release guide](RELEASING.md).
