import Foundation
import SwiftData
import GymTrackerKit

/// An in-memory, seeded container for SwiftUI previews — never touches the real App Group store.
@MainActor
enum PreviewSupport {
    static let container: ModelContainer = {
        let schema = Schema([Exercise.self, Workout.self, ExerciseLog.self, SetLog.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        SeedData.seedIfNeeded(context: container.mainContext)
        return container
    }()

    /// Like `container`, plus about four weeks of logged sessions with steadily rising weights,
    /// so History, Progress, and Calendar have something to show.
    static let demoContainer: ModelContainer = {
        let schema = Schema([Exercise.self, Workout.self, ExerciseLog.self, SetLog.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext
        SeedData.seedIfNeeded(context: context)

        let exercises = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let skippedDaysAgo: Set<Int> = [11, 19, 20]
        var day = DayType.push
        var sessionsByExercise: [String: Int] = [:]

        // Oldest first, ending yesterday, so "next up" and the streak look like a real week.
        // `-demoSession` also starts today's workout with its first two exercises logged.
        let includesToday = ProcessInfo.processInfo.arguments.contains("-demoSession")
        for daysAgo in stride(from: 28, through: includesToday ? 0 : 1, by: -1) where !skippedDaysAgo.contains(daysAgo) {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)?
                .addingTimeInterval(daysAgo == 0 ? 60 : 18 * 3600) else { continue }
            let workout = Workout(date: date, dayType: day)
            context.insert(workout)

            let dayExercises = exercises.filter { $0.dayType == day }.sorted { $0.sortOrder < $1.sortOrder }
            for exercise in daysAgo == 0 ? Array(dayExercises.prefix(2)) : dayExercises {
                let session = sessionsByExercise[exercise.name, default: 0]
                sessionsByExercise[exercise.name] = session + 1
                let base = Double(30 + (exercise.name.count % 8) * 15)
                let log = ExerciseLog(exercise: exercise, workout: workout)
                context.insert(log)
                for setNumber in [1, 2] {
                    let weight = base + Double(session) * 5 - Double(setNumber - 1) * 10
                    let set = SetLog(
                        setNumber: setNumber,
                        weightValue: weight,
                        unit: .lb,
                        fullReps: 8 + (session + setNumber) % 4,
                        partialReps: 2 + setNumber % 2
                    )
                    set.exerciseLog = log
                    context.insert(set)
                }
            }
            day = day.next
        }
        try? context.save()
        return container
    }()
}

#if DEBUG
/// Launch arguments for screenshots and manual testing in the Simulator:
/// `-demoData` uses `PreviewSupport.demoContainer` (and skips the notification prompt; add
/// `-demoSession` for a workout in progress), and
/// `-tab <today|history|progress|calendar|settings>` opens on that tab.
enum DebugLaunch {
    static var usesDemoData: Bool { ProcessInfo.processInfo.arguments.contains("-demoData") }
    static var initialTab: String? { UserDefaults.standard.string(forKey: "tab") }
}
#endif
