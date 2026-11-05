import XCTest
@testable import SunBrightCore

final class ActivationPolicyTests: XCTestCase {
    private var settings: SunBrightSettings {
        SunBrightSettings(
            apps: [AppRule(bundleIdentifier: "com.apple.Safari", name: "Safari")],
            schedule: DailySchedule(isEnabled: true, startMinute: 540, endMinute: 1080)
        )
    }

    private func evaluate(
        mode: ActivationMode = .automatic,
        settings: SunBrightSettings? = nil,
        hdr: Bool = true,
        suspended: Bool = false,
        battery: Bool = false,
        app: String? = nil,
        minute: Int = 720
    ) -> ActivationReason {
        ActivationPolicy.evaluate(
            mode: mode, settings: settings ?? self.settings,
            context: ActivationContext(hasHDRDisplay: hdr, isSuspended: suspended,
                                       isOnBattery: battery, frontmostBundleIdentifier: app,
                                       minuteOfDay: minute)
        )
    }

    func testOffOverridesBothAutomationTriggers() {
        XCTAssertEqual(evaluate(mode: .off, app: "com.apple.Safari"), .off)
    }

    func testManualModeDoesNotRequireAnAutomationMatch() {
        XCTAssertEqual(evaluate(mode: .on, minute: 0), .manual)
    }

    func testManualModeStillRequiresHDRAndAnActiveSession() {
        XCTAssertEqual(evaluate(mode: .on, hdr: false), .noHDRDisplay)
        XCTAssertEqual(evaluate(mode: .on, suspended: true), .suspended)
    }

    func testPowerAdapterRuleAppliesToBothManualAndAutomaticModes() {
        var settings = self.settings
        settings.onlyOnPowerAdapter = true
        for mode in [ActivationMode.on, .automatic] {
            XCTAssertEqual(evaluate(mode: mode, settings: settings, battery: true), .battery)
            XCTAssertTrue(evaluate(mode: mode, settings: settings, battery: false).shouldBoost)
        }
    }

    func testBatteryIsAllowedByDefault() {
        XCTAssertTrue(evaluate(battery: true).shouldBoost)
    }

    func testSelectedAppCanActivateOutsideTheSchedule() {
        XCTAssertEqual(evaluate(app: "com.apple.Safari", minute: 0), .app("Safari"))
    }

    func testScheduleCanActivateWithoutAMatchingApp() {
        XCTAssertEqual(evaluate(app: "com.apple.finder"), .schedule)
    }

    func testLeavingSelectedAppRemovesItsTrigger() {
        XCTAssertTrue(evaluate(app: "com.apple.Safari", minute: 0).shouldBoost)
        XCTAssertEqual(evaluate(app: "com.apple.finder", minute: 0), .waiting)
    }

    func testDisabledAppDoesNotActivate() {
        var settings = self.settings
        settings.apps[0].isEnabled = false
        XCTAssertEqual(evaluate(settings: settings, app: "com.apple.Safari", minute: 0), .waiting)
    }

    func testAppIdentifierMustMatchExactly() {
        XCTAssertEqual(evaluate(app: "com.apple.Safari.WebApp", minute: 0), .waiting)
    }

    func testEmptyRulesWaitInAutomaticMode() {
        XCTAssertEqual(evaluate(settings: SunBrightSettings()), .waiting)
    }

    func testStandardBrightnessDoesNotCreateOverlays() {
        XCTAssertEqual(evaluate(mode: .on, settings: SunBrightSettings(multiplier: 1)), .standardBrightness)
    }

    func testSuspensionAndWakeReevaluateTheCurrentRules() {
        XCTAssertEqual(evaluate(suspended: true, app: "com.apple.Safari"), .suspended)
        XCTAssertEqual(evaluate(suspended: false, app: "com.apple.Safari"), .app("Safari"))
        XCTAssertEqual(evaluate(suspended: false, app: "com.apple.finder", minute: 1200), .waiting)
    }

    func testDisabledReasonsNeverRequestBrightness() {
        for reason in [ActivationReason.off, .noHDRDisplay, .suspended, .battery, .standardBrightness, .waiting] {
            XCTAssertFalse(reason.shouldBoost, reason.description)
        }
    }

    func testKeyboardToggleCanTurnOffAPausedManualMode() {
        XCTAssertEqual(evaluate(mode: .on, hdr: false), .noHDRDisplay)
        XCTAssertEqual(ActivationMode.on.toggled(automaticIsActive: false), .off)
        XCTAssertEqual(ActivationMode.off.toggled(automaticIsActive: false), .on)
    }

    func testKeyboardToggleOverridesAutomaticModeInBothDirections() {
        XCTAssertEqual(ActivationMode.automatic.toggled(automaticIsActive: true), .off)
        XCTAssertEqual(ActivationMode.automatic.toggled(automaticIsActive: false), .on)
    }
}
