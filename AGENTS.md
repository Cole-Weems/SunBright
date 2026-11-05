# Guidance for working on SunBright

## Scope and current state

This file applies to the entire repository. Read it and `README.md` before making changes. Follow more specific instructions in a subdirectory if such files are added later.

SunBright is a planned macOS utility for using HDR/extended dynamic range (EDR) display headroom to brighten SDR content. Its core goals are reversible operation, manual and keyboard toggles, per-app activation, and automation support.

The repository currently contains documentation only. There is no application implementation, chosen framework, dependency manifest, build system, or test suite. Treat the README's features as planned until code and validation establish otherwise.

## Before changing files

- Inspect the working tree and preserve unrelated user changes.
- Read the relevant source and configuration once they exist; use them to establish actual behavior and available commands.
- Keep the change within the requested scope. A documentation task does not imply scaffolding an application or choosing a technology stack.
- State necessary assumptions when the repository does not answer an implementation question. Do not present assumptions as established project decisions.

## Product requirements

### Display behavior and cleanup

- Prefer supported macOS APIs. Investigate EDR capabilities and document the selected approach before relying on it.
- Do not modify display firmware, system files, or persistent color profiles to implement the boost.
- Treat display headroom as a changing capability. Detect unsupported or unavailable configurations and report them clearly.
- Track temporary resources and display changes owned by SunBright; release or undo them when disabled or closed.
- Avoid overwriting display changes made by the user or another application while SunBright is running.
- Handle sleep/wake and display connection changes explicitly. Investigate behavior on unexpected termination and document recovery limitations.
- Respect system brightness limits. Do not promise a fixed brightness gain, universal compatibility, or guaranteed hardware safety without evidence.

### Controls and rules

- Keep the effective boost state explicit and observable by the user.
- Define how manual control, keyboard shortcuts, per-app rules, and automation interact before combining them.
- Keep a reliable manual disable action available when automatic activation is enabled.
- Make repeated enable and disable requests safe; avoid accumulating effects or leaking resources.
- For per-app activation, distinguish the foreground app from apps that are merely running.
- When adding global shortcuts or app observation, establish actual permission requirements and explain them in user documentation.
- Request only permissions needed for implemented functionality. Do not assume Accessibility or Screen Recording access is required before confirming the chosen APIs.

## Implementation practices

- Follow the language, structure, and formatting established by committed code when it exists.
- Keep display capability detection, boost lifecycle, activation rules, and user interface responsibilities separable so state logic can be tested independently of hardware.
- Select dependencies based on concrete needs. Document new tools and prerequisites rather than assuming a package manager or framework is already available.
- Keep UI updates responsive and honor the threading requirements of the selected macOS APIs.
- Make errors actionable, especially for unsupported displays, unavailable headroom, and permission failures.
- Do not log credentials, signing material, or unnecessary personal app-usage data.
- Keep refactors and unrelated cleanup out of focused feature or documentation changes.

## Build and validation

There are currently no build, run, lint, or test commands. Do not invent commands or claim that application tests passed.

When adding the first implementation:

1. Commit the project configuration and dependency declarations needed to reproduce the build.
2. Document exact setup, build, run, and test commands in `README.md`.
3. Establish supported macOS and developer-tool versions from the implementation's requirements.
4. Add meaningful tests for state transitions, rule precedence, repeated requests, and cleanup where they can run without display hardware.

For subsequent code changes, run the relevant checks available in the repository. Report commands and results accurately, including any platform or hardware limitations. A non-macOS environment cannot verify macOS display behavior.

For documentation-only changes, check accuracy, relative links, Markdown structure, and whitespace. An application build is unnecessary unless the documentation change also affects executable configuration or examples that need verification.

### Hardware verification

Use real supported hardware to verify brightness and restoration. Record the macOS version, Mac model, display model, connection type, and conditions relevant to the result.

Choose checks relevant to the change:

- Enable, disable, repeated toggles, and normal exit.
- Unexpected termination and recovery.
- Sleep/wake and display connection changes.
- Unsupported displays and changes in available headroom.
- Multiple displays when that behavior is implemented.
- Foreground-app transitions, shortcut conflicts, and manual overrides.
- Automation requests interacting with other controls.
- Power use and responsiveness when those properties are affected.

Do not equate passing unit tests with verified display compatibility. List hardware checks that remain unperformed.

## Documentation and completion

- Keep `README.md` aligned with the actual repository state.
- Separate implemented features, planned features, and unverified compatibility claims.
- Update the repository layout and development commands when adding code or tooling.
- Document new permissions, user controls, compatibility findings, and known limitations with the feature that introduces them.
- Do not invent download links, release versions, benchmarks, supported hardware, or license terms.
- Finish with a concise account of what changed, what was checked, and any unresolved limitation relevant to the task.
