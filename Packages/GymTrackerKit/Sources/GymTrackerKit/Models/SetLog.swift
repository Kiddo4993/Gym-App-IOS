import Foundation
import SwiftData

/// One working set: weight, full reps to failure, and the partial reps taken immediately after.
/// Partials are always stored separately and never summed into `fullReps`.
@Model
public final class SetLog {
    public var setNumber: Int
    public var weightValue: Double
    public var weightUnitRaw: String
    public var fullReps: Int
    public var partialReps: Int
    public var exerciseLog: ExerciseLog?

    public init(
        setNumber: Int,
        weightValue: Double,
        unit: WeightUnit,
        fullReps: Int,
        partialReps: Int
    ) {
        self.setNumber = setNumber
        self.weightValue = weightValue
        self.weightUnitRaw = unit.rawValue
        self.fullReps = fullReps
        self.partialReps = partialReps
    }

    public var weightUnit: WeightUnit {
        get { WeightUnit(rawValue: weightUnitRaw) ?? .lb }
        set { weightUnitRaw = newValue.rawValue }
    }

    /// The weight this set was logged with, converted into `target` if needed.
    public func weight(in target: WeightUnit) -> Double {
        weightUnit.convert(weightValue, to: target)
    }
}
