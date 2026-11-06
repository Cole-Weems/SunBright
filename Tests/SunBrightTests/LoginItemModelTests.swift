import ServiceManagement
import XCTest
@testable import SunBright

final class LoginItemModelTests: XCTestCase {
    @MainActor
    func testFirstLaunchOnlyReadsRegistrationAndDoesNotEnableIt() {
        let service = FakeLoginItemService()
        let model = LoginItemModel(service: service)
        model.refresh()
        XCTAssertFalse(model.isEnabled)
        XCTAssertEqual(model.status, .notRegistered)
        XCTAssertEqual(service.registerCalls, 0)
        XCTAssertEqual(service.unregisterCalls, 0)
    }

    @MainActor
    func testEnableDisableAndRepeatedRequests() async {
        let service = FakeLoginItemService()
        let model = LoginItemModel(service: service)
        await model.setEnabled(true)
        await model.setEnabled(true)
        XCTAssertTrue(model.isEnabled)
        XCTAssertEqual(service.registerCalls, 1)
        XCTAssertNil(model.errorMessage)

        await model.setEnabled(false)
        await model.setEnabled(false)
        XCTAssertFalse(model.isEnabled)
        XCTAssertEqual(service.unregisterCalls, 1)
        XCTAssertFalse(model.isUpdating)
    }

    @MainActor
    func testRestartAndExternalSystemChangesUseActualStatusWithoutRegistering() {
        let service = FakeLoginItemService()
        service.status = .enabled
        let model = LoginItemModel(service: service)
        XCTAssertTrue(model.isEnabled)

        service.status = .requiresApproval
        model.refresh()
        XCTAssertFalse(model.isEnabled)
        XCTAssertEqual(model.status, .requiresApproval)
        service.status = .notRegistered
        model.refresh()
        XCTAssertFalse(model.isEnabled)
        service.status = .enabled
        model.refresh()
        XCTAssertTrue(model.isEnabled)

        let restarted = LoginItemModel(service: service)
        XCTAssertTrue(restarted.isEnabled)
        XCTAssertEqual(service.registerCalls, 0)
        XCTAssertEqual(service.unregisterCalls, 0)
    }

    @MainActor
    func testApprovalIsNotReportedAsEnabledAndCanBeCancelled() async {
        let service = FakeLoginItemService()
        service.registrationResult = .requiresApproval
        let model = LoginItemModel(service: service)
        await model.setEnabled(true)
        XCTAssertFalse(model.isEnabled)
        XCTAssertEqual(model.status, .requiresApproval)
        XCTAssertTrue(model.statusMessage.contains("Approval required"))
        await model.setEnabled(true)
        XCTAssertEqual(service.registerCalls, 1)
        await model.setEnabled(false)
        XCTAssertEqual(model.status, .notRegistered)
        XCTAssertEqual(service.unregisterCalls, 1)
    }

    @MainActor
    func testFailuresKeepActualStatusAndOfferRecovery() async {
        let service = FakeLoginItemService()
        service.failure = TestFailure.denied
        let model = LoginItemModel(service: service)
        await model.setEnabled(true)
        XCTAssertFalse(model.isEnabled)
        XCTAssertTrue(model.errorMessage?.contains("Could not enable") == true)
        XCTAssertTrue(model.errorMessage?.contains("System Settings") == true)
        XCTAssertFalse(model.isUpdating)

        service.failure = nil
        await model.setEnabled(true)
        XCTAssertTrue(model.isEnabled)
        XCTAssertNil(model.errorMessage)

        service.failure = TestFailure.denied
        await model.setEnabled(false)
        XCTAssertTrue(model.isEnabled)
        XCTAssertTrue(model.errorMessage?.contains("Could not disable") == true)
        XCTAssertFalse(model.isUpdating)

        service.status = .notRegistered
        model.refresh()
        XCTAssertFalse(model.isEnabled)
        XCTAssertNil(model.errorMessage)
    }

    @MainActor
    func testUnbundledRunCannotRegisterAndNotFoundCanBeRetried() async {
        let service = FakeLoginItemService()
        service.isAvailable = false
        let unbundled = LoginItemModel(service: service)
        await unbundled.setEnabled(true)
        XCTAssertEqual(service.registerCalls, 0)
        XCTAssertTrue(unbundled.errorMessage?.contains("SunBright.app") == true)

        service.isAvailable = true
        service.status = .notFound
        let installed = LoginItemModel(service: service)
        XCTAssertTrue(installed.statusMessage.contains("Applications"))
        await installed.setEnabled(true)
        XCTAssertTrue(installed.isEnabled)
        XCTAssertEqual(service.registerCalls, 1)
    }

    @MainActor
    func testRefreshAndConcurrentRequestDuringUnregisterDoNotRegisterAgain() async {
        let service = FakeLoginItemService()
        service.status = .enabled
        service.pauseUnregister = true
        let model = LoginItemModel(service: service)
        let disabling = Task { await model.setEnabled(false) }
        // Yield to the disabling task until its fake async operation suspends.
        while service.unregisterContinuation == nil { await Task.yield() }
        XCTAssertTrue(model.isUpdating)
        model.refresh()
        await model.setEnabled(true)
        XCTAssertEqual(service.registerCalls, 0)
        service.unregisterContinuation?.resume()
        await disabling.value
        XCTAssertFalse(model.isUpdating)
        XCTAssertFalse(model.isEnabled)
        XCTAssertEqual(service.unregisterCalls, 1)
    }
}

@MainActor
private final class FakeLoginItemService: LoginItemService {
    var status: SMAppService.Status = .notRegistered
    var isAvailable = true
    var registrationResult: SMAppService.Status = .enabled
    var registerCalls = 0
    var unregisterCalls = 0
    var failure: Error?
    var pauseUnregister = false
    var unregisterContinuation: CheckedContinuation<Void, Never>?

    func register() async throws {
        registerCalls += 1
        if let failure { throw failure }
        status = registrationResult
    }

    func unregister() async throws {
        unregisterCalls += 1
        if let failure { throw failure }
        if pauseUnregister {
            await withCheckedContinuation { unregisterContinuation = $0 }
        }
        status = .notRegistered
    }
}

private enum TestFailure: LocalizedError {
    case denied
    var errorDescription: String? { "Registration denied for testing." }
}
