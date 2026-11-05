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
mkdir -p "$app_dir/Contents/MacOS"
cp "$binary_dir/SunBright" "$app_dir/Contents/MacOS/SunBright"
cp "$repo_dir/Resources/Info.plist" "$app_dir/Contents/Info.plist"
plutil -lint "$app_dir/Contents/Info.plist"

# Local builds use an ad hoc signature. Set SUNBRIGHT_SIGNING_IDENTITY to a
# Developer ID Application identity for a distributable build; notarize separately.
codesign --force --options runtime --sign "${SUNBRIGHT_SIGNING_IDENTITY:--}" "$app_dir"
codesign --verify --strict "$app_dir"
if [[ "${1:-}" == "--apple-silicon" ]]; then
    lipo "$app_dir/Contents/MacOS/SunBright" -verify_arch arm64
fi
echo "Built $app_dir"
