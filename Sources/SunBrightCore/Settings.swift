import Foundation

public enum ActivationMode: String, CaseIterable, Identifiable {
    case off, on, automatic

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .off: return "Off"
        case .on: return "On"
        case .automatic: return "Auto"
        }
    }

    /// An explicit toggle leaves Auto; selecting Auto is required to resume it.
    public func toggled(automaticIsActive: Bool) -> ActivationMode {
        switch self {
        case .off: return .on
        case .on: return .off
        case .automatic: return automaticIsActive ? .off : .on
        }
    }
}

public struct AppRule: Codable, Equatable, Identifiable {
    public var bundleIdentifier: String
    public var name: String
    public var isEnabled: Bool
    public var id: String { bundleIdentifier }

    public init(bundleIdentifier: String, name: String, isEnabled: Bool = true) {
        self.bundleIdentifier = bundleIdentifier
        self.name = name
        self.isEnabled = isEnabled
    }
}

public struct DailySchedule: Codable, Equatable {
    public var isEnabled: Bool
    public var startMinute: Int
    public var endMinute: Int

    public init(isEnabled: Bool = false, startMinute: Int = 540, endMinute: Int = 1080) {
        self.isEnabled = isEnabled
        self.startMinute = startMinute
        self.endMinute = endMinute
    }

    /// The end is exclusive. Equal times make an empty window, not an all-day rule.
    public func contains(minuteOfDay minute: Int) -> Bool {
        guard isEnabled, (0..<1440).contains(minute),
              (0..<1440).contains(startMinute), (0..<1440).contains(endMinute),
              startMinute != endMinute else { return false }
        if startMinute < endMinute {
            return minute >= startMinute && minute < endMinute
        }
        return minute >= startMinute || minute < endMinute
    }
}

public struct SunBrightSettings: Codable, Equatable {
    public static let multiplierRange = 1.0...2.0

    public var multiplier: Double
    public var onlyOnPowerAdapter: Bool
    public var apps: [AppRule]
    public var schedule: DailySchedule

    public init(
        multiplier: Double = 1.4,
        onlyOnPowerAdapter: Bool = false,
        apps: [AppRule] = [],
        schedule: DailySchedule = DailySchedule()
    ) {
        self.multiplier = multiplier
        self.onlyOnPowerAdapter = onlyOnPowerAdapter
        self.apps = apps
        self.schedule = schedule
        normalize()
    }

    /// User preferences are untrusted input, including previously saved versions.
    public mutating func normalize() {
        multiplier = multiplier.isFinite ? min(max(multiplier, 1), 2) : 1.4
        schedule.startMinute = min(max(schedule.startMinute, 0), 1439)
        schedule.endMinute = min(max(schedule.endMinute, 0), 1439)
        var identifiers = Set<String>()
        apps = apps.compactMap { rule in
            let identifier = rule.bundleIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !identifier.isEmpty, identifiers.insert(identifier).inserted else { return nil }
            var result = rule
            result.bundleIdentifier = identifier
            if result.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                result.name = identifier
            }
            return result
        }
    }

    private enum CodingKeys: String, CodingKey {
        case multiplier, onlyOnPowerAdapter, apps, schedule
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        multiplier = try values.decodeIfPresent(Double.self, forKey: .multiplier) ?? 1.4
        onlyOnPowerAdapter = try values.decodeIfPresent(Bool.self, forKey: .onlyOnPowerAdapter) ?? false
        apps = try values.decodeIfPresent([AppRule].self, forKey: .apps) ?? []
        schedule = try values.decodeIfPresent(DailySchedule.self, forKey: .schedule) ?? DailySchedule()
        normalize()
    }
}
