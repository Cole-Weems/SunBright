#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "SunBright.app must be built on macOS 13 or later with Xcode 15 or later." >&2
    exit 1
fi

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_dir"

build_args=(--configuration release)
case "${1:-}" in
    "") ;;
    --apple-silicon) build_args+=(--arch arm64) ;;
    *) echo "Usage: bash scripts/build-app.sh [--apple-silicon]" >&2; exit 1 ;;
esac
if [[ $# -gt 1 ]]; then
    echo "Usage: bash scripts/build-app.sh [--apple-silicon]" >&2
    exit 1
fi

swift build "${build_args[@]}" --product SunBright
binary_dir="$(swift build "${build_args[@]}" --show-bin-path)"
app_dir="$repo_dir/dist/SunBright.app"
mkdir -p "$app_dir/Contents/MacOS" "$app_dir/Contents/Frameworks" "$app_dir/Contents/Resources"
cp "$binary_dir/SunBright" "$app_dir/Contents/MacOS/SunBright"
cp "$repo_dir/Resources/Info.plist" "$app_dir/Contents/Info.plist"
python3 scripts/configure-updates.py "$app_dir/Contents/Info.plist"
plutil -lint "$app_dir/Contents/Info.plist"

sparkle_artifacts="$repo_dir/.build/artifacts/sparkle/Sparkle"
framework="$app_dir/Contents/Frameworks/Sparkle.framework"
# ditto preserves Sparkle's versioned framework symlinks and helper permissions.
rm -rf "$framework"
ditto "$sparkle_artifacts/Sparkle.xcframework/macos-arm64_x86_64/Sparkle.framework" "$framework"
cp "$sparkle_artifacts/LICENSE" "$app_dir/Contents/Resources/Sparkle-LICENSE.txt"

# Local builds use an ad hoc signature. Set SUNBRIGHT_SIGNING_IDENTITY to a
# Developer ID Application identity for a distributable build; notarize separately.
signing_identity="${SUNBRIGHT_SIGNING_IDENTITY:--}"
signing_options=()
# Ad hoc builds cannot use library validation with a third-party framework.
# Developer ID builds retain the hardened runtime and sign all nested code.
if [[ "$signing_identity" != "-" ]]; then signing_options+=(--options runtime); fi
for component in \
    "$framework/Versions/B/XPCServices/Installer.xpc" \
    "$framework/Versions/B/XPCServices/Downloader.xpc" \
    "$framework/Versions/B/Autoupdate" \
    "$framework/Versions/B/Updater.app" \
    "$framework" \
    "$app_dir"; do
    codesign --force "${signing_options[@]}" --preserve-metadata=entitlements --sign "$signing_identity" "$component"
done
codesign --verify --deep --strict "$app_dir"
if [[ "${1:-}" == "--apple-silicon" ]]; then
    lipo "$app_dir/Contents/MacOS/SunBright" -verify_arch arm64
fi
echo "Built $app_dir"
