import Foundation
import UserNotifications

/// The 8:00 AM "which day is up next" reminder. Lives in the shared package so both the app and
/// the widget can keep it current: its text is fixed when it's scheduled, so it has to be replaced
/// whenever a session is logged, including one started from the widget without opening the app.
public enum MorningReminder {
    public static let identifier = "com.gymtracker.morningDayReminder"

    /// A request that repeats daily at 8:00 AM announcing `day`.
    public static func request(for day: DayType) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = "\(day.displayName) day"
        content.body = body(for: day)
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 8
        dateComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        return UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    }

    /// Swaps in `day`'s text, but only if a reminder is already scheduled, so this never turns the
    /// reminder on for someone who switched it off in Settings (that setting lives in the app).
    public static func updateIfScheduled(for day: DayType) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        guard pending.contains(where: { $0.identifier == identifier }) else { return }
        try? await center.add(request(for: day))
    }

    private static func body(for day: DayType) -> String {
        switch day {
        case .push: "Time to train chest, shoulders, and triceps."
        case .pull: "Time to train back and biceps."
        case .legs: "Time to train legs."
        case .rest: "Rest day — recover and come back stronger tomorrow."
        }
    }
}
