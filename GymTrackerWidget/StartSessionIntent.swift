import AppIntents
import WidgetKit
import SwiftData
import GymTrackerKit

/// Starts today's session directly from the widget's button — no need to open the app first.
/// By the time you do open GymTracker, today's `Workout` already exists, so the Today tab skips
/// the picker screen entirely and drops you straight into the exercise list.
struct StartSessionIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Session"
    static var description = IntentDescription("Starts today's workout using the next day in your split.")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult {
        let container = SharedModelContainer.make()
        let context = ModelContext(container)

        var descriptor = FetchDescriptor<Workout>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        descriptor.fetchLimit = 1
        let mostRecent = try? context.fetch(descriptor).first

        let alreadyStartedToday = mostRecent.map { Calendar.current.isDateInToday($0.date) } ?? false
        if !alreadyStartedToday {
            let nextDay = NextDayCalculator.nextDayType(afterLast: mostRecent)
            let workout = Workout(dayType: nextDay)
            context.insert(workout)
            try? context.save()

            // Same follow-up as starting a session in the app: a real workout is logged, so the
            // automatic rotation takes back over, and tomorrow's 8 AM reminder names the new next day.
            DayOverrideStore.current = nil
            await MorningReminder.updateIfScheduled(for: NextDayCalculator.nextDayType(afterLast: workout))
        }

        WidgetCenter.shared.reloadTimelines(ofKind: "GymTrackerWidget")
        return .result()
    }
}
