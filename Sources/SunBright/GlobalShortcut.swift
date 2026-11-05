import Carbon
import Foundation

/// Carbon hot keys work globally without an Accessibility or Input Monitoring grant.
@MainActor
final class GlobalShortcut {
    private var hotKey: EventHotKeyRef?
    private var handler: EventHandlerRef?
    private var action: (() -> Void)?

    func register(action: @escaping () -> Void) -> Bool {
        unregister()
        self.action = action
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let installResult = InstallEventHandler(GetApplicationEventTarget(), { _, event, context in
            guard let context, let event else { return OSStatus(eventNotHandledErr) }
            var identifier = EventHotKeyID()
            let result = GetEventParameter(event, EventParamName(kEventParamDirectObject),
                                           EventParamType(typeEventHotKeyID), nil,
                                           MemoryLayout<EventHotKeyID>.size, nil, &identifier)
            guard result == noErr, identifier.signature == 0x53425254, identifier.id == 1 else {
                return OSStatus(eventNotHandledErr)
            }
            let shortcut = Unmanaged<GlobalShortcut>.fromOpaque(context).takeUnretainedValue()
            // Carbon dispatches application events on the main run loop.
            MainActor.assumeIsolated { shortcut.action?() }
            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), &handler)
        guard installResult == noErr else { return false }
        let identifier = EventHotKeyID(signature: 0x53425254, id: 1) // SBRT
        let result = RegisterEventHotKey(UInt32(kVK_ANSI_B), UInt32(cmdKey | optionKey),
                                         identifier, GetApplicationEventTarget(), 0, &hotKey)
        if result != noErr { unregister() }
        return result == noErr
    }

    func unregister() {
        if let hotKey { UnregisterEventHotKey(hotKey) }
        if let handler { RemoveEventHandler(handler) }
        hotKey = nil
        handler = nil
        action = nil
    }
}
