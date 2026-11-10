import Foundation

@MainActor
public protocol ReminderPreferencesStore: AnyObject {
    var intervalMinutes: Int { get set }
    var soundEnabled: Bool { get set }
}

@MainActor
public final class UserDefaultsReminderPreferences: ReminderPreferencesStore {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var intervalMinutes: Int {
        get { defaults.object(forKey: "intervalMinutes") as? Int ?? 30 }
        set { defaults.set(newValue, forKey: "intervalMinutes") }
    }

    public var soundEnabled: Bool {
        get { defaults.object(forKey: "soundEnabled") as? Bool ?? false }
        set { defaults.set(newValue, forKey: "soundEnabled") }
    }
}
