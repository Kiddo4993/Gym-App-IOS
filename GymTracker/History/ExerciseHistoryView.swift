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
                ContentUnavailableView(
                    "No sessions yet",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Log \(exercise.name) during a session and it shows up here.")
                )
            } else {
                List {
                    ForEach(logs) { log in
                        Button {
                            editingLog = log
                        } label: {
                            HistoryRow(log: log, unit: unit)
                        }
                        .listRowBackground(Theme.surface)
                        .listRowSeparatorTint(Theme.divider)
                    }
                }
                .listStyle(.insetGrouped)
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

    private var volume: Double { VolumeCalculator.estimatedVolume(for: sets, in: unit) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text((log.workout?.date ?? .now).formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("\(volume.weightText) \(unit.symbol) vol")
                    .font(.caption.weight(.medium))
                    .monospacedDigit()
                    .foregroundStyle(Theme.textTertiary)
            }

            ForEach(sets) { set in
                HStack(spacing: 10) {
                    Text("\(set.setNumber)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Theme.accent(for: log.exercise?.dayType ?? .push))
                        .frame(width: 20, height: 20)
                        .background(Theme.accent(for: log.exercise?.dayType ?? .push).opacity(0.12), in: Circle())
                    Text("\(set.weight(in: unit).weightText) \(unit.symbol)")
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Text("\(set.fullReps) reps")
                        .font(.subheadline)
                        .monospacedDigit()
                        .foregroundStyle(Theme.textSecondary)
                    if set.partialReps > 0 {
                        Text("+\(set.partialReps)")
                            .font(.caption.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(Theme.textTertiary)
                            .accessibilityLabel("plus \(set.partialReps) partials")
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(.vertical, 6)
    }
}
