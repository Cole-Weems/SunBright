#!/usr/bin/env bash
set -euo pipefail

if [[ $# != 4 ]]; then
    echo "Usage: bash scripts/create-update-feed.sh <app-bundle> <zip> <output-directory> <download-url-prefix>" >&2
    exit 1
fi
repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
app_dir="$1"
archive="$2"
feed_dir="$3"
download_prefix="$4"
sparkle_bin="$repo_dir/.build/artifacts/sparkle/Sparkle/bin"
: "${SUNBRIGHT_SPARKLE_PRIVATE_KEY:?Set the Sparkle private key as a CI secret.}"
public_key=$(/usr/libexec/PlistBuddy -c 'Print :SUPublicEDKey' "$app_dir/Contents/Info.plist")
codesign --verify --deep --strict "$app_dir"
mkdir -p "$feed_dir"
archive_name="$(basename -- "$archive")"
cp "$archive" "$feed_dir/$archive_name"
cp "$repo_dir/docs/RELEASE-NOTES.md" "$feed_dir/${archive_name%.zip}.md"

# The private key goes only to stdin, never command arguments, artifacts, or logs.
printf '%s' "$SUNBRIGHT_SPARKLE_PRIVATE_KEY" | "$sparkle_bin/generate_appcast" \
    --ed-key-file - --maximum-deltas 0 --embed-release-notes \
    --download-url-prefix "$download_prefix/" "$feed_dir"

signature=$(python3 - "$feed_dir/appcast.xml" "$archive" "$download_prefix" "$app_dir/Contents/Info.plist" <<'PY'
from pathlib import Path
import plistlib
import sys
import xml.etree.ElementTree as ET

feed, archive, prefix, plist = sys.argv[1:]
with open(plist, 'rb') as source:
    info = plistlib.load(source)
ns = {'s': 'http://www.andymatuschak.org/xml-namespaces/sparkle'}
items = ET.parse(feed).findall('./channel/item')
item = next(i for i in items if i.findtext('s:version', namespaces=ns) == info['CFBundleVersion'])
enclosure = item.find('enclosure')
assert enclosure is not None, 'Missing update enclosure'
assert enclosure.get('url') == prefix + '/' + Path(archive).name, 'Incorrect update URL'
assert int(enclosure.get('length')) == Path(archive).stat().st_size, 'Incorrect update length'
assert item.findtext('s:shortVersionString', namespaces=ns) == info['CFBundleShortVersionString'], 'Incorrect update version'
assert item.findtext('s:minimumSystemVersion', namespaces=ns) == info['LSMinimumSystemVersion'], 'Incorrect minimum macOS version'
signature = enclosure.get('{' + ns['s'] + '}edSignature')
assert signature, 'Update was not signed; check the Sparkle key pair'
print(signature)
PY
)
swift "$repo_dir/scripts/verify-update-signature.swift" "$archive" "$public_key" "$signature"
printf '%s' "$SUNBRIGHT_SPARKLE_PRIVATE_KEY" | "$sparkle_bin/sign_update" --verify --ed-key-file - "$feed_dir/appcast.xml"
echo "Verified signed update feed: $feed_dir/appcast.xml"
