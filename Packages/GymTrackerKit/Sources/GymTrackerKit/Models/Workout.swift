import Foundation
import SwiftData

/// One training session: a date plus the day type that was trained (or Rest, logged with no
/// exercises attached).
@Model
public final class Workout {
    public var date: Date
    public var dayTypeRaw: String

    @Relationship(deleteRule: .cascade, inverse: \ExerciseLog.workout)
    public var exerciseLogs: [ExerciseLog]? = []

    public init(date: Date = .now, dayType: DayType) {
        self.date = date
        self.dayTypeRaw = dayType.rawValue
    }

    public var dayType: DayType {
        get { DayType(rawValue: dayTypeRaw) ?? .rest }
        set { dayTypeRaw = newValue.rawValue }
    }
}
