import AppKit
import Metal
import QuartzCore

extension NSScreen {
    var displayID: CGDirectDisplayID? {
        (deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
    }

    var supportsBrightnessBoost: Bool {
        guard let displayID, CGDisplayMirrorsDisplay(displayID) == kCGNullDirectDisplay else { return false }
        return maximumPotentialExtendedDynamicRangeColorComponentValue > 1.01
    }
}

struct DisplayStatus: Identifiable {
    let id: CGDirectDisplayID
    let name: String
    let supportsHDR: Bool
    let potentialHeadroom: Double
    var effectiveMultiplier: Double = 1
}

/// Only owns windows. No display configuration, gamma, brightness, or profile APIs.
@MainActor
final class OverlayRenderer {
    private var overlays: [CGDirectDisplayID: DisplayOverlay] = [:]
    private var drawTimer: Timer?
    private var requestedMultiplier = 1.0
    private var drawingFailure: Error?

    func update(enabled: Bool, multiplier: Double) throws -> [DisplayStatus] {
        let screens = NSScreen.screens
        let wanted = Set(enabled ? screens.filter(\.supportsBrightnessBoost).compactMap(\.displayID) : [])
        for id in Array(overlays.keys) where !wanted.contains(id) {
            overlays.removeValue(forKey: id)?.close()
        }
        if overlays.isEmpty {
            drawTimer?.invalidate()
            drawTimer = nil
        }
        if !enabled { drawingFailure = nil }
        if let drawingFailure {
            stop()
            throw drawingFailure
        }
        requestedMultiplier = multiplier

        do {
            let result: [DisplayStatus] = try screens.compactMap { screen in
                guard let id = screen.displayID else { return nil }
                var status = DisplayStatus(
                    id: id,
                    name: screen.localizedName,
                    supportsHDR: screen.supportsBrightnessBoost,
                    potentialHeadroom: Double(screen.maximumPotentialExtendedDynamicRangeColorComponentValue)
                )
                guard wanted.contains(id) else { return status }
                if overlays[id] == nil {
                    overlays[id] = try DisplayOverlay(screen: screen)
                }
                overlays[id]?.update(screen: screen)
                status.effectiveMultiplier = try overlays[id]?.render(requestedMultiplier: multiplier) ?? 1
                return status
            }
            if !overlays.isEmpty && drawTimer == nil {
                // Re-present at a low frame rate: WindowServer does not reliably
                // retain a one-shot cross-window multiply composition.
                let timer = Timer(timeInterval: 0.2, repeats: true) { [weak self] _ in
                    MainActor.assumeIsolated { self?.redraw() }
                }
                drawTimer = timer
                RunLoop.main.add(timer, forMode: .common)
            }
            return result
        } catch {
            stop()
            throw error
        }
    }

    func stop() {
        drawTimer?.invalidate()
        drawTimer = nil
        overlays.values.forEach { $0.close() }
        overlays.removeAll()
        drawingFailure = nil
    }

    private func redraw() {
        do {
            for overlay in overlays.values {
                _ = try overlay.render(requestedMultiplier: requestedMultiplier)
            }
        } catch {
            stop()
            // The next status refresh reports this error and offers a retry.
            drawingFailure = error
        }
    }
}

private enum RenderingError: LocalizedError {
    case metalUnavailable
    case surfaceUnavailable

    var errorDescription: String? {
        switch self {
        case .metalUnavailable: return "Metal is unavailable. SunBright has removed its overlays."
        case .surfaceUnavailable: return "The HDR surface is unavailable. SunBright has removed its overlays."
        }
    }
}

@MainActor
private final class OverlayPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    init(frame: NSRect, surface: MetalSurface, trigger: Bool = false) {
        super.init(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        animationBehavior = .none
        sharingType = .none
        level = NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue - (trigger ? 2 : 1))
        // Treat both surfaces as system overlays, rather than auxiliary windows
        // belonging to a particular full-screen app during a Space swipe.
        collectionBehavior = [.canJoinAllSpaces, .canJoinAllApplications, .stationary, .ignoresCycle]
        let view = NSView(frame: NSRect(origin: .zero, size: frame.size))
        view.wantsLayer = true
        view.layer = surface.layer
        contentView = view
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}

@MainActor
private final class DisplayOverlay {
    private var screen: NSScreen
    private let triggerSurface: MetalSurface
    private let boostSurface: MetalSurface
    private let trigger: OverlayPanel
    private let boost: OverlayPanel

