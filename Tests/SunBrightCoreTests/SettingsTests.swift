import XCTest
@testable import SunBrightCore

final class SettingsTests: XCTestCase {
    func testPreferencesRoundTrip() throws {
        let settings = SunBrightSettings(
            multiplier: 1.65, onlyOnPowerAdapter: true,
            apps: [AppRule(bundleIdentifier: "com.example.editor", name: "Editor", isEnabled: false)],
            schedule: DailySchedule(isEnabled: true, startMinute: 1320, endMinute: 360)
        )
        let encoded = try JSONEncoder().encode(settings)
        XCTAssertEqual(try JSONDecoder().decode(SunBrightSettings.self, from: encoded), settings)
    }

    func testNewPreferencesDefaultWhenReadingAnEmptyObject() throws {
        let settings = try JSONDecoder().decode(SunBrightSettings.self, from: Data("{}".utf8))
        XCTAssertEqual(settings, SunBrightSettings())
    }

    func testOutOfRangeSavedValuesAreNormalized() throws {
        let json = """
        {"multiplier": 1000, "schedule": {"isEnabled": true, "startMinute": -50, "endMinute": 5000}}
        """
        let settings = try JSONDecoder().decode(SunBrightSettings.self, from: Data(json.utf8))
        XCTAssertEqual(settings.multiplier, 1600.0 / 600.0)
        XCTAssertEqual(settings.schedule.startMinute, 0)
        XCTAssertEqual(settings.schedule.endMinute, 1439)
    }

    func testNonFiniteAndTooLowMultipliersAreNormalized() {
        XCTAssertEqual(SunBrightSettings(multiplier: .nan).multiplier, 1.4)
        XCTAssertEqual(SunBrightSettings(multiplier: .infinity).multiplier, 1.4)
        XCTAssertEqual(SunBrightSettings(multiplier: -1).multiplier, 1)
    }

    func testAppRulesAreTrimmedDeduplicatedAndGivenNames() {
        let settings = SunBrightSettings(apps: [
            AppRule(bundleIdentifier: " com.example.editor ", name: ""),
            AppRule(bundleIdentifier: "com.example.editor", name: "Duplicate"),
            AppRule(bundleIdentifier: "  ", name: "Empty")
        ])
        XCTAssertEqual(settings.apps, [AppRule(bundleIdentifier: "com.example.editor", name: "com.example.editor")])
    }

    func testMalformedPreferencesAreRejected() {
        for json in ["not json", "{\"multiplier\": \"bright\"}", "{\"apps\": 1}"] {
            XCTAssertThrowsError(try JSONDecoder().decode(SunBrightSettings.self, from: Data(json.utf8)))
        }
    }

    func testActivationModeIsNeverPersisted() throws {
        let data = try JSONEncoder().encode(SunBrightSettings())
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertNil(object["mode"])
    }
}
