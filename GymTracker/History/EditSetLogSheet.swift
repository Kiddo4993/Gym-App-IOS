import SwiftUI
import SwiftData
import GymTrackerKit

/// Edits an already-logged session's two sets, reusing the same field/keypad UI as live logging.
struct EditSetLogSheet: View {
    let exerciseLog: ExerciseLog
    let unit: WeightUnit

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var draft = SetEntryDraft()

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
            .navigationTitle(exerciseLog.exercise?.name ?? "Edit Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundStyle(Theme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.foregroundStyle(Theme.accent).fontWeight(.semibold)
                }
            }
        }
        .onAppear(perform: prefill)
    }

    private func prefill() {
        for set in exerciseLog.sets ?? [] where set.setNumber == 1 || set.setNumber == 2 {
            let value = set.weight(in: unit)
            let text = value.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(value)) : String(format: "%.1f", value)
            draft.set(.weight(set.setNumber), text)
            draft.set(.fullReps(set.setNumber), "\(set.fullReps)")
            draft.set(.partialReps(set.setNumber), "\(set.partialReps)")
        }
    }

    private func save() {
        for setNumber in [1, 2] {
            guard let set = exerciseLog.sets?.first(where: { $0.setNumber == setNumber }) else { continue }
            set.weightValue = draft.doubleValue(.weight(setNumber))
            set.weightUnitRaw = unit.rawValue
            set.fullReps = draft.intValue(.fullReps(setNumber))
            set.partialReps = draft.intValue(.partialReps(setNumber))
        }
        try? context.save()
        dismiss()
    }
}
