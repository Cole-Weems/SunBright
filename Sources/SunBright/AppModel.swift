import AppKit
import Combine
import IOKit.ps
import SunBrightCore
import UniformTypeIdentifiers

@MainActor
final class AppModel: ObservableObject {
    @Published var settings: SunBrightSettings {
        didSet {
            do {
                try store.save(settings)
                preferencesWarning = nil
            } catch {
                preferencesWarning = "Your settings could not be saved."
            }
            renderingError = nil
            refresh()
        }
    }
    // Activation is intentionally never persisted. Every launch starts off.
    @Published var mode: ActivationMode = .off {
        didSet {
            renderingError = nil
            refresh()
        }
    }
    @Published private(set) var reason: ActivationReason = .off
    @Published private(set) var displays: [DisplayStatus] = []
    @Published private(set) var renderingError: String?
    @Published private(set) var preferencesWarning: String?
    @Published private(set) var shortcutAvailable = true
    @Published private(set) var frontmostAppName = "No app selected"
    @Published var appSelectionError: String?
    @Published var manualHDRPause = false { didSet { refresh() } }

    private let store: PreferencesStore
    private let renderer = OverlayRenderer()
    private let shortcut = GlobalShortcut()
    private var observers: [(NotificationCenter, NSObjectProtocol)] = []
    private var timer: Timer?
    private var frontmostBundleIdentifier: String?
    private var systemSleeping = false
    private var displaysSleeping = false
    private var sessionInactive = false

    var isBoosting: Bool { displays.contains { $0.effectiveMultiplier > 1.01 } }
    var hasHDRDisplay: Bool { displays.contains(where: \.supportsHDR) }
    var statusMessage: String {
        if let renderingError { return renderingError }
        if reason.shouldBoost && !isBoosting { return "Waiting for available HDR headroom" }
        return reason.description
    }

    init() {
        let store = PreferencesStore()
        let loaded = store.load()
        self.store = store
        settings = loaded.settings
        preferencesWarning = loaded.warning
    }

    func start() {
        updateFrontmostApp(NSWorkspace.shared.frontmostApplication)
        shortcutAvailable = shortcut.register { [weak self] in self?.toggle() }
        let workspace = NSWorkspace.shared.notificationCenter
        observe(workspace, NSWorkspace.didActivateApplicationNotification) { model, notification in
            model.updateFrontmostApp(notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication)
            model.refresh()
        }
        observe(workspace, NSWorkspace.willSleepNotification) { model, _ in
            model.systemSleeping = true
            model.refresh()
        }
        observe(workspace, NSWorkspace.didWakeNotification) { model, _ in
            model.systemSleeping = false
            model.refresh()
        }
        observe(workspace, NSWorkspace.screensDidSleepNotification) { model, _ in
            model.displaysSleeping = true
            model.refresh()
        }
        observe(workspace, NSWorkspace.screensDidWakeNotification) { model, _ in
            model.displaysSleeping = false
            model.refresh()
        }
        observe(workspace, NSWorkspace.sessionDidResignActiveNotification) { model, _ in
            model.sessionInactive = true
            model.refresh()
        }
        observe(workspace, NSWorkspace.sessionDidBecomeActiveNotification) { model, _ in
            model.sessionInactive = false
            model.refresh()
        }
        observe(.default, NSApplication.didChangeScreenParametersNotification) { model, _ in
            model.renderer.stop()
            model.renderingError = nil
            model.refresh()
        }
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        self.timer = timer
        RunLoop.main.add(timer, forMode: .common)
        refresh()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        observers.forEach { center, observer in center.removeObserver(observer) }
        observers.removeAll()
        shortcut.unregister()
        renderer.stop()
    }

    func toggle() {
        // A manual action overrides automation until Auto is selected again.
        mode = mode.toggled(automaticIsActive: reason.shouldBoost)
    }

    func retryRenderer() {
        renderer.stop()
        renderingError = nil
        refresh()
    }

    func chooseApps() { chooseApps(forHDRPause: false) }
    func chooseHDRApps() { chooseApps(forHDRPause: true) }

    private func chooseApps(forHDRPause: Bool) {
        let panel = NSOpenPanel()
        panel.title = "Choose apps for SunBright"
        panel.prompt = "Add Apps"
        panel.allowedContentTypes = [.application]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        guard panel.runModal() == .OK else { return }
        var updated = settings
        var rules = forHDRPause ? updated.hdrPauseApps : updated.apps
        var rejected: [String] = []
        for url in panel.urls {
            guard let bundle = Bundle(url: url), let identifier = bundle.bundleIdentifier,
                  identifier != Bundle.main.bundleIdentifier else {
                rejected.append(url.deletingPathExtension().lastPathComponent)
                continue
            }
            guard !rules.contains(where: { $0.bundleIdentifier == identifier }) else { continue }
            let name = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
                ?? url.deletingPathExtension().lastPathComponent
            rules.append(AppRule(bundleIdentifier: identifier, name: name))
        }
        rules.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        if forHDRPause { updated.hdrPauseApps = rules } else { updated.apps = rules }
        settings = updated
        appSelectionError = rejected.isEmpty ? nil : "Could not add: \(rejected.joined(separator: ", ")). Choose a different app."
    }

    func removeApp(_ identifier: String) {
        settings.apps.removeAll { $0.bundleIdentifier == identifier }
    }

    private func updateFrontmostApp(_ app: NSRunningApplication?) {
        guard let app, let identifier = app.bundleIdentifier,
              identifier != Bundle.main.bundleIdentifier else { return }
        frontmostBundleIdentifier = identifier
        frontmostAppName = app.localizedName ?? identifier
    }

    private func refresh() {
        let components = Calendar.current.dateComponents([.hour, .minute], from: Date())
        let context = ActivationContext(
            hasHDRDisplay: NSScreen.screens.contains(where: \.supportsBrightnessBoost),
            isSuspended: systemSleeping || displaysSleeping || sessionInactive,
            isOnBattery: Self.isOnBattery(),
            frontmostBundleIdentifier: frontmostBundleIdentifier,
            minuteOfDay: (components.hour ?? 0) * 60 + (components.minute ?? 0),
            manualHDRPause: manualHDRPause,
            runningBundleIdentifiers: Set(NSWorkspace.shared.runningApplications.compactMap {
                $0.isTerminated ? nil : $0.bundleIdentifier
            })
        )
        reason = ActivationPolicy.evaluate(mode: mode, settings: settings, context: context)
        do {
            displays = try renderer.update(
                enabled: reason.shouldBoost && renderingError == nil,
                multiplier: settings.multiplier
            )
        } catch {
            renderingError = error.localizedDescription
            // Refresh the list after the renderer has removed all windows.
            displays = (try? renderer.update(enabled: false, multiplier: 1)) ?? []
        }
    }

    private func observe(
        _ center: NotificationCenter,
        _ name: Notification.Name,
        action: @escaping @MainActor (AppModel, Notification) -> Void
    ) {
        let observer = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] notification in
            MainActor.assumeIsolated {
                guard let self else { return }
                action(self, notification)
            }
        }
        observers.append((center, observer))
    }

    private static func isOnBattery() -> Bool {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let source = IOPSGetProvidingPowerSourceType(info)?.takeUnretainedValue() else { return false }
        return source as String == kIOPSBatteryPowerValue
    }
}