    init(screen: NSScreen) throws {
        guard let device = MTLCreateSystemDefaultDevice(), let queue = device.makeCommandQueue() else {
            throw RenderingError.metalUnavailable
        }
        self.screen = screen
        let scale = screen.backingScaleFactor
        let pixel = 1 / scale
        let triggerSurface = MetalSurface(device: device, queue: queue, scale: scale, multiply: false)
        let boostSurface = MetalSurface(device: device, queue: queue, scale: scale, multiply: true)
        self.triggerSurface = triggerSurface
        self.boostSurface = boostSurface
        // One physical pixel in the corner opts the display into EDR. It may be
        // visible on a rectangular display; a fully transparent trigger cannot
        // reliably request HDR headroom from WindowServer.
        let trigger = OverlayPanel(
            frame: NSRect(x: screen.frame.minX, y: screen.frame.maxY - pixel, width: pixel, height: pixel),
            surface: triggerSurface, trigger: true
        )
        let boost = OverlayPanel(frame: screen.frame, surface: boostSurface)
        self.trigger = trigger
        self.boost = boost
        trigger.orderFrontRegardless()
        boost.orderFrontRegardless()
    }

    func update(screen: NSScreen) {
        // NSScreen instances and geometry can change without the display going
        // away. Keep the EDR trigger and multiply surfaces alive across refreshes.
        self.screen = screen
        let scale = screen.backingScaleFactor
        let pixel = 1 / scale
        let triggerFrame = NSRect(x: screen.frame.minX, y: screen.frame.maxY - pixel,
                                  width: pixel, height: pixel)
        if trigger.frame != triggerFrame { trigger.setFrame(triggerFrame, display: false) }
        if boost.frame != screen.frame { boost.setFrame(screen.frame, display: false) }
        triggerSurface.layer.contentsScale = scale
        boostSurface.layer.contentsScale = scale
    }

    func render(requestedMultiplier: Double) throws -> Double {
        let potential = Double(screen.maximumPotentialExtendedDynamicRangeColorComponentValue)
        guard triggerSurface.present(value: min(potential, max(2, requestedMultiplier))) else { throw RenderingError.surfaceUnavailable }
        let current = Double(screen.maximumExtendedDynamicRangeColorComponentValue)
        let multiplier = max(1, min(requestedMultiplier, current, potential))
        guard boostSurface.present(value: multiplier) else { throw RenderingError.surfaceUnavailable }
        return multiplier
    }

    func close() {
        // Stop multiplying before releasing the EDR trigger.
        boost.orderOut(nil)
        boost.close()
        trigger.orderOut(nil)
        trigger.close()
    }
}

@MainActor
private final class MetalSurface {
    let layer = CAMetalLayer()
    private let queue: MTLCommandQueue
    private var hasPresented = false

    init(device: MTLDevice, queue: MTLCommandQueue, scale: CGFloat, multiply: Bool) {
        self.queue = queue
        layer.device = device
        layer.pixelFormat = .rgba16Float
        layer.colorspace = CGColorSpace(name: CGColorSpace.extendedLinearSRGB)
        layer.wantsExtendedDynamicRangeContent = true
        layer.contentsScale = scale
        // Compositing must retain the content behind the window.
        layer.isOpaque = false
        // Keep new surfaces transparent until their first GPU frame completes.
        layer.opacity = 0
        layer.framebufferOnly = true
        layer.maximumDrawableCount = 2
        layer.allowsNextDrawableTimeout = true
        if multiply { layer.compositingFilter = "multiply" }
    }

    @discardableResult
    func present(value: Double) -> Bool {
        let size = CGSize(width: max(1, layer.bounds.width * layer.contentsScale),
                          height: max(1, layer.bounds.height * layer.contentsScale))
        if layer.drawableSize != size { layer.drawableSize = size }
        guard let drawable = layer.nextDrawable(), let command = queue.makeCommandBuffer() else { return false }
        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = drawable.texture
        pass.colorAttachments[0].loadAction = .clear
        pass.colorAttachments[0].storeAction = .store
        pass.colorAttachments[0].clearColor = MTLClearColor(red: value, green: value, blue: value, alpha: 1)
        guard let encoder = command.makeRenderCommandEncoder(descriptor: pass) else { return false }
        encoder.endEncoding()
        command.present(drawable)
        command.commit()
        if !hasPresented {
            command.waitUntilCompleted()
            guard command.status == .completed else { return false }
            hasPresented = true
            layer.opacity = 1
        }
        return true
    }
}
