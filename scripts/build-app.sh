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

icon_source="$repo_dir/Resources/AppIcon.png"
if [[ ! -s "$icon_source" ]]; then
    echo "Missing app icon source: Resources/AppIcon.png" >&2
    exit 1
fi
if ! icon_properties="$(sips -g format -g pixelWidth -g pixelHeight "$icon_source")"; then
    echo "Resources/AppIcon.png must be a valid square PNG at least 1024 pixels wide." >&2
    exit 1
fi
icon_format="$(awk '/^[[:space:]]+format:/ { print $2 }' <<< "$icon_properties")"
icon_width="$(awk '/^[[:space:]]+pixelWidth:/ { print $2 }' <<< "$icon_properties")"
icon_height="$(awk '/^[[:space:]]+pixelHeight:/ { print $2 }' <<< "$icon_properties")"
if [[ "$icon_format" != "png" || ! "$icon_width" =~ ^[0-9]+$ || "$icon_width" != "$icon_height" ]] || (( icon_width < 1024 )); then
    echo "Resources/AppIcon.png must be a square PNG at least 1024 pixels wide." >&2
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

# Generate every standard macOS icon representation before signing the bundle.
icon_work_dir="$(mktemp -d "${TMPDIR:-/tmp}/sunbright-icon.XXXXXX")"
trap 'rm -rf "$icon_work_dir"' EXIT
iconset="$icon_work_dir/AppIcon.iconset"
mkdir "$iconset"
for icon_size in 16 32 128 256 512; do
    sips -z "$icon_size" "$icon_size" "$icon_source" \
        --out "$iconset/icon_${icon_size}x${icon_size}.png" >/dev/null
    retina_size=$((icon_size * 2))
    sips -z "$retina_size" "$retina_size" "$icon_source" \
        --out "$iconset/icon_${icon_size}x${icon_size}@2x.png" >/dev/null
done
iconutil -c icns "$iconset" -o "$app_dir/Contents/Resources/AppIcon.icns"

sparkle_artifacts="$repo_dir/.build/artifacts/sparkle/Sparkle"
framework="$app_dir/Contents/Frameworks/Sparkle.framework"
# ditto preserves Sparkle's versioned framework symlinks and helper permissions.
rm -rf "$framework"
ditto "$sparkle_artifacts/Sparkle.xcframework/macos-arm64_x86_64/Sparkle.framework" "$framework"
cp "$sparkle_artifacts/LICENSE" "$app_dir/Contents/Resources/Sparkle-LICENSE.txt"

# Local builds use an ad hoc signature. Set SUNBRIGHT_SIGNING_IDENTITY to a
# Developer ID Application identity for a distributable build; notarize separately.
signing_identity="${SUNBRIGHT_SIGNING_IDENTITY:--}"
signing_options=(--force --preserve-metadata=entitlements --sign "$signing_identity")
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
    codesign "${signing_options[@]}" "$component"
done
codesign --verify --deep --strict "$app_dir"
if [[ "${1:-}" == "--apple-silicon" ]]; then
    lipo "$app_dir/Contents/MacOS/SunBright" -verify_arch arm64
fi
echo "Built $app_dir"
