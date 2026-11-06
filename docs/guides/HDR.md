# Nits targets and HDR playback

[Project overview](../../README.md) · [All guides](README.md)

The slider defaults to **600–1600 estimated nits**. In General settings, select a **500**, **600**, or **1000 nit SDR reference** appropriate to your display and current brightness setting. SunBright converts the target into a relative multiplier and caps the rendered effect to each display’s current headroom. The reference is shared across connected displays, so mixed displays can have different actual output. These numbers are estimates, not measured or guaranteed luminance.

[Apple’s MacBook Pro specifications](https://support.apple.com/en-gb/117737) distinguish **1000 nits sustained full-screen** from **1600 nits peak HDR**; 1600 is not a promise of sustained full-screen output. SDR brightness varies by model and conditions. A target equal to the SDR reference disables the overlays.

**Pause for HDR playback** in the menu or HDR Pause settings removes all overlays until you uncheck it. It preserves your mode rather than turning automation off.

**Automatically pause while selected media apps are running** is enabled by default for QuickTime Player, TV, and VLC. Add/remove players or browsers in **Settings → HDR Pause**. Pausing applies to background players too and overrides manual On and automatic activation; quitting all selected players allows the current mode and rules to resume within about a second.

This is deliberately an **app-based safeguard, not automatic HDR-content detection**. The public display headroom API reports capability and available range, not whether another app is playing HDR; SunBright’s own overlays also request EDR. No playback inspection, screen recording, or private media APIs are used. Consequently, selected apps pause the boost for SDR video and while idle too. For HDR in an unselected app, use the manual pause or add that app. See [Apple’s EDR documentation](https://developer.apple.com/documentation/appkit/nsscreen/maximumextendeddynamicrangecolorcomponentvalue).
