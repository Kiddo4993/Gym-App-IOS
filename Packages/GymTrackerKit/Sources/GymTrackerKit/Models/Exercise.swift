import Foundation
import SwiftData

/// A single movement in the exercise library, scoped to one day type, with a manual sort order
/// the user can reorder from Settings.
@Model
public final class Exercise {
    public var name: String
    public var muscleGroup: String
    public var dayTypeRaw: String
    public var sortOrder: Int
    public var isArchived: Bool

    @Relationship(deleteRule: .cascade, inverse: \ExerciseLog.exercise)
    public var logs: [ExerciseLog]? = []

    public init(
        name: String,
        muscleGroup: String,
        dayType: DayType,
        sortOrder: Int,
        isArchived: Bool = false
    ) {
        self.name = name
        self.muscleGroup = muscleGroup
        self.dayTypeRaw = dayType.rawValue
        self.sortOrder = sortOrder
        self.isArchived = isArchived
    }

    public var dayType: DayType {
        get { DayType(rawValue: dayTypeRaw) ?? .push }
        set { dayTypeRaw = newValue.rawValue }
    }
}
