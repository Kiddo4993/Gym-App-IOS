import SwiftUI
import GymTrackerKit

/// Small, reusable pieces that keep every screen consistent with the app's minimal, dark,
/// high-contrast look — few colors, generous tap targets, no unnecessary chrome.

extension Font {
    /// Condensed, heavy SF Pro for big numbers and day names — an athletic, scoreboard feel
    /// without bundling a custom font.
    static func display(_ size: CGFloat, weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight).width(.condensed)
    }
}

struct SectionHeader: View {
    let title: String
    var trailing: String? = nil

    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .tracking(1.2)
                .foregroundStyle(Theme.textTertiary)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .accessibilityAddTraits(.isHeader)
    }
}

private struct CardBackground: ViewModifier {
    var padding: CGFloat
    var tint: Color?

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Theme.surface)
                    .overlay {
                        if let tint {
                            // A faint wash of the day's color in the top corner identifies the
                            // card without turning it into a big colored block.
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(LinearGradient(
                                    colors: [tint.opacity(0.16), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .center
                                ))
                        }
                    }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Theme.stroke, lineWidth: 1)
            )
    }
}

extension View {
    func cardStyle(padding: CGFloat = 16, tint: Color? = nil) -> some View {
        modifier(CardBackground(padding: padding, tint: tint))
    }
}

/// A rounded-square icon on a soft tint, like the rows in iOS Settings.
struct IconTile: View {
    let systemName: String
    var tint: Color = Theme.accent
    var size: CGFloat = 32

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.46, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background(tint.opacity(0.15), in: RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
            .accessibilityHidden(true)
    }
}

/// One headline number with a label underneath — used in rows of two or three.
struct StatTile: View {
    let value: String
    let label: String
    let systemImage: String
    var tint: Color = Theme.textSecondary

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.display(28, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }
        }
        .cardStyle(padding: 14)
        .accessibilityElement(children: .combine)
    }
}

/// A full-width, high-contrast primary action button sized for use with sweaty, imprecise taps.
struct PrimaryButtonStyle: ButtonStyle {
    var tint: Color = Theme.accent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(tint, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Darkens a card-shaped row slightly while it's held, so taps register visually.
struct PressableRowStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.6 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension Double {
    /// "135" for whole numbers, "137.5" otherwise.
    var weightText: String {
        truncatingRemainder(dividingBy: 1) == 0 ? String(Int(self)) : String(format: "%.1f", self)
    }
}
