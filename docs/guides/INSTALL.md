# Install SunBright

[Project overview](../../README.md) · [All guides](README.md)

Versioned builds can be distributed through [GitHub Releases](https://github.com/Cole-Weems/SunBright/releases). Look for a **published** release with a `SunBright-<version>-apple-silicon.zip` asset. A draft is visible only to maintainers and is not a public download. If no published release has an app ZIP, follow the [source build guide](BUILD.md); GitHub’s **Source code** archives are not runnable apps.

1. Download the versioned **SunBright ZIP** under Assets, extract it, and move `SunBright.app` to **Applications**. Release builds require an Apple Silicon Mac (M-series) running macOS 13 or later; these downloads do not support Intel Macs.
2. Open the app from Applications. It appears as a sun in the menu bar, without a Dock icon, and starts Off.
3. These free builds are **ad hoc signed, not Developer ID signed or notarized by Apple**. macOS may block the first launch. If you trust the source, use the per-app **System Settings → Privacy & Security → Open Anyway** approval when available. See [Apple’s guidance](https://support.apple.com/en-us/102445). Managed Macs may prohibit opening unnotarized apps.

You do not need Xcode or an Apple Developer Program membership to run a prebuilt build. The repository’s visibility controls release access: if it is private, downloads require access to the repository. Public distribution needs a public repository or another public download location; this workflow does not change repository visibility.

For later versions, see [Updating SunBright](UPDATING.md).
