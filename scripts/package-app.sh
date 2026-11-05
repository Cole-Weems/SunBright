#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "App packaging requires macOS." >&2
    exit 1
fi

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_dir"
app_dir="$repo_dir/dist/SunBright.app"
version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app_dir/Contents/Info.plist")"
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "App version must have the form major.minor.patch." >&2
    exit 1
fi
codesign --verify --strict "$app_dir"
if [[ "$(lipo "$app_dir/Contents/MacOS/SunBright" -archs)" != "arm64" ]]; then
    echo "Release packages require an Apple Silicon build; run build-app.sh --apple-silicon." >&2
    exit 1
fi
archive="$repo_dir/dist/SunBright-$version-apple-silicon.zip"
# Preserve the executable bit, app bundle, and macOS metadata inside the ZIP.
ditto -c -k --sequesterRsrc --keepParent "$app_dir" "$archive"
verification_dir="$(mktemp -d "${TMPDIR:-/tmp}/sunbright-package.XXXXXX")"
trap 'rm -rf "$verification_dir"' EXIT
ditto -x -k "$archive" "$verification_dir"
test -x "$verification_dir/SunBright.app/Contents/MacOS/SunBright"
codesign --verify --strict "$verification_dir/SunBright.app"
(cd "$repo_dir/dist" && shasum -a 256 "SunBright-$version-apple-silicon.zip" > "SunBright-$version-apple-silicon.zip.sha256")
echo "Packaged $archive"
