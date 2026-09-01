import Foundation

/// A weight unit. Each `SetLog` remembers the unit it was entered in, so history always
/// displays exactly what was typed, converted on the fly when the user's preference differs.
public enum WeightUnit: String, Codable, CaseIterable, Identifiable, Sendable {
    case lb, kg

    public var id: String { rawValue }
    public var symbol: String { rawValue }

    private static let poundsPerKilogram = 0.45359237

    public func convert(_ value: Double, to target: WeightUnit) -> Double {
        guard self != target else { return value }
        return self == .lb ? value * Self.poundsPerKilogram : value / Self.poundsPerKilogram
    }
}
