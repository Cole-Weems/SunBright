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

## Prepare a GitHub Release

The **Prepare GitHub release** workflow tests the code, builds and verifies the Apple Silicon architecture, packages the app, and creates a **draft** GitHub Release with the ZIP and checksum. It needs no Apple signing secrets. It does not publish the draft or make the repository public.

After merging the workflow into the default branch, maintainers can select **Actions → Prepare GitHub release → Run workflow** and choose the branch to build. Alternatively, push a version tag matching `CFBundleShortVersionString` in `Resources/Info.plist`:

```sh
# After committing and pushing the source you intend to release:
git tag v0.2.0
git push origin v0.2.0
```

For later versions, first update the app version and build number in `Resources/Info.plist`, update the visible settings version and [release notes](../RELEASE-NOTES.md), then commit, test, and push a new matching tag. Do not reuse a published version or tag. The workflow fails rather than overwriting an existing release.

Review the draft’s assets and notes and test the downloaded app before publishing it in GitHub’s Releases page. Free builds retain the first-launch approval requirement. Draft creation, archive checks, and successful compilation do not validate HDR output on real displays.
