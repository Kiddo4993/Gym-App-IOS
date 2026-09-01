import SwiftUI

/// A minimal, dark-mode-first palette: near-black surfaces, a single neon accent used sparingly,
/// and a muted per-day-type tint used only as small identifying color, not decoration.
public enum Theme {
    public static let background = Color(red: 0.043, green: 0.047, blue: 0.055)
    public static let surface = Color(red: 0.098, green: 0.106, blue: 0.122)
    public static let surfaceRaised = Color(red: 0.137, green: 0.145, blue: 0.165)

    /// The app's single accent color — used for the active state, primary actions, and streaks.
    public static let accent = Color(red: 0.78, green: 1.0, blue: 0.32)

    public static let textPrimary = Color.white
    public static let textSecondary = Color.white.opacity(0.56)
    public static let textTertiary = Color.white.opacity(0.34)
    public static let divider = Color.white.opacity(0.08)
    public static let danger = Color(red: 1.0, green: 0.38, blue: 0.38)

    /// A restrained per-day-type tint, used only for small glyphs and dots, never large fills.
    public static func accent(for dayType: DayType) -> Color {
        switch dayType {
        case .push: Color(red: 0.78, green: 1.0, blue: 0.32)
        case .pull: Color(red: 0.42, green: 0.78, blue: 1.0)
        case .legs: Color(red: 1.0, green: 0.58, blue: 0.32)
        case .rest: Color.white.opacity(0.4)
        }
    }
}
