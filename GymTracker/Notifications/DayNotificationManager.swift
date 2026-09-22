import Foundation
import UserNotifications
import GymTrackerKit

/// Reminds the user each morning at 8:00 AM which day is up next in their Push/Pull/Legs/Rest
/// split. A local notification's content is fixed the moment it's scheduled — it can't be
/// recomputed at delivery time — so instead of one far-future schedule, the pending request is
/// replaced (same identifier, freshly computed content) any time the rotation could have
/// changed: app launch/foreground, a session being logged, or a manual day override. The
/// request itself repeats daily at 8:00 AM, so it keeps firing with the last known content even
/// if the user doesn't reopen the app for a few days.
enum DayNotificationManager {
    static let identifier = "com.gymtracker.morningDayReminder"
    static let enabledStorageKey = "morningReminderEnabled"

    static var isEnabled: Bool {
        (UserDefaults.standard.object(forKey: enabledStorageKey) as? Bool) ?? true
    }

    /// Prompts for notification permission the first time this runs; a no-op after that.
    static func requestAuthorizationIfNeeded() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                guard granted else { return }
                refresh()
            }
        }
    }

    /// Cancels the pending reminder and, if enabled and permitted, schedules a fresh one that
    /// repeats daily at 8:00 AM with content reflecting the current "next up" day.
    static func refresh() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        guard isEnabled else { return }

        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }

            let snapshot = DashboardSnapshot.load(from: SharedModelContainer.make())
            let day = snapshot.nextDayType

            let content = UNMutableNotificationContent()
            content.title = "\(day.displayName) day"
            content.body = body(for: day)
            content.sound = .default

            var dateComponents = DateComponents()
            dateComponents.hour = 8
            dateComponents.minute = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            center.add(request)
        }
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
