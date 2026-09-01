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
}
