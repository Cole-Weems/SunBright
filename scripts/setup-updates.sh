#!/usr/bin/env bash
set -euo pipefail

case "${1:-}" in
    "") publish=false ;;
    --publish) publish=true ;;
    --help|-h)
        echo "Usage: bash scripts/setup-updates.sh [--publish]"
        echo "Run on your Mac with Xcode and an authenticated GitHub CLI."
        echo "Configures SunBright signing keys; --publish also starts the release from main."
        exit 0 ;;
    *) echo "Usage: bash scripts/setup-updates.sh [--publish]" >&2; exit 1 ;;
esac
if [[ $# -gt 1 || "$(uname -s)" != "Darwin" ]]; then
    echo "Run this script on your Mac with Xcode and the GitHub CLI installed." >&2
    exit 1
fi
for tool in gh swift python3; do command -v "$tool" >/dev/null; done
if ! gh auth status >/dev/null 2>&1; then
    echo "Run gh auth login using an account that can manage Cole-Weems/SunBright, then run this script again." >&2
    exit 1
fi
repository="Cole-Weems/SunBright"
repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_dir"
if [[ "$(gh repo view "$repository" --json visibility --jq .visibility)" != "PUBLIC" ]]; then
    echo "The repository must be public to host these update downloads." >&2
    exit 1
fi

remote_public_key=$(gh variable list --repo "$repository" --json name,value \
    --jq '.[] | select(.name == "SUNBRIGHT_SPARKLE_PUBLIC_KEY") | .value')
has_private_key=$(gh secret list --repo "$repository" --json name \
    --jq 'any(.[]; .name == "SUNBRIGHT_SPARKLE_PRIVATE_KEY")')
if [[ "$has_private_key" == "true" ]]; then
    if [[ -z "$remote_public_key" ]]; then
        echo "A private signing key already exists, but its public key is missing. Restore the matching public key; this script will not replace an existing signing secret." >&2
        exit 1
    fi
    echo "Existing signing configuration retained."
else
    swift package resolve
    sparkle_bin="$repo_dir/.build/artifacts/sparkle/Sparkle/bin"
    if [[ -z "$remote_public_key" ]]; then
        # Sparkle reuses an existing Keychain key rather than rotating it.
        "$sparkle_bin/generate_keys" --account SunBright >/dev/null
    fi
    local_public_key=$("$sparkle_bin/generate_keys" --account SunBright -p)
    if [[ -n "$remote_public_key" && "$remote_public_key" != "$local_public_key" ]]; then
        echo "The Keychain key does not match the configured public key. Restore the correct Keychain key before continuing." >&2
        exit 1
    fi
    key_directory="$(mktemp -d "${TMPDIR:-/tmp}/sunbright-signing.XXXXXX")"
    trap 'rm -rf "$key_directory"' EXIT
    "$sparkle_bin/generate_keys" --account SunBright -x "$key_directory/private-key" >/dev/null
    chmod 600 "$key_directory/private-key"
    # Supply the key through stdin, never as a command argument or log message.
    gh secret set SUNBRIGHT_SPARKLE_PRIVATE_KEY --repo "$repository" < "$key_directory/private-key"
    gh variable set SUNBRIGHT_SPARKLE_PUBLIC_KEY --repo "$repository" --body "$local_public_key"
    echo "Signing keys configured. Keep the SunBright key in your login Keychain and back it up securely."
fi
# This public repository hosts its own updates and needs no extra publishing token.
gh variable set SUNBRIGHT_UPDATE_REPOSITORY --repo "$repository" --body "$repository"

if [[ "$publish" == "true" ]]; then
    # Release the remote main commit, regardless of the user's local branch/edits.
    release_sha=$(gh api "repos/$repository/git/ref/heads/main" --jq .object.sha)
    version=$(gh api "repos/$repository/contents/Resources/Info.plist?ref=$release_sha" --jq .content | python3 -c '
import base64, plistlib, sys
info = plistlib.loads(base64.b64decode(sys.stdin.read()))
if not info.get("SURequireSignedFeed"):
    sys.exit("Merge the update implementation before publishing.")
print(info["CFBundleShortVersionString"])
')
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "The release version must have the form major.minor.patch." >&2
        exit 1
    fi
    tag="v$version"
    if tag_sha=$(gh api "repos/$repository/git/ref/tags/$tag" --jq .object.sha 2>/dev/null); then
        if [[ "$tag_sha" != "$release_sha" ]]; then
            echo "$tag already points to different source. Increase the version on main instead of moving the tag." >&2
            exit 1
        fi
        gh workflow run release.yml --repo "$repository" --ref main -f "tag=$tag"
    else
        gh api "repos/$repository/git/refs" --method POST -f "ref=refs/tags/$tag" -f "sha=$release_sha" --silent
    fi
    echo "Release $tag requested. Follow https://github.com/$repository/actions/workflows/release.yml"
else
    echo "Setup complete. Run this script with --publish to start the version on main."
fi
