import SwiftUI
import SwiftData
import GymTrackerKit

/// Every exercise, grouped by day type, in the fixed Push → Pull → Legs order. Tap one to see
/// its full session-by-session history.
struct HistoryListView: View {
    @Query(sort: [SortDescriptor(\Exercise.dayTypeRaw), SortDescriptor(\Exercise.sortOrder)])
    private var exercises: [Exercise]
    @AppStorage("preferredWeightUnit") private var unitRaw = WeightUnit.lb.rawValue

    private var unit: WeightUnit { WeightUnit(rawValue: unitRaw) ?? .lb }

    private var grouped: [(DayType, [Exercise])] {
        let byDay = Dictionary(grouping: exercises.filter { !$0.isArchived }, by: \.dayType)
        return DayType.allCases.compactMap { day in
            guard day != .rest, let items = byDay[day], !items.isEmpty else { return nil }
            return (day, items)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(grouped, id: \.0) { day, items in
                    Section {
                        ForEach(items) { exercise in
                            NavigationLink {
                                ExerciseHistoryView(exercise: exercise)
                            } label: {
                                HistoryExerciseRow(exercise: exercise, unit: unit)
                            }
                            .listRowBackground(Theme.surface)
                            .listRowSeparatorTint(Theme.divider)
                        }
                    } header: {
                        Label(day.displayName, systemImage: day.symbolName)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Theme.accent(for: day))
                            .textCase(nil)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("History")
            .overlay {
                if grouped.isEmpty {
                    ContentUnavailableView(
                        "No exercises",
                        systemImage: "dumbbell",
                        description: Text("Add exercises in Settings to start building history.")
                    )
                }
            }
        }
    }
}

private struct HistoryExerciseRow: View {
    let exercise: Exercise
    let unit: WeightUnit

    private var sessionCount: Int { exercise.logs?.filter { $0.workout != nil }.count ?? 0 }

    var body: some View {
        HStack(spacing: 12) {
            IconTile(systemName: exercise.dayType.symbolName, tint: Theme.accent(for: exercise.dayType), size: 36)
            VStack(alignment: .leading, spacing: 3) {
                Text(exercise.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(sessionCount == 0 ? exercise.muscleGroup : "\(exercise.muscleGroup) · \(sessionCount) sessions")
                    .font(.caption)
                    .foregroundStyle(Theme.textTertiary)
            }
            Spacer(minLength: 8)
            if let last = exercise.lastTopSetText(in: unit) {
                Text(last)
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(.vertical, 4)
    }
}
