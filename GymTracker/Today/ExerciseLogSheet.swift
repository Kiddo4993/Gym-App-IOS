import SwiftUI
import SwiftData
import Observation
import GymTrackerKit

/// One of the six numeric fields a set entry can have focus on.
enum EntryField: Hashable {
    case weight(Int)
    case fullReps(Int)
    case partialReps(Int)
}

/// Holds the in-progress text for both sets while the custom keypad is driving entry, plus which
/// field currently has focus. Shared between the "log today" sheet and the "edit past entry"
/// sheet so both use the identical field/keypad UI.
@Observable
final class SetEntryDraft {
    var weight: [Int: String] = [1: "", 2: ""]
    var fullReps: [Int: String] = [1: "", 2: ""]
    var partialReps: [Int: String] = [1: "", 2: ""]
    var active: EntryField = .weight(1)

    func text(for field: EntryField) -> String {
        switch field {
        case .weight(let set): weight[set] ?? ""
        case .fullReps(let set): fullReps[set] ?? ""
        case .partialReps(let set): partialReps[set] ?? ""
        }
    }

    func set(_ field: EntryField, _ value: String) {
        switch field {
        case .weight(let set): weight[set] = value
        case .fullReps(let set): fullReps[set] = value
        case .partialReps(let set): partialReps[set] = value
        }
    }

    var allowsDecimal: Bool {
        if case .weight = active { return true }
        return false
    }

    func append(_ digit: String) {
        var current = text(for: active)
        if digit == "." {
            guard allowsDecimal, !current.contains(".") else { return }
        }
        if current == "0", digit != "." { current = "" }
        guard current.count < 6 else { return }
        current += digit
        set(active, current)
    }

    func backspace() {
        var current = text(for: active)
        guard !current.isEmpty else { return }
        current.removeLast()
        set(active, current)
    }

    func doubleValue(_ field: EntryField) -> Double { Double(text(for: field)) ?? 0 }
    func intValue(_ field: EntryField) -> Int { Int(text(for: field)) ?? 0 }
}

/// Log sets for one exercise in the current session. Pre-fills both sets with the values from
/// the last session for this exercise so only what's different needs to change.
struct ExerciseLogSheet: View {
    let exercise: Exercise
    let workout: Workout

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("preferredWeightUnit") private var unitRaw = WeightUnit.lb.rawValue
    @State private var draft = SetEntryDraft()

    private var unit: WeightUnit { WeightUnit(rawValue: unitRaw) ?? .lb }

    private var existingLog: ExerciseLog? {
        workout.exerciseLogs?.first { $0.exercise?.persistentModelID == exercise.persistentModelID }
    }

    private var lastLog: ExerciseLog? {
        (exercise.logs ?? [])
            .filter { $0.workout?.persistentModelID != workout.persistentModelID }
            .sorted { ($0.workout?.date ?? .distantPast) > ($1.workout?.date ?? .distantPast) }
            .first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 20) {
                        SetEntryRow(setNumber: 1, draft: draft, unit: unit)
                        SetEntryRow(setNumber: 2, draft: draft, unit: unit)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    Spacer()

                    NumericKeypad(draft: draft)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                }
            }
            .navigationTitle(exercise.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .foregroundStyle(Theme.accent)
                        .fontWeight(.semibold)
                }
            }
        }
        .onAppear(perform: prefill)
    }

    private func prefill() {
        guard let sets = (existingLog ?? lastLog)?.sets else { return }
        for set in sets where set.setNumber == 1 || set.setNumber == 2 {
            draft.set(.weight(set.setNumber), formatted(set.weight(in: unit)))
            draft.set(.fullReps(set.setNumber), "\(set.fullReps)")
            draft.set(.partialReps(set.setNumber), "\(set.partialReps)")
        }
    }

    private func save() {
        let log = existingLog ?? ExerciseLog(exercise: exercise, workout: workout)
        if existingLog == nil {
            context.insert(log)
        }

        for setNumber in [1, 2] {
            let weight = draft.doubleValue(.weight(setNumber))
            let full = draft.intValue(.fullReps(setNumber))
            let partial = draft.intValue(.partialReps(setNumber))

            if let set = log.sets?.first(where: { $0.setNumber == setNumber }) {
                set.weightValue = weight
                set.weightUnitRaw = unit.rawValue
                set.fullReps = full
                set.partialReps = partial
            } else {
                let set = SetLog(setNumber: setNumber, weightValue: weight, unit: unit, fullReps: full, partialReps: partial)
                set.exerciseLog = log
                context.insert(set)
                log.sets?.append(set)
            }
        }

        try? context.save()
        dismiss()
    }
}

private func formatted(_ value: Double) -> String {
    value.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(value)) : String(format: "%.1f", value)
}

/// One "Set N" row: weight / full reps / partial reps, each a tappable `KeypadField`.
struct SetEntryRow: View {
    let setNumber: Int
    var draft: SetEntryDraft
    let unit: WeightUnit

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SET \(setNumber)")
                .font(.caption.weight(.bold))
                .tracking(1.5)
                .foregroundStyle(Theme.textTertiary)

            HStack(spacing: 10) {
                KeypadField(label: "Weight (\(unit.symbol))", field: .weight(setNumber), draft: draft)
                KeypadField(label: "Full", field: .fullReps(setNumber), draft: draft)
                KeypadField(label: "Partial", field: .partialReps(setNumber), draft: draft)
            }
        }
    }
}

/// A large, tappable numeric display. Tapping it makes it the active target for the custom
/// keypad — there is no system keyboard anywhere in this flow.
struct KeypadField: View {
    let label: String
    let field: EntryField
    var draft: SetEntryDraft

    private var isActive: Bool { draft.active == field }

    var body: some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Theme.textTertiary)
            Text(draft.text(for: field).isEmpty ? "–" : draft.text(for: field))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    isActive ? Theme.accent.opacity(0.16) : Theme.surface,
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(isActive ? Theme.accent : .clear, lineWidth: 2)
                )
        }
        .contentShape(Rectangle())
        .onTapGesture { draft.active = field }
    }
}
