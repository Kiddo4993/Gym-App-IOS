import Foundation
import SwiftData

/// Populates the pre-loaded exercise library the first time the app launches. Safe to call on
/// every launch — it's a no-op once any `Exercise` exists.
public enum SeedData {
    public static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Exercise>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }

        var nextOrder: [DayType: Int] = [.push: 0, .pull: 0, .legs: 0, .rest: 0]

        func add(_ name: String, _ muscleGroup: String, _ day: DayType) {
            let order = nextOrder[day, default: 0]
            nextOrder[day] = order + 1
            context.insert(Exercise(name: name, muscleGroup: muscleGroup, dayType: day, sortOrder: order))
        }

        // Push
        add("Incline Bench Press", "Chest", .push)
        add("Pec Deck", "Chest", .push)
        add("Dumbbell Shoulder Press", "Shoulders", .push)
        add("Seated Lateral Raises", "Shoulders", .push)
        add("Rear Delt Flyes", "Shoulders", .push)
        add("Tricep Pushdown", "Triceps", .push)
        add("Overhead Rope Tricep Extension", "Triceps", .push)

        // Pull
        add("Lat Pulldown", "Back", .pull)
        add("Single-Arm Machine Row", "Back", .pull)
        add("Preacher Curls", "Biceps", .pull)
        add("Hammer Curls", "Biceps", .pull)

        // Legs
        add("Leg Press", "Legs", .legs)
        add("Romanian Deadlift", "Hamstrings", .legs)
        add("Leg Curl", "Hamstrings", .legs)
        add("Leg Extension", "Quads", .legs)
        add("Hip Abductors", "Glutes", .legs)

        // Rest has no exercises by design.

        try? context.save()
    }
}
