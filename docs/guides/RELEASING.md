# Release SunBright

[Project overview](../../README.md) · [All guides](README.md)

Set up the [development tools and checkout](BUILD.md) before building a release. Run commands from the repository root.

## Package an Apple Silicon build

For an Apple Silicon release build, run:

```sh
bash scripts/build-app.sh --apple-silicon
bash scripts/package-app.sh
```

The packaging script creates `dist/SunBright-0.2.0-apple-silicon.zip` and a SHA-256 checksum alongside it. It preserves executable permissions and app metadata. For optional Developer ID signing, supply `SUNBRIGHT_SIGNING_IDENTITY` when building and notarize separately. Without it, the build is ad hoc signed and unnotarized.

## Automatic GitHub Releases

The **Publish GitHub release** workflow automatically tests, builds, and publishes a release when you push a version tag. It verifies the Apple Silicon app bundle and signature, then uploads the versioned ZIP and SHA-256 checksum. New releases include [release notes](../RELEASE-NOTES.md) followed by GitHub’s generated change notes. The workflow uses GitHub’s built-in token and needs no Apple signing secrets.

Before tagging a new version, update `CFBundleShortVersionString` and the build number in `Resources/Info.plist`, the visible settings version, and [release notes](../RELEASE-NOTES.md). Commit, test, and merge the source you intend to release into `main`. Then push a tag matching the app version:

```sh
git switch main
git pull --ff-only origin main
version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Resources/Info.plist)
git tag "v$version"
git push origin "v$version"
```

Tags must have the form `v<major>.<minor>.<patch>` and match the version in the tagged source. The workflow always checks out that exact tag; it rejects missing tags and version mismatches before publishing. Pushing ordinary commits runs CI without creating a release. Do not move a published tag to new code; give source changes a new version and tag.

To retry a failed release or refresh the downloads for an existing tag, select **Actions → Publish GitHub release → Run workflow** and enter the existing tag in **tag**. The selected branch supplies the workflow, but the app is built from the entered tag. Reruns replace the same tag’s ZIP and checksum while preserving existing release notes. A new release stays a draft until its uploads succeed, then publishes automatically; a retry also finishes publishing an existing draft.

Merge this workflow into the default branch to enable manual runs. Releases follow the repository’s existing visibility. Free builds remain ad hoc signed and unnotarized, with the first-launch approval requirement. Automated build and archive checks do not validate HDR output on real displays; complete the relevant [hardware checks](../VALIDATION.md) before tagging a release.
