import AppKit
import Combine
import SwiftUI

@main
@MainActor
struct SunBrightApp {
    static func main() {
        let application = NSApplication.shared
        let delegate = AppDelegate()
        application.delegate = delegate
        application.setActivationPolicy(.accessory)
        withExtendedLifetime(delegate) { application.run() }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let model = AppModel()
    private var statusItem: NSStatusItem?
    private let popover = NSPopover()
    private var settingsWindow: NSWindow?
    private var subscription: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem = item
        item.button?.target = self
        item.button?.action = #selector(togglePopover)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: MenuBarView(
            model: model,
            openSettings: { [weak self] in self?.showSettings() },
            quit: { NSApp.terminate(nil) }
        ))
        subscription = model.objectWillChange.sink { [weak self] in
            DispatchQueue.main.async { self?.updateStatusItem() }
        }
        model.start()
        updateStatusItem()
    }

    func applicationWillTerminate(_ notification: Notification) {
        model.stop()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    @objc private func togglePopover() {
        guard let button = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    private func showSettings() {
        popover.performClose(nil)
        if settingsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 560, height: 610),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered, defer: false
            )
            window.title = "SunBright Settings"
            window.minSize = NSSize(width: 520, height: 540)
            window.isReleasedWhenClosed = false
            window.contentViewController = NSHostingController(rootView: SettingsView(model: model))
            window.center()
            settingsWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    private func updateStatusItem() {
        guard let button = statusItem?.button else { return }
        let symbol = model.isBoosting ? "sun.max.fill" : "sun.max"
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: "SunBright")
        image?.isTemplate = true
        button.image = image
        button.toolTip = "SunBright · \(model.statusMessage)"
        button.setAccessibilityLabel("SunBright: \(model.statusMessage)")
    }
}
