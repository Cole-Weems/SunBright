import Combine
import Foundation
import ServiceManagement

@MainActor
protocol LoginItemService {
    var status: SMAppService.Status { get }
    var isAvailable: Bool { get }
    func register() async throws
    func unregister() async throws
}

@MainActor
private struct SystemLoginItemService: LoginItemService {
    var status: SMAppService.Status { SMAppService.mainApp.status }
    var isAvailable: Bool {
        Bundle.main.bundleURL.pathExtension == "app" && Bundle.main.bundleIdentifier != nil
    }

    func register() async throws { try SMAppService.mainApp.register() }
    func unregister() async throws { try await SMAppService.mainApp.unregister() }
}

/// macOS owns the saved registration. Never persist a second preference or
/// re-register during launch/refresh, which could undo a user's system change.
@MainActor
final class LoginItemModel: ObservableObject {
    @Published private(set) var status: SMAppService.Status
    @Published private(set) var isUpdating = false
    @Published private(set) var errorMessage: String?
    let isAvailable: Bool
    private let service: any LoginItemService

    var isEnabled: Bool { status == .enabled }

    var statusMessage: String {
        guard isAvailable else {
            return "Launch at Login requires SunBright.app. Build or download the app, move it to Applications, and open that copy."
        }
        switch status {
        case .notRegistered:
            return "SunBright will not start when you sign in."
        case .enabled:
            return "SunBright will start in the menu bar when you sign in, with brightness boost Off."
        case .requiresApproval:
            return "Approval required. SunBright will not start at login until you allow it in System Settings → General → Login Items."
        case .notFound:
            return "macOS could not find SunBright’s login item. Quit, move SunBright.app to Applications, reopen it, and try enabling Launch at Login again."
        @unknown default:
            return "macOS reported an unknown login item state. Check System Settings → General → Login Items."
        }
    }

    init(service: (any LoginItemService)? = nil) {
        let service = service ?? SystemLoginItemService()
        self.service = service
        status = service.status
        isAvailable = service.isAvailable
    }

    func refresh() {
        let actualStatus = service.status
        if status != actualStatus {
            status = actualStatus
            if !isUpdating { errorMessage = nil }
        }
    }

    func setEnabled(_ enabled: Bool) async {
        guard !isUpdating else { return }
        refresh()
        errorMessage = nil
        guard isAvailable else {
            errorMessage = statusMessage
            return
        }
        // A pending request needs system approval, not another registration.
        if enabled && (status == .enabled || status == .requiresApproval) { return }
        if !enabled && status == .notRegistered { return }

        isUpdating = true
        defer {
            refresh()
            isUpdating = false
        }
        do {
            if enabled { try await service.register() }
            else { try await service.unregister() }
        } catch {
            let action = enabled ? "enable" : "disable"
            errorMessage = "Could not \(action) Launch at Login: \(error.localizedDescription) Check System Settings → General → Login Items, then try again from SunBright.app in Applications."
        }
    }

    func openSystemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
