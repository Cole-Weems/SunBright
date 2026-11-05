import XCTest
@testable import SunBrightCore

final class NitsAndHDRPauseTests: XCTestCase {
    func testNitsTargetConvertsToMultiplier() {
        var settings = SunBrightSettings()
        settings.targetNits = 1000
        XCTAssertEqual(settings.multiplier, 1000.0 / 600)
        XCTAssertEqual(settings.targetNits, 1000)
        settings.targetNits = 1600
        XCTAssertEqual(settings.multiplier, 1600.0 / 600)
    }

    func testNitsTargetsAreBoundedAndNonFiniteInputsStayNeutral() {
        var settings = SunBrightSettings()
        for value in [-100.0, .nan, -.infinity, .infinity] {
            settings.targetNits = value
            XCTAssertEqual(settings.targetNits, 600)
        }
        settings.targetNits = 10000
        XCTAssertEqual(settings.targetNits, 1600)
    }

    func testDifferentSDRReferencesChangeTheMapping() {
        var settings = SunBrightSettings()
        settings.sdrReferenceNits = 500
        settings.targetNits = 1600
        XCTAssertEqual(settings.multiplier, 3.2)
        XCTAssertEqual(settings.targetNitsRange, 500...1600)
        settings.sdrReferenceNits = 1000
        settings.targetNits = 500
        XCTAssertEqual(settings.multiplier, 1)
        XCTAssertEqual(settings.targetNits, 1000)
    }

    func testLegacySettingsPreserveMultiplierAndGainHDRDefaults() throws {
        let data = Data("{\"multiplier\":1.65}".utf8)
        let settings = try JSONDecoder().decode(SunBrightSettings.self, from: data)
        XCTAssertEqual(settings.targetNits, 990, accuracy: 0.001)
        XCTAssertTrue(settings.pauseInMediaApps)
        XCTAssertEqual(settings.hdrPauseApps, SunBrightSettings.defaultHDRPauseApps)
    }

    func testHDRSettingsRoundTripAndNormalizeReference() throws {
        var settings = SunBrightSettings()
        settings.sdrReferenceNits = 500
        settings.targetNits = 1400
        settings.pauseInMediaApps = false
        settings.hdrPauseApps = [AppRule(bundleIdentifier: "com.apple.Safari", name: "Safari")]
        XCTAssertEqual(try JSONDecoder().decode(SunBrightSettings.self, from: JSONEncoder().encode(settings)), settings)
        settings.sdrReferenceNits = .nan
        settings.normalize()
        XCTAssertEqual(settings.sdrReferenceNits, 600)
        XCTAssertLessThanOrEqual(settings.targetNits, 1600)
    }

    private func evaluate(_ mode: ActivationMode = .on, manual: Bool = false,
                          running: Set<String> = [], settings: SunBrightSettings = SunBrightSettings()) -> ActivationReason {
        ActivationPolicy.evaluate(mode: mode, settings: settings, context: ActivationContext(
            hasHDRDisplay: true, minuteOfDay: 720, manualHDRPause: manual,
            runningBundleIdentifiers: running
        ))
    }

    func testManualHDRPauseOverridesOnAndAutomaticRules() {
        var settings = SunBrightSettings()
        settings.schedule.isEnabled = true
        for mode in [ActivationMode.on, .automatic] {
            XCTAssertEqual(evaluate(mode, manual: true, settings: settings), .hdrPlayback)
            XCTAssertFalse(evaluate(mode, manual: true, settings: settings).shouldBoost)
        }
        XCTAssertEqual(evaluate(.off, manual: true), .off)
    }

    func testBackgroundPlayerPausesAndQuittingResumes() {
        XCTAssertEqual(evaluate(running: ["com.apple.QuickTimePlayerX"]), .mediaApp("QuickTime Player"))
        XCTAssertEqual(evaluate(running: []), .manual)
        XCTAssertEqual(evaluate(running: ["com.apple.finder"]), .manual)
    }

    func testDisabledMediaRulesAndDisabledGuardDoNotPause() {
        var settings = SunBrightSettings()
        settings.hdrPauseApps[0].isEnabled = false
        XCTAssertEqual(evaluate(running: ["com.apple.QuickTimePlayerX"], settings: settings), .manual)
        settings.pauseInMediaApps = false
        XCTAssertEqual(evaluate(running: ["com.apple.TV"], settings: settings), .manual)
        XCTAssertEqual(evaluate(manual: true, settings: settings), .hdrPlayback)
    }

    func testLeavingPauseRespectsOffAndInactiveAutomaticRules() {
        XCTAssertEqual(evaluate(.off), .off)
        XCTAssertEqual(evaluate(.automatic), .waiting)
        XCTAssertEqual(evaluate(manual: false), .manual)
    }

    func testSavedMediaRulesAreNormalizedWithoutAffectingActivationRules() throws {
        var settings = SunBrightSettings(apps: [AppRule(bundleIdentifier: "com.example.player", name: "Player")])
        settings.hdrPauseApps = [
            AppRule(bundleIdentifier: " com.example.player ", name: ""),
            AppRule(bundleIdentifier: "com.example.player", name: "Duplicate"),
            AppRule(bundleIdentifier: " ", name: "Invalid")
        ]
        let saved = try JSONDecoder().decode(SunBrightSettings.self, from: JSONEncoder().encode(settings))
        XCTAssertEqual(saved.hdrPauseApps, [AppRule(bundleIdentifier: "com.example.player", name: "com.example.player")])
        XCTAssertEqual(saved.apps, settings.apps)
    }
}
