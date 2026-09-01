import SwiftUI
import GymTrackerKit

/// Everything logged in one session: the day type plus every exercise's sets, in the order the
/// exercises appear in the library. Reached by tapping a trained day in the calendar grid.
struct WorkoutDayDetailView: View {
    let workout: Workout

    @AppStorage("preferredWeightUnit") private var unitRaw = WeightUnit.lb.rawValue
    private var unit: WeightUnit { WeightUnit(rawValue: unitRaw) ?? .lb }

    private var logs: [ExerciseLog] {
        (workout.exerciseLogs ?? []).sorted {
            ($0.exercise?.sortOrder ?? 0) < ($1.exercise?.sortOrder ?? 0)
        }
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(spacing: 6) {
                    Image(systemName: workout.dayType.symbolName)
                        .foregroundStyle(Theme.accent(for: workout.dayType))
                    Text(workout.dayType.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.accent(for: workout.dayType))
                }
                .padding(.top, 12)
                .padding(.bottom, 8)

                if workout.dayType == .rest {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "moon.zzz.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(Theme.accent(for: .rest))
                        Text("Rest day")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    Spacer()
                } else if logs.isEmpty {
                    Spacer()
                    Text("Nothing logged this session")
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                } else {
                    List {
                        ForEach(logs) { log in
                            Section {
                                ForEach((log.sets ?? []).sorted(by: { $0.setNumber < $1.setNumber })) { set in
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
                            } header: {
                                Text(log.exercise?.name ?? "Exercise")
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            .listRowBackground(Theme.surface)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .navigationTitle(workout.date.formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func displayValue(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(value)) : String(format: "%.1f", value)
    }
}
