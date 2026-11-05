# SunBright

_A macOS utility for using HDR display headroom to brighten SDR content._

SunBright aims to make the whole desktop easier to read in bright surroundings, including outdoors, by using display brightness headroom normally reserved for HDR content. Everyday apps, documents, and websites should benefit without needing HDR media. The goal is a simple, reversible brightness boost that you can toggle manually, enable for selected apps, or control through automations.

## Project status

SunBright is in the planning stage. This repository currently contains project documentation only; there is no application source, downloadable build, installer, or working brightness control yet.

The features and workflows below describe the intended product. Display compatibility, the minimum macOS version, implementation details, and performance characteristics still need to be established through development and testing.

## Why SunBright?

HDR-capable displays can have brightness headroom beyond the level normally used for standard dynamic range (SDR) content. SunBright will explore using macOS extended dynamic range (EDR) capabilities to make ordinary desktop content brighter on supported hardware.

Brightening SDR content does not turn it into HDR or add detail to the original content. Available headroom depends on the display, macOS, current settings, and operating conditions. SunBright cannot create brightness beyond a display's capabilities, and sustained brightness may differ from a display's advertised peak HDR brightness.

## Product reference: Vivid

[Vivid's website](https://www.getvivid.app/) is the product reference for SunBright's brightness experience. Vivid describes system-wide use of XDR headroom, outdoor readability, integration with existing brightness keys, and a split-screen preview of the effect.

SunBright's proposed design takes these directions from that reference:

- **Whole-desktop brightness:** make ordinary apps easier to read in bright environments.
- **Familiar adjustment:** investigate using the existing brightness keys while the boost is enabled, alongside a dedicated toggle shortcut.
- **Visible feedback:** explore a side-by-side preview so users can judge the effect on their own display.
- **Hardware-aware behavior:** explain when usable brightness headroom is unavailable.

SunBright adds per-app activation and automation as its own stated project goals. It is an independent project with no affiliation with Vivid. Vivid's compatibility, performance, safety statements, pricing, and licensing do not establish equivalent behavior or terms for SunBright.

## Planned features

| Feature | Intended behavior |
| --- | --- |
| Reversible brightness boost | Enable and disable the effect without persistent display modifications. |
| Manual toggle | Give the user a direct way to turn the boost on and off. |
| Keyboard shortcuts | Toggle the boost with a configurable key binding. |
| Brightness-key integration (exploratory) | Investigate adjusting the boosted range with existing brightness keys. |
| Before/after preview (exploratory) | Investigate a side-by-side comparison on supported displays. |
| Per-app activation | Automatically enable the boost when a selected app is active. |
| Automations | Allow repeatable control of the boost through automation; supported integrations are still to be selected. |

### Reversibility

Reversibility is a core design requirement. The intended implementation should:

- Use supported macOS capabilities wherever possible.
- Avoid modifying system files, display firmware, or persistent display profiles.
- Release any temporary display resources and undo changes it owns when disabled or closed.
- Handle sleep, wake, and display connection changes without leaving a stale effect active.
- Give users a reliable manual way to disable the effect, including when automatic activation is configured.

These are implementation and validation goals. Hardware safety, compatibility, and recovery behavior cannot be guaranteed before a working implementation has been tested.

## Compatibility and requirements

SunBright targets macOS and displays that expose usable HDR or EDR brightness headroom. An HDR label alone does not establish that a display will work with the eventual implementation.

Initial hardware investigation should prioritize the built-in XDR displays in 14-inch and 16-inch Apple silicon MacBook Pro models and the Pro Display XDR. This is a proposed test scope, not a supported-device list. Do not assume MacBook Air, 13-inch MacBook Pro, standard Studio Display, or generic HDR monitors have usable headroom for this approach.

| Requirement | Current status |
| --- | --- |
| Minimum macOS version | Not yet established. |
| Compatible Mac models and processors | Not yet verified. |
| Built-in displays | Intended for investigation; no models verified yet. |
| External displays | Support depends on the display, connection, and macOS behavior; unverified. |
| Required permissions | Not yet established; will be documented when the implementation requires them. |
| Developer tools and dependencies | Not yet selected. |

A future compatibility list should distinguish hardware that has been tested from hardware that is only expected to work. Displays without usable headroom should receive a clear explanation instead of an apparent boost that has no effect.

## Installation

There is no installable release yet. This repository cannot currently be built or run as an application.

Once a release exists, this section will document its download location, supported macOS versions, installation steps, any required permissions, and how to uninstall it.

## Intended usage

The interface is still to be designed. The expected workflow is:

1. Open SunBright and check whether the connected display is supported.
2. Enable the brightness boost using the manual control or a keyboard shortcut.
3. Adjust the brightness to a comfortable level; integration with existing brightness keys is an exploratory goal.
4. Disable the boost at any time to return to normal display behavior.
5. Optionally configure per-app activation or an automation.

A comparison preview is also an exploratory goal. If implemented, it should help users evaluate the visible difference before enabling the effect across the desktop.

### Per-app activation

The intended rule is to enable the boost when a user-selected app becomes the foreground app. Behavior when switching between selected and unselected apps, quitting an app, or manually overriding a rule must be defined and tested before this feature ships.

### Automations

Automation support is a project goal. No Shortcuts actions, command-line interface, scripting API, or other integration is currently available. The eventual integration should document how to enable, disable, and query the boost, along with how automation interacts with manual controls and per-app rules.

## Brightness, power, and display behavior

Using additional brightness headroom may increase power consumption and affect battery life or thermal behavior. macOS and the display may limit brightness as conditions change. Exact effects require measurement on supported hardware.

The project should document these tradeoffs alongside compatibility results and keep disabling the boost easy. It should also respect system-controlled brightness limits.

## Development

### Repository layout

```text
SunBright/
├── README.md    # Project overview, planned behavior, and current status
└── AGENTS.md    # Repository guidance for coding agents and contributors
```

No application framework, package manager, build system, or test runner has been committed. There are currently no build, run, lint, or test commands to execute.

Before implementing a feature, read [AGENTS.md](AGENTS.md). When the first application code is added, update this README with the exact prerequisites and commands needed to build, run, and test it from a clean checkout.

### Implementation priorities

1. **Validate the display approach.** Investigate supported macOS APIs, establish whether an SDR brightness boost is feasible, and record hardware and OS compatibility.
2. **Build the manual control.** Implement a minimal toggle with explicit state, predictable cleanup, and a clear unsupported-display response.
3. **Add keyboard control.** Make the shortcut configurable and document any permission requirements or shortcut conflicts. Investigate integration with existing brightness keys.
4. **Add per-app rules.** Define foreground-app detection and its interaction with manual overrides.
5. **Add automation support.** Choose an integration and document its control and state semantics.
6. **Evaluate a comparison preview.** Determine whether a side-by-side view accurately demonstrates the effect without disrupting other windows.
7. **Prepare a release.** Document installation, removal, compatibility, measured limitations, and recovery behavior.

These are proposed milestones, not delivery commitments or completed features.

### Validation goals

Brightness changes need validation on real supported hardware. Automated tests can verify state and rule logic, but they cannot establish that a display becomes brighter or that restoration works on every configuration.

As implementation progresses, verify:

- Repeated enable/disable cycles and normal application exit.
- Recovery after interruption or an unexpected application termination.
- Sleep/wake, display disconnect/reconnect, and changes in available headroom.
- Mixed supported and unsupported displays, if multi-display operation is implemented.
- Keyboard shortcut conflicts and per-app transitions.
- Interactions among manual controls, app rules, and automations.
- Energy use and responsiveness with the boost enabled and disabled.

Record the macOS version, Mac model, display, connection type, and observed result for hardware checks. Clearly label checks that have not been performed.

## Contributing

Contributions can help establish technical feasibility, document display compatibility, define user interactions, or implement the planned features.

- Keep changes focused and explain the behavior they introduce.
- Distinguish working functionality from proposals in documentation and change descriptions.
- Include relevant validation results and describe any hardware-dependent checks you could not perform.
- Update setup and usage instructions whenever a change introduces new prerequisites or commands.
- Avoid committing credentials, signing material, or personal display and application data.

For a compatibility report, include your macOS version, Mac model, display model, and connection type. For a behavior report, include reproduction steps, expected behavior, actual behavior, and whether disabling or quitting SunBright restores the display.

## License

No license file has been added to this repository. A license must be chosen and committed before the project can offer explicit reuse and distribution terms.
