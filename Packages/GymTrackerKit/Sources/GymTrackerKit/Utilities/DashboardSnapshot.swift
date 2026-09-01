import Foundation
import SwiftData

/// One calendar day's training status, used to render the last-7-days strip.
public struct DayStatus: Sendable, Identifiable {
    public let date: Date
    public let dayType: DayType?
    public var id: Date { date }

    public init(date: Date, dayType: DayType?) {
        self.date = date
        self.dayType = dayType
    }
}

/// A small, cheap-to-compute summary of training state — next day, streak, last week — shared by
/// the app's Today tab and the home screen widget.
public struct DashboardSnapshot: Sendable {
    public let nextDayType: DayType
    public let streak: Int
    public let lastSevenDays: [DayStatus]
    public let lastWorkoutDate: Date?

    public static let empty = DashboardSnapshot(nextDayType: .push, streak: 0, lastSevenDays: [], lastWorkoutDate: nil)

    public init(nextDayType: DayType, streak: Int, lastSevenDays: [DayStatus], lastWorkoutDate: Date?) {
        self.nextDayType = nextDayType
        self.streak = streak
        self.lastSevenDays = lastSevenDays
        self.lastWorkoutDate = lastWorkoutDate
    }

    public static func load(from container: ModelContainer, calendar: Calendar = .current) -> DashboardSnapshot {
        let context = ModelContext(container)
        var descriptor = FetchDescriptor<Workout>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        descriptor.fetchLimit = 60
        let workouts = (try? context.fetch(descriptor)) ?? []

        let next = NextDayCalculator.nextDayType(afterLast: workouts.first)
        let streak = StreakCalculator.currentStreak(workouts: workouts, calendar: calendar)

        var days: [DayStatus] = []
        let today = calendar.startOfDay(for: .now)
        for offset in stride(from: 6, through: 0, by: -1) {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let match = workouts.first { calendar.isDate($0.date, inSameDayAs: day) }
            days.append(DayStatus(date: day, dayType: match?.dayType))
        }

        return DashboardSnapshot(nextDayType: next, streak: streak, lastSevenDays: days, lastWorkoutDate: workouts.first?.date)
    }
}
