import Combine
import SunBrightCore
import XCTest
@testable import SunBright

final class UpdateModelTests: XCTestCase {
    private let publicKey = Data(repeating: 1, count: 32).base64EncodedString()

    func testConfigurationRequiresAnAppHTTPSAndAnEd25519Key() {
        for (path, feed, key, available) in [
            ("/Applications/SunBright.app", "https://example.com/appcast.xml", publicKey, true),
            ("/tmp/SunBright", "https://example.com/appcast.xml", publicKey, false),
            ("/Applications/SunBright.app", "http://example.com/appcast.xml", publicKey, false),
            ("/Applications/SunBright.app", "https://token@example.com/appcast.xml", publicKey, false),
            ("/Applications/SunBright.app", "https://example.com/appcast.xml", "invalid", false),
            ("/Applications/SunBright.app", "https://example.com/appcast.xml", Data(repeating: 1, count: 31).base64EncodedString(), false)
        ] {
            let configuration = UpdateConfiguration(bundleURL: URL(fileURLWithPath: path), feedURL: feed, publicKey: key)
            XCTAssertEqual(configuration.unavailableReason == nil, available)
        }
        XCTAssertNotNil(UpdateConfiguration(bundleURL: URL(fileURLWithPath: "/Applications/SunBright.app"), feedURL: nil, publicKey: nil).unavailableReason)
    }

    @MainActor
    func testStartingUpdaterNeverChecksWithoutAButtonPress() {
        let service = FakeUpdateService()
        let model = makeModel(service)
        model.checkForUpdates()
        XCTAssertEqual(service.checkCount, 0)
        model.start()
        model.start()
        XCTAssertEqual(service.startCount, 1)
        XCTAssertEqual(service.checkCount, 0)
        XCTAssertTrue(model.canCheckForUpdates)
        model.checkForUpdates()
        XCTAssertEqual(service.checkCount, 1)
        service.available.send(false)
        XCTAssertFalse(model.canCheckForUpdates)
        model.checkForUpdates()
        XCTAssertEqual(service.checkCount, 1)
        service.available.send(true)
        model.checkForUpdates()
        XCTAssertEqual(service.checkCount, 2)
    }

    @MainActor
    func testUnavailableBuildDoesNotCreateAnUpdater() {
        let model = UpdateModel(
            configuration: UpdateConfiguration(bundleURL: URL(fileURLWithPath: "/tmp/SunBright"), feedURL: nil, publicKey: nil),
            makeService: { XCTFail("An unbundled build must not create an updater"); return FakeUpdateService() }
        )
        model.start()
        model.checkForUpdates()
        XCTAssertFalse(model.canCheckForUpdates)
    }

    @MainActor
    func testFailedStartupDisablesChecksAndCanBeRetried() {
        let service = FakeUpdateService()
        service.failStartup = true
        let model = makeModel(service)
        model.start()
        XCTAssertNotNil(model.errorMessage)
        XCTAssertFalse(model.canCheckForUpdates)
        model.checkForUpdates()
        XCTAssertEqual(service.checkCount, 0)
        service.failStartup = false
        model.start()
        XCTAssertNil(model.errorMessage)
        XCTAssertTrue(model.canCheckForUpdates)
    }

    @MainActor
    func testInstallationTurnsBoostOffAndPreservesSavedPreferences() throws {
        let suite = "SunBright.UpdateModelTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = PreferencesStore(defaults: defaults)
        let settings = SunBrightSettings(
            multiplier: 1.8,
            apps: [AppRule(bundleIdentifier: "com.example.editor", name: "Editor")],
            schedule: DailySchedule(isEnabled: true, startMinute: 0, endMinute: 1439)
        )
        try store.save(settings)
        let service = FakeUpdateService()
        let updates = makeModel(service)
        let app = AppModel(store: store, updates: updates)
        updates.start()
        app.mode = .on
        service.willInstallUpdate?()
        XCTAssertEqual(app.mode, .off)
        XCTAssertFalse(app.isBoosting)
        XCTAssertEqual(app.settings, settings)
        let relaunchedApp = AppModel(store: store)
        XCTAssertEqual(relaunchedApp.mode, .off)
        XCTAssertEqual(relaunchedApp.settings, settings)
    }

    @MainActor
    private func makeModel(_ service: FakeUpdateService) -> UpdateModel {
        UpdateModel(
            configuration: UpdateConfiguration(
                bundleURL: URL(fileURLWithPath: "/Applications/SunBright.app"),
                feedURL: "https://example.com/appcast.xml", publicKey: publicKey
            ),
            makeService: { service }
        )
    }
}

@MainActor
private final class FakeUpdateService: AppUpdateService {
    let available = CurrentValueSubject<Bool, Never>(true)
    var canCheckForUpdates: AnyPublisher<Bool, Never> { available.eraseToAnyPublisher() }
    var willInstallUpdate: (() -> Void)?
    var startCount = 0
    var checkCount = 0
    var failStartup = false

    func start() throws {
        startCount += 1
        if failStartup { throw NSError(domain: "UpdateModelTests", code: 1) }
    }
    func checkForUpdates() { checkCount += 1 }
}
