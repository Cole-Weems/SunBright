import AppKit
import XCTest
@testable import SunBright

final class AppIconTests: XCTestCase {
    @MainActor
    func testSharedImageFollowsTheCurrentApplicationIcon() throws {
        let application = NSApplication.shared
        let original = application.applicationIconImage
        defer { application.applicationIconImage = original }

        application.applicationIconImage = makeIcon(color: .red, size: 32)
        let first = try XCTUnwrap(application.applicationIconImage?.tiffRepresentation)
        XCTAssertEqual(try XCTUnwrap(AppIcon.image.tiffRepresentation), first)

        application.applicationIconImage = makeIcon(color: .blue, size: 48)
        let second = try XCTUnwrap(application.applicationIconImage?.tiffRepresentation)
        XCTAssertNotEqual(first, second)
        XCTAssertEqual(try XCTUnwrap(AppIcon.image.tiffRepresentation), second)
    }

    @MainActor
    func testInterfaceImagesPreserveSourceArtworkAndDistinguishBoostState() throws {
        let application = NSApplication.shared
        let original = application.applicationIconImage
        defer { application.applicationIconImage = original }

        let icon = makeIcon(color: .blue, size: 64)
        icon.isTemplate = true
        application.applicationIconImage = icon
        let source = AppIcon.image
        let sourceSize = source.size
        let sourceTemplate = source.isTemplate
        let sourceArtwork = try XCTUnwrap(source.tiffRepresentation)

        let inactive = AppIcon.statusImage(isBoosting: false)
        let active = AppIcon.statusImage(isBoosting: true)
        let tab = AppIcon.tabImage
        XCTAssertEqual(tab.size, NSSize(width: 16, height: 16))
        XCTAssertFalse(tab.isTemplate)
        XCTAssertEqual(inactive.size, NSSize(width: 18, height: 18))
        XCTAssertEqual(active.size, NSSize(width: 18, height: 18))
        XCTAssertFalse(inactive.isTemplate)
        XCTAssertFalse(active.isTemplate)
        // Rasterize both images so deferred drawing also runs before checking
        // that neither status variant changes the shared source image.
        XCTAssertNotEqual(try XCTUnwrap(inactive.tiffRepresentation),
                          try XCTUnwrap(active.tiffRepresentation))
        XCTAssertEqual(source.size, sourceSize)
        XCTAssertEqual(source.isTemplate, sourceTemplate)
        XCTAssertEqual(try XCTUnwrap(source.tiffRepresentation), sourceArtwork)
    }

    @MainActor
    private func makeIcon(color: NSColor, size: CGFloat) -> NSImage {
        NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            color.setFill()
            NSBezierPath(rect: rect).fill()
            return true
        }
    }
}
