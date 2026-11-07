# How the effect works

[Project overview](../../README.md) · [All guides](README.md)

Each supported display gets a one-pixel EDR trigger and a full-screen multiply-compositing layer. The layers use floating-point Metal surfaces in extended linear sRGB. The multiplier follows the display’s current headroom, up to the requested nits target relative to the selected SDR reference. macOS retains control of the display’s output.

The renderer follows the documented [Metal EDR configuration](https://developer.apple.com/documentation/metal/performing-your-own-tone-mapping) and the publicly described [EDR plus multiply-overlay technique](https://yogeshvar.github.io/maxnits.html). It is an independent implementation and performs no screen capture. The app also embeds [Sparkle](https://sparkle-project.org) for signed in-app updates; it does not participate in rendering.

Both overlay windows use all-Spaces, all-applications, full-screen auxiliary, and stationary collection behavior. The multiply window uses the public [display-shielding window level](https://developer.apple.com/documentation/coregraphics/cgshieldingwindowlevel()), with the one-pixel HDR trigger one level above it so the boost window cannot cover the trigger. This ordering follows the configuration used by [BrightIntosh](https://github.com/niklasr22/BrightIntosh/blob/main/BrightIntosh/OverlayWindow.swift); it does not capture the display or change its configuration.

Display configuration updates retain surfaces for connected displays and update their position and scale in place. Space changes reassert their window ordering without recreating the surfaces. These are follow-up changes for [issue 9](https://github.com/Cole-Weems/SunBright/issues/9): the earlier all-applications/lifecycle change did not eliminate the reported dimming during full-screen swipes. The new ordering still needs a physical swipe test before the issue can be considered resolved.
