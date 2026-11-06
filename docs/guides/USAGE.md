# Controls and automation

[Project overview](../../README.md) · [All guides](README.md)

| Control | Behavior |
| --- | --- |
| Off | Removes all overlays and pauses automation. |
| On | Boosts supported connected displays, subject to the power adapter rule. |
| Auto | Boosts when an enabled app rule **or** the daily schedule matches. |
| Option–Command–B | Toggles manually. Select Auto again to resume automation. |
| HDR pause | Removes overlays while preserving the selected activation mode. |
| Media-app pause | Overrides On and Auto while any enabled selected player is running. |
| Quit | Removes all overlays and exits. |

In **Settings → App Rules**, add applications with the native app picker. Rules match exact bundle identifiers. Switching away from a matching app removes that trigger; a matching schedule can still keep the boost on. Opening SunBright’s own settings preserves the last foreground app.

In **Settings → Schedule**, choose a start and end time, enable the schedule, and select **Auto**. Times follow your Mac’s local clock, with an inclusive start and exclusive end. An end earlier than the start continues into the following day. Equal times create an empty window.


See [nits targets and HDR playback](HDR.md) for brightness estimates and pause behavior.
