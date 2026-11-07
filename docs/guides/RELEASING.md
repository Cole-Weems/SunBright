# Release SunBright

[Project overview](../../README.md) · [All guides](README.md)

Set up the [development tools and checkout](BUILD.md) before building a release. Run commands from the repository root.

## Package an Apple Silicon build

For an Apple Silicon release build, run:

```sh
bash scripts/build-app.sh --apple-silicon
bash scripts/package-app.sh
```

The packaging script creates `dist/SunBright-<version>-apple-silicon.zip` and a SHA-256 checksum alongside it. It preserves executable permissions and app metadata. For optional Developer ID signing, supply `SUNBRIGHT_SIGNING_IDENTITY` when building and notarize separately. Without it, the build is ad hoc signed and unnotarized.

## Automatic GitHub Releases

The **Publish GitHub release** workflow automatically tests, builds, and publishes a release when you push a version tag. It verifies the Apple Silicon app bundle and all Sparkle helpers, then uploads the versioned ZIP, SHA-256 checksum, and signed `appcast.xml`. Sparkle uses that feed for the Settings update button. New source-repository releases include [release notes](../RELEASE-NOTES.md) followed by GitHub’s generated change notes.

### One-time updater setup

Complete this setup before pushing the first tag containing the updater. It needs no Apple developer membership, but it does need a persistent Sparkle signing key and publicly readable downloads. Missing signing or hosting configuration stops the release workflow before publication; it never ships an updater that accepts unsigned downloads.

SunBright's repository is now public, so it can host its own update downloads. From an up-to-date checkout on your Mac, with Xcode, Python 3, and the [GitHub CLI](https://cli.github.com/) installed, authenticate the CLI (`gh auth login`) with an account that can manage this repository, then run:

```sh
bash scripts/setup-updates.sh --publish
```

The helper creates or reuses a signing key in your login Keychain, transfers it directly into the repository's Actions secret, sets the public configuration, and starts the version on remote `main`. It preserves existing signing secrets and rejects mismatched keys or moved tags. Temporary exported key files are deleted. Keep the Keychain key and a secure backup; do not paste private keys or GitHub tokens into chat. Omit `--publish` to configure keys without starting a release. This script must run with your own GitHub CLI authentication because the Codex GitHub connector does not expose Actions-secret administration.

The manual steps below remain available for custom hosting or key recovery.

The source repository can remain private. Create a separate **public download-only repository**, initialized with a README, and set the source repository's Actions variable `SUNBRIGHT_UPDATE_REPOSITORY` to its `owner/repository` name. Only the compiled ZIP, checksum, signed feed, and reviewed release notes are copied there; source code and private pull request change notes are not copied. Public artifacts will be downloadable by anyone. If the source repository is already public, this variable can be omitted to use its own Releases instead.

For a separate repository, create a fine-grained GitHub token limited to that download repository with **Contents: Read and write** permission. Save it as the **source** repository's Actions secret `SUNBRIGHT_UPDATE_TOKEN`. Never put a GitHub token in the app, feed, source files, or chat. If publishing to the same public repository, the workflow uses its built-in token and needs no extra token.

On your Mac, from the source checkout, resolve the pinned Sparkle package and generate a signing key once:

```sh
swift package resolve
sparkle_bin=.build/artifacts/sparkle/Sparkle/bin
"$sparkle_bin/generate_keys" --account SunBright
```

Sparkle saves the private key in your login Keychain and prints the public key. Configure these in the **source** repository's **Settings → Secrets and variables → Actions**:

| Type | Name | Value |
| --- | --- | --- |
| Variable | `SUNBRIGHT_UPDATE_REPOSITORY` | Public download repository's `owner/repository` name, if separate |
| Variable | `SUNBRIGHT_SPARKLE_PUBLIC_KEY` | The public key printed by `generate_keys` |
| Secret | `SUNBRIGHT_SPARKLE_PRIVATE_KEY` | The exported private signing key |
| Secret | `SUNBRIGHT_UPDATE_TOKEN` | The fine-grained token, if using a separate repository |

If you use the GitHub CLI, you can transfer the signing key without displaying it. Authenticate the CLI with an account that can manage the source repository's secrets first:

```sh
gh variable set SUNBRIGHT_SPARKLE_PUBLIC_KEY --repo Cole-Weems/SunBright \
  --body "$("$sparkle_bin/generate_keys" --account SunBright -p)"
key_directory=$(mktemp -d)
"$sparkle_bin/generate_keys" --account SunBright -x "$key_directory/private-key"
gh secret set SUNBRIGHT_SPARKLE_PRIVATE_KEY --repo Cole-Weems/SunBright < "$key_directory/private-key"
rm -rf "$key_directory"
```

Keep the Keychain key and a secure backup. Use the same public/private key pair and feed URL for future versions; changing them can strand installed copies. Sparkle verifies both the signed feed and update archive against the public key embedded in the installed app. The workflow independently checks that the generated archive signature matches the embedded public key. Apple Developer ID signing and notarization remain separate from Sparkle signing.

### Publish a version

Before tagging a new version, update `CFBundleShortVersionString`, **increase `CFBundleVersion`** in `Resources/Info.plist`, and update [release notes](../RELEASE-NOTES.md). Sparkle compares build numbers to decide whether an update is newer; a new tag alone is not enough. Settings displays the version from the app bundle automatically. Commit, test, and merge the source you intend to release into `main`. Then push a tag matching the app version:

```sh
git switch main
git pull --ff-only origin main
version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Resources/Info.plist)
git tag "v$version"
git push origin "v$version"
```

Tags must have the form `v<major>.<minor>.<patch>` and match the version in the tagged source. The workflow always checks out that exact tag; it rejects missing tags and version mismatches before publishing. Pushing ordinary commits runs CI without creating a release. Do not move a published tag to new code; give source changes a new version and tag.

To retry a failed release or refresh downloads for an existing tag, select **Actions → Publish GitHub release → Run workflow** and enter the existing tag in **tag**. The selected branch supplies the workflow, but the app is built from the entered tag. Reruns replace the same tag's ZIP, checksum, and feed while preserving existing release notes. A new release stays a draft until its uploads succeed, then publishes automatically; a retry also finishes publishing an existing draft. Tags created before this updater integration use the old build scripts and cannot produce update-enabled packages.

The app's feed is `https://github.com/<update-owner>/<update-repository>/releases/latest/download/appcast.xml`, with version-specific archive URLs inside it. The workflow preserves the source repository's release and additionally publishes to the public download repository when configured. Private source releases keep GitHub's generated change notes; the public mirror uses only the reviewed release-notes file. GitHub's Latest release determines which feed the app sees.

Merge this workflow into the default branch to enable manual runs. Free builds remain ad hoc signed and unnotarized, with the first-launch approval requirement. Automated build and archive checks do not validate HDR output on real displays; complete the relevant [hardware checks](../VALIDATION.md) before tagging a release. Older apps without Sparkle need one manual installation of the first update-enabled build.

### Configure a local update-enabled build

Ordinary source and CI builds have updates disabled. To build a local app pointing at your production feed, provide public configuration before running the normal build script:

```sh
SUNBRIGHT_UPDATE_FEED_URL='https://github.com/<update-owner>/<update-repository>/releases/latest/download/appcast.xml' \
SUNBRIGHT_SPARKLE_PUBLIC_KEY='<your public key>' \
  bash scripts/build-app.sh --apple-silicon
```

The private key is needed only for generating the update feed, not for building or running the app. Python 3 validates the public configuration and writes it into the app's Info.plist before signing.
