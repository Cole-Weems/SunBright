import AppKit
import SwiftUI

/// AppKit resolves the current bundle's app icon. Keep all in-app artwork tied
/// to it rather than maintaining separate copies or a second sun illustration.
@MainActor
enum AppIcon {
    static var image: NSImage {
        NSApplication.shared.applicationIconImage ?? NSImage(size: NSSize(width: 1, height: 1))
    }

    static func statusImage(isBoosting: Bool) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let result = NSImage(size: size)
        result.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(in: NSRect(origin: .zero, size: size), from: .zero,
                   operation: .sourceOver, fraction: 1)
        if isBoosting {
            let indicator = NSBezierPath(ovalIn: NSRect(x: 13, y: 0, width: 5, height: 5))
            NSColor.systemOrange.setFill()
            indicator.fill()
            NSColor.black.withAlphaComponent(0.6).setStroke()
            indicator.lineWidth = 0.75
            indicator.stroke()
        }
        result.unlockFocus()
        result.isTemplate = false
        return result
    }
}

@MainActor
struct AppIconView: View {
    let size: CGFloat

    var body: some View {
        Image(nsImage: AppIcon.image)
            .renderingMode(.original)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}
