#!/usr/bin/env python3
"""Embed the public updater configuration before signing an app bundle."""
import base64
import os
from pathlib import Path
import plistlib
import sys
from urllib.parse import urlsplit


def configure(path, feed_url, public_key, required=False):
    feed_url, public_key = feed_url.strip(), public_key.strip()
    if bool(feed_url) != bool(public_key) or (required and not feed_url):
        raise ValueError("Set both SUNBRIGHT_UPDATE_FEED_URL and SUNBRIGHT_SPARKLE_PUBLIC_KEY before building a release.")
    if feed_url:
        url = urlsplit(feed_url)
        if url.scheme != "https" or not url.hostname or url.username or url.password or url.fragment:
            raise ValueError("The update feed must be an HTTPS URL without credentials or a fragment.")
        if len(base64.b64decode(public_key, validate=True)) != 32:
            raise ValueError("The Sparkle public key must be a base64-encoded 32-byte Ed25519 key.")
    path = Path(path)
    with path.open("rb") as source:
        info = plistlib.load(source)
    for key in ("SUFeedURL", "SUPublicEDKey"):
        info.pop(key, None)
    if feed_url:
        info.update(SUFeedURL=feed_url, SUPublicEDKey=public_key)
    with path.open("wb") as output:
        plistlib.dump(info, output, sort_keys=False)


if __name__ == "__main__":
    try:
        configure(
            sys.argv[1], os.environ.get("SUNBRIGHT_UPDATE_FEED_URL", ""),
            os.environ.get("SUNBRIGHT_SPARKLE_PUBLIC_KEY", ""),
            os.environ.get("SUNBRIGHT_REQUIRE_UPDATES") == "1",
        )
    except (ValueError, OSError) as error:
        sys.exit(str(error))
