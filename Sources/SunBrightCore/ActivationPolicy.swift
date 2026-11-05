import Foundation

public struct ActivationContext {
    public var hasHDRDisplay: Bool
    public var isSuspended: Bool
    public var isOnBattery: Bool
    public var frontmostBundleIdentifier: String?
    public var minuteOfDay: Int
    public var manualHDRPause: Bool
    public var runningBundleIdentifiers: Set<String>

    public init(
        hasHDRDisplay: Bool,
        isSuspended: Bool = false,
        isOnBattery: Bool = false,
        frontmostBundleIdentifier: String? = nil,
        minuteOfDay: Int,
        manualHDRPause: Bool = false,
        runningBundleIdentifiers: Set<String> = []
    ) {
        self.hasHDRDisplay = hasHDRDisplay
        self.isSuspended = isSuspended
        self.isOnBattery = isOnBattery
        self.frontmostBundleIdentifier = frontmostBundleIdentifier
        self.minuteOfDay = minuteOfDay
        self.manualHDRPause = manualHDRPause
        self.runningBundleIdentifiers = runningBundleIdentifiers
    }
}

public enum ActivationReason: Equatable {
    case off
    case noHDRDisplay
    case suspended
    case battery
    case hdrPlayback
    case mediaApp(String)
    case standardBrightness
    case manual
    case app(String)
    case schedule
    case waiting

    public var shouldBoost: Bool {
        switch self {
        case .manual, .app, .schedule: return true
        default: return false
        }
    }

    public var description: String {
        switch self {
        case .off: return "Brightness boost is off"
        case .noHDRDisplay: return "No HDR-capable display connected"
        case .suspended: return "Paused while your session is inactive"
        case .battery: return "Paused on battery power"
        case .hdrPlayback: return "Paused for HDR playback"
        case .mediaApp(let name): return "Paused while \(name) is running"
        case .standardBrightness: return "Raise the nits target above the SDR reference to boost"
        case .manual: return "Brightness boost is on"
        case .app(let name): return "Active for \(name)"
        case .schedule: return "Daily schedule is active"
        case .waiting: return "Waiting for an app or scheduled time"
        }
    }
}

public enum ActivationPolicy {
    public static func evaluate(
        mode: ActivationMode,
        settings: SunBrightSettings,
        context: ActivationContext
    ) -> ActivationReason {
        guard mode != .off else { return .off }
        guard !context.isSuspended else { return .suspended }
        guard context.hasHDRDisplay else { return .noHDRDisplay }
        guard !(settings.onlyOnPowerAdapter && context.isOnBattery) else { return .battery }
        if context.manualHDRPause { return .hdrPlayback }
        if settings.pauseInMediaApps,
           let app = settings.hdrPauseApps.first(where: {
               $0.isEnabled && context.runningBundleIdentifiers.contains($0.bundleIdentifier)
           }) { return .mediaApp(app.name) }
        guard settings.multiplier > 1 else { return .standardBrightness }
        if mode == .on { return .manual }

        if let app = settings.apps.first(where: {
            $0.isEnabled && $0.bundleIdentifier == context.frontmostBundleIdentifier
        }) {
            return .app(app.name)
        }
        if settings.schedule.contains(minuteOfDay: context.minuteOfDay) { return .schedule }
        return .waiting
    }
}
