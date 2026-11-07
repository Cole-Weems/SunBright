import AppKit
import QuartzCore
import XCTest
@testable import SunBright

final class OverlayPanelTests: XCTestCase {
    @MainActor
    func testBoostClearsTheShieldingLevelAndTriggerRemainsAboveIt() {
        _ = NSApplication.shared
        let frame = NSRect(x: 0, y: 0, width: 100, height: 100)
        let boost = OverlayPanel(frame: frame, layer: CALayer(), role: .boost)
        let trigger = OverlayPanel(frame: frame, layer: CALayer(), role: .trigger)
        defer {
            boost.close()
            trigger.close()
        }

        XCTAssertGreaterThanOrEqual(boost.level.rawValue, Int(CGShieldingWindowLevel()))
        XCTAssertGreaterThan(trigger.level.rawValue, boost.level.rawValue)
        XCTAssertFalse(boost.isVisible)
        XCTAssertFalse(trigger.isVisible)
    }

    @MainActor
    func testBothSurfacesJoinFullScreenSpacesWithoutTakingFocusOrClicks() {
        _ = NSApplication.shared
        let requiredBehavior: NSWindow.CollectionBehavior = [
            .canJoinAllSpaces, .canJoinAllApplications, .fullScreenAuxiliary,
            .stationary, .ignoresCycle
        ]
        for role in [OverlayPanel.Role.trigger, .boost] {
            let panel = OverlayPanel(
                frame: NSRect(x: 0, y: 0, width: 100, height: 100),
                layer: CALayer(), role: role
            )
            defer { panel.close() }

            XCTAssertTrue(panel.collectionBehavior.contains(requiredBehavior))
            XCTAssertFalse(panel.collectionBehavior.contains(.fullScreenPrimary))
            XCTAssertFalse(panel.collectionBehavior.contains(.fullScreenNone))
            XCTAssertTrue(panel.styleMask.contains(.nonactivatingPanel))
            XCTAssertFalse(panel.canBecomeKey)
            XCTAssertFalse(panel.canBecomeMain)
            XCTAssertTrue(panel.ignoresMouseEvents)
            XCTAssertFalse(panel.hidesOnDeactivate)
        }
    }
}
