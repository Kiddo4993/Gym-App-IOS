import Foundation

/// The four-day training cycle the app rotates through: Push → Pull → Legs → Rest → Push …
public enum DayType: String, Codable, CaseIterable, Identifiable, Sendable {
    case push, pull, legs, rest

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .push: "Push"
        case .pull: "Pull"
        case .legs: "Legs"
        case .rest: "Rest"
        }
    }

    public var symbolName: String {
        switch self {
        case .push: "figure.strengthtraining.traditional"
        case .pull: "figure.strengthtraining.functional"
        case .legs: "figure.run"
        case .rest: "moon.zzz.fill"
        }
    }

    /// The day that follows this one in the fixed rotation.
    public var next: DayType {
        switch self {
        case .push: .pull
        case .pull: .legs
        case .legs: .rest
        case .rest: .push
        }
    }
}
