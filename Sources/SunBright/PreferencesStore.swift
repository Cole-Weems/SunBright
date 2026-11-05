import Foundation
import SunBrightCore

struct PreferencesStore {
    private let defaults: UserDefaults
    private let key = "SunBright.settings.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> (settings: SunBrightSettings, warning: String?) {
        guard let data = defaults.data(forKey: key) else { return (SunBrightSettings(), nil) }
        do {
            return (try JSONDecoder().decode(SunBrightSettings.self, from: data), nil)
        } catch {
            return (SunBrightSettings(), "Saved settings could not be read. Defaults are in use.")
        }
    }

    func save(_ settings: SunBrightSettings) throws {
        defaults.set(try JSONEncoder().encode(settings), forKey: key)
    }
}
