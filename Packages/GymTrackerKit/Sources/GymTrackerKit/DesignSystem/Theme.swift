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
    /// Hairline edge on cards, so surfaces stay separated from the near-black background.
    public static let stroke = Color.white.opacity(0.06)
    public static let danger = Color(red: 1.0, green: 0.38, blue: 0.38)

    /// The tint for a day type. Every training day shares the one accent so the app has a single
    /// main color; day types are told apart by name and icon. Rest stays neutral gray.
    public static func accent(for dayType: DayType) -> Color {
        dayType == .rest ? Color.white.opacity(0.4) : accent
    }
}
