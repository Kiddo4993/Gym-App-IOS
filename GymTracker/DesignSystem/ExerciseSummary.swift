import Foundation
import SwiftData
import GymTrackerKit

extension Exercise {
    /// The most recent logged session for this exercise, optionally skipping one workout
    /// (the one being logged right now).
    func latestLog(excluding workout: Workout? = nil) -> ExerciseLog? {
        (logs ?? [])
            .filter { $0.workout != nil && $0.workout?.persistentModelID != workout?.persistentModelID }
            .max { ($0.workout?.date ?? .distantPast) < ($1.workout?.date ?? .distantPast) }
    }

    /// "135 lb × 8" for the heaviest set of the latest session, or nil if never logged.
    func lastTopSetText(in unit: WeightUnit, excluding workout: Workout? = nil) -> String? {
        guard let sets = latestLog(excluding: workout)?.sets, !sets.isEmpty,
              let top = sets.max(by: { $0.weight(in: unit) < $1.weight(in: unit) })
        else { return nil }
        return "\(top.weight(in: unit).weightText) \(unit.symbol) × \(top.fullReps)"
    }
}
