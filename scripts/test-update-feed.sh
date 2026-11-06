#!/usr/bin/env bash
set -euo pipefail
repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_dir"
test_dir="$(mktemp -d "${TMPDIR:-/tmp}/sunbright-updates.XXXXXX")"
trap 'rm -rf "$test_dir"' EXIT

# Ephemeral test-only keys. Neither the key nor the test app is uploaded by CI.
swift - "$test_dir" <<'SWIFT'
import CryptoKit
import Foundation
let directory = URL(fileURLWithPath: CommandLine.arguments[1])
let key = Curve25519.Signing.PrivateKey()
try key.rawRepresentation.base64EncodedString().write(to: directory.appendingPathComponent("private-key"), atomically: true, encoding: .utf8)
try key.publicKey.rawRepresentation.base64EncodedString().write(to: directory.appendingPathComponent("public-key"), atomically: true, encoding: .utf8)
SWIFT
ditto dist/SunBright.app "$test_dir/SunBright.app"
export SUNBRIGHT_UPDATE_FEED_URL="https://example.com/appcast.xml"
SUNBRIGHT_SPARKLE_PUBLIC_KEY="$(cat "$test_dir/public-key")"
export SUNBRIGHT_SPARKLE_PUBLIC_KEY
python3 scripts/configure-updates.py "$test_dir/SunBright.app/Contents/Info.plist"
codesign --force --sign - "$test_dir/SunBright.app"
ditto -c -k --sequesterRsrc --keepParent "$test_dir/SunBright.app" "$test_dir/SunBright-test.zip"
SUNBRIGHT_SPARKLE_PRIVATE_KEY="$(cat "$test_dir/private-key")"
export SUNBRIGHT_SPARKLE_PRIVATE_KEY
bash scripts/create-update-feed.sh "$test_dir/SunBright.app" "$test_dir/SunBright-test.zip" "$test_dir/feed" "https://example.com/downloads"

signature=$(python3 - "$test_dir/feed/appcast.xml" <<'PY'
import sys
import xml.etree.ElementTree as ET
enclosure = ET.parse(sys.argv[1]).find('./channel/item/enclosure')
print(enclosure.get('{http://www.andymatuschak.org/xml-namespaces/sparkle}edSignature'))
PY
)
printf 'tampered' >> "$test_dir/SunBright-test.zip"
if swift scripts/verify-update-signature.swift "$test_dir/SunBright-test.zip" "$SUNBRIGHT_SPARKLE_PUBLIC_KEY" "$signature"; then
    echo "A tampered update was incorrectly accepted." >&2
    exit 1
fi
echo "Signed feed generation and rejection of a tampered update passed."
