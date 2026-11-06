import ServiceManagement
import SunBrightCore
import XCTest
@testable import SunBright

final class LoginStartupTests: XCTestCase {
    @MainActor
    func testLoginRegistrationNeverRestoresActivationButPreservesRules() throws {
        let suite = "SunBright.LoginStartupTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = SunBrightSettings(
            multiplier: 1.8, onlyOnPowerAdapter: true,
            apps: [AppRule(bundleIdentifier: "com.example.editor", name: "Editor")],
            schedule: DailySchedule(isEnabled: true, startMinute: 0, endMinute: 1439)
        )
        let store = PreferencesStore(defaults: defaults)
        try store.save(settings)

        for oldMode in ["off", "on", "automatic"] {
            // Even older/foreign data containing activation must not restore it.
            var object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(settings)) as? [String: Any])
            object["mode"] = oldMode
            defaults.set(try JSONSerialization.data(withJSONObject: object), forKey: "SunBright.settings.v1")
            for status in [SMAppService.Status.notRegistered, .enabled, .requiresApproval] {
                let service = StartupLoginItemService(status: status)
                let loginItem = LoginItemModel(service: service)
                let model = AppModel(store: store, loginItem: loginItem)
                XCTAssertEqual(model.mode, .off)
                XCTAssertEqual(model.reason, .off)
                XCTAssertFalse(model.isBoosting)
                XCTAssertEqual(model.settings, settings)
                XCTAssertEqual(loginItem.status, status)
            }
        }
    }
}

@MainActor
private struct StartupLoginItemService: LoginItemService {
    let status: SMAppService.Status
    var isAvailable: Bool { true }
    func register() async throws { XCTFail("Startup must not register login items") }
    func unregister() async throws { XCTFail("Startup must not unregister login items") }
}
