import SwiftUI
import SwiftData
import GymTrackerKit

/// Every exercise, grouped by day type, in the fixed Push → Pull → Legs order. Tap one to see
/// its full session-by-session history.
struct HistoryListView: View {
    @Query(sort: [SortDescriptor(\Exercise.dayTypeRaw), SortDescriptor(\Exercise.sortOrder)])
    private var exercises: [Exercise]

    private var grouped: [(DayType, [Exercise])] {
        let byDay = Dictionary(grouping: exercises.filter { !$0.isArchived }, by: \.dayType)
        return DayType.allCases.compactMap { day in
            guard let items = byDay[day], !items.isEmpty else { return nil }
            return (day, items)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(grouped, id: \.0) { day, items in
                    if day != .rest {
                        Section {
                            ForEach(items) { exercise in
                                NavigationLink {
                                    ExerciseHistoryView(exercise: exercise)
                                } label: {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(exercise.name).font(.headline).foregroundStyle(Theme.textPrimary)
                                        Text(exercise.muscleGroup).font(.caption).foregroundStyle(Theme.textSecondary)
                                    }
                                    .padding(.vertical, 4)
                                }
                                .listRowBackground(Theme.surface)
                            }
                        } header: {
                            Text(day.displayName).foregroundStyle(Theme.accent(for: day))
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("History")
        }
    }
}
