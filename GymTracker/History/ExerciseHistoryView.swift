import SwiftUI
import SwiftData
import GymTrackerKit

/// Every past session for one exercise: date, weight, full reps, and partials — newest first.
/// Tapping a session opens it for editing.
struct ExerciseHistoryView: View {
    let exercise: Exercise

    @AppStorage("preferredWeightUnit") private var unitRaw = WeightUnit.lb.rawValue
    @State private var editingLog: ExerciseLog?

    private var unit: WeightUnit { WeightUnit(rawValue: unitRaw) ?? .lb }

    private var logs: [ExerciseLog] {
        (exercise.logs ?? []).sorted { ($0.workout?.date ?? .distantPast) > ($1.workout?.date ?? .distantPast) }
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            if logs.isEmpty {
                Text("No sessions logged yet")
                    .foregroundStyle(Theme.textSecondary)
            } else {
                List {
                    ForEach(logs) { log in
                        Button {
                            editingLog = log
                        } label: {
                            HistoryRow(log: log, unit: unit)
                        }
                        .listRowBackground(Theme.surface)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingLog) { log in
            EditSetLogSheet(exerciseLog: log, unit: unit)
        }
    }
}

private struct HistoryRow: View {
    let log: ExerciseLog
    let unit: WeightUnit

    private var sets: [SetLog] {
        (log.sets ?? []).sorted { $0.setNumber < $1.setNumber }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text((log.workout?.date ?? .now).formatted(date: .abbreviated, time: .omitted))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)

            ForEach(sets) { set in
                HStack {
                    Text("Set \(set.setNumber)")
                        .font(.caption)
                        .foregroundStyle(Theme.textTertiary)
                        .frame(width: 46, alignment: .leading)
                    Text("\(displayValue(set.weight(in: unit))) \(unit.symbol)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Text("\(set.fullReps) full · \(set.partialReps) partial")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .padding(.vertical, 6)
    }

    private func displayValue(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(value)) : String(format: "%.1f", value)
    }
}
