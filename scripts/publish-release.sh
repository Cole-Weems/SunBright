#!/usr/bin/env bash
set -euo pipefail

if [[ $# != 3 ]]; then
    echo "Usage: bash scripts/publish-release.sh <repository> <tag> <version>" >&2
    exit 1
fi
repository="$1"
tag="$2"
version="$3"
if [[ ! "$repository" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ||
      ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ || "$tag" != "v$version" ]]; then
    echo "Invalid release repository, tag, or version." >&2
    exit 1
fi
assets=(
    "dist/SunBright-$version-apple-silicon.zip"
    "dist/SunBright-$version-apple-silicon.zip.sha256"
    "dist/updates/appcast.xml"
)
for asset in "${assets[@]}"; do test -s "$asset"; done
create_options=(--repo "$repository" --draft --title "SunBright $version" --notes-file docs/RELEASE-NOTES.md)
edit_options=(--repo "$repository" --draft=false)
if [[ "$repository" == "$GITHUB_REPOSITORY" ]]; then
    # Source tags must already exist. Private change notes stay in the source repo.
    create_options+=(--verify-tag --generate-notes)
    edit_options+=(--verify-tag)
fi
if is_draft=$(gh release view "$tag" --repo "$repository" --json isDraft --jq .isDraft); then
    # Retrying repairs downloads while preserving edited release notes.
    gh release upload "$tag" "${assets[@]}" --repo "$repository" --clobber
else
    # A new release is not published until all three assets have been uploaded.
    gh release create "$tag" "${assets[@]}" "${create_options[@]}"
    is_draft=true
fi
if [[ "$is_draft" == "true" ]]; then
    gh release edit "$tag" "${edit_options[@]}"
fi
