import Foundation
import SwiftData

/// Links one `Exercise` to one `Workout`, holding the sets performed for that exercise that day.
@Model
public final class ExerciseLog {
    public var exercise: Exercise?
    public var workout: Workout?

    @Relationship(deleteRule: .cascade, inverse: \SetLog.exerciseLog)
    public var sets: [SetLog]? = []

    public init(exercise: Exercise, workout: Workout) {
        self.exercise = exercise
        self.workout = workout
    }
}
