import Foundation
import SwiftData

/// Builds the single `ModelContainer` shared by the app and the widget extension, backing it
/// with a store inside the App Group container so both processes read/write the same data.
public enum SharedModelContainer {
    /// Must match the App Group configured in Signing & Capabilities for BOTH the app target
    /// and the widget extension target. Change this (and `project.yml`) to your own reverse-DNS
    /// identifier before shipping.
    public static let appGroupID = "group.com.gymtracker.shared"

    public static var schema: Schema {
        Schema([Exercise.self, Workout.self, ExerciseLog.self, SetLog.self])
    }

    public static func make() -> ModelContainer {
        let config: ModelConfiguration
        if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            let storeURL = groupURL.appendingPathComponent("GymTracker.sqlite")
            config = ModelConfiguration(schema: schema, url: storeURL)
        } else {
            // App Group not set up yet (e.g. a fresh checkout before Signing & Capabilities has
            // been configured in Xcode). Falling back keeps the app usable; the widget just
            // won't see data until the App Group is wired up.
            config = ModelConfiguration(schema: schema)
        }

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}
