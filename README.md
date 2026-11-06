# SunBright

A native macOS menu bar tool that boosts everyday SDR content using your display’s HDR headroom.

This is the first, experimental iteration. It uses temporary, click-through Metal overlays; turning it off or quitting removes the effect. SunBright does not write gamma tables, change display profiles, modify system files, or change the system brightness setting.

## Included

- Menu bar controls with **Off**, **On**, and **Auto** modes.
- Estimated brightness targets in nits, from the selected SDR reference up to 1600 nits, capped by each display’s current HDR headroom.
- Manual HDR pause and configurable automatic pause while selected media apps are running.
- Global **Option–Command–B** toggle, without Accessibility or Input Monitoring permissions.
- Per-app activation based on the foreground app’s bundle identifier.
- A daily schedule, including windows that cross midnight.
- An optional power adapter requirement.
- Saved preferences, per-display status, and cleanup on sleep, session changes, display disconnection, and quit.
- Optional **Launch at Login**, managed through macOS’s login-item registration.

SunBright starts **off** on every launch. Your brightness, app rules, and schedule are saved; activation is never saved.

## Documentation

Check the [documentation](docs/guides/README.md) for installation, updating, building, usage, release instructions, and current limitations.
