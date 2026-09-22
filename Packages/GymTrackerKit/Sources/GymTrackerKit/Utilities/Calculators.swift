import Foundation

/// Decides which day type is "up next", cycling Push → Pull → Legs → Rest → Push …
public enum NextDayCalculator {
    /// A manual override (set via `DayOverrideStore`) always wins, so users can correct or
    /// kick off the rotation without needing to log a workout first.
    public static func nextDayType(afterLast workout: Workout?) -> DayType {
        if let override = DayOverrideStore.current { return override }
        guard let workout else { return .push }
        return workout.dayType.next
    }
}

/// Working-weight and estimated-volume math shared by History, Progress, and the widget.
public enum VolumeCalculator {
    /// Full reps count fully toward volume; partial reps (taken past failure, over a shorter
    /// range of motion) count at half weight-contribution. This keeps partials visible in the
    /// trend without letting them inflate volume as much as a full rep would.
    public static func estimatedVolume(for setLog: SetLog, in unit: WeightUnit) -> Double {
        let weight = setLog.weight(in: unit)
        return weight * Double(setLog.fullReps) + weight * Double(setLog.partialReps) * 0.5
    }

    public static func estimatedVolume(for sets: [SetLog], in unit: WeightUnit) -> Double {
        sets.reduce(0) { $0 + estimatedVolume(for: $1, in: unit) }
    }

    public static func topWeight(for sets: [SetLog], in unit: WeightUnit) -> Double {
        sets.map { $0.weight(in: unit) }.max() ?? 0
    }
}

/// Consecutive-day streak math for the Calendar tab and the widget.
public enum StreakCalculator {
    /// Consecutive calendar days (counting back from today) with a logged `Workout`. Rest days
    /// count as "trained" — logging Rest is still an intentional check-in with the app.
    public static func currentStreak(workouts: [Workout], calendar: Calendar = .current) -> Int {
        let days = Set(workouts.map { calendar.startOfDay(for: $0.date) })
        guard !days.isEmpty else { return 0 }

        var streak = 0
        var cursor = calendar.startOfDay(for: .now)

        // If today hasn't been logged yet, the streak isn't broken until yesterday goes unlogged.
        if !days.contains(cursor) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor) else { return 0 }
            cursor = yesterday
        }

        while days.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }
}
