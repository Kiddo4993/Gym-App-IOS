import Foundation

/// Lets the user manually set which day is "up next," overriding the automatic
/// Push → Pull → Legs → Rest rotation that `NextDayCalculator` derives from the last logged
/// workout. Stored in the shared App Group so the app, widget, and morning notification all
/// agree. The override is consumed (cleared) the moment a session is started, so the ordinary
/// last-workout-based rotation resumes from there.
public enum DayOverrideStore {
    private static let key = "manualDayOverride"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: SharedModelContainer.appGroupID) ?? .standard
    }

    public static var current: DayType? {
        get {
            guard let raw = defaults.string(forKey: key) else { return nil }
            return DayType(rawValue: raw)
        }
        set {
            if let newValue {
                defaults.set(newValue.rawValue, forKey: key)
            } else {
                defaults.removeObject(forKey: key)
            }
        }
    }
}
