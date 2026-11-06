# How the effect works

[Project overview](../../README.md) · [All guides](README.md)

Each supported display gets a one-pixel EDR trigger and a full-screen multiply-compositing layer. The layers use floating-point Metal surfaces in extended linear sRGB. The multiplier follows the display’s current headroom, up to the requested nits target relative to the selected SDR reference. macOS retains control of the display’s output.

The implementation follows the documented [Metal EDR configuration](https://developer.apple.com/documentation/metal/performing-your-own-tone-mapping) and the publicly described [EDR plus multiply-overlay technique](https://yogeshvar.github.io/maxnits.html). It is an independent implementation with no third-party runtime dependencies. No screen capture is performed.

Both overlay windows use all-Spaces, full-screen auxiliary, and stationary collection behavior. Display configuration updates retain overlays for connected displays, but this checkout does not explicitly update their position and scale in place. Continuity during full-screen swipes still needs verification on a Mac.
