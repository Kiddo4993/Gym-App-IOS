import SwiftUI
import GymTrackerKit

/// A large custom numeric keypad — replaces the system keyboard entirely so sets can be logged
/// mid-workout with big, forgiving tap targets.
struct NumericKeypad: View {
    var draft: SetEntryDraft

    private let rows: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        [".", "0", "⌫"]
    ]

    var body: some View {
        VStack(spacing: 10) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(row, id: \.self) { key in
                        KeypadButton(key: key, isEnabled: key != "." || draft.allowsDecimal) {
                            handle(key)
                        }
                    }
                }
            }
        }
    }

    private func handle(_ key: String) {
        switch key {
        case "⌫": draft.backspace()
        default: draft.append(key)
        }
    }
}

private struct KeypadButton: View {
    let key: String
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if key == "⌫" {
                    Image(systemName: "delete.left")
                } else {
                    Text(key)
                }
            }
            .font(.system(size: 24, weight: .semibold, design: .rounded))
            .frame(maxWidth: .infinity, minHeight: 58)
            .foregroundStyle(isEnabled ? Theme.textPrimary : Theme.textTertiary)
        }
        .buttonStyle(KeyStyle())
        .disabled(!isEnabled)
        .accessibilityLabel(key == "⌫" ? "Delete" : key == "." ? "Decimal point" : key)
    }
}

/// Keys light up while held, like the system keyboard, so every tap is confirmed.
private struct KeyStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                configuration.isPressed ? Theme.surfaceRaised : Theme.surface,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .sensoryFeedback(.selection, trigger: configuration.isPressed) { _, pressed in pressed }
    }
}
