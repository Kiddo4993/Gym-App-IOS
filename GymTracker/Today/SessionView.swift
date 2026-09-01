import SwiftUI
import SwiftData
import GymTrackerKit

/// The exercise list for the active workout's day type — tap an exercise to log its sets.
struct SessionView: View {
    let workout: Workout

    @Query private var dayExercises: [Exercise]
    @State private var selectedExercise: Exercise?

    init(workout: Workout) {
        self.workout = workout
        let dayRaw = workout.dayTypeRaw
        _dayExercises = Query(
            filter: #Predicate<Exercise> { $0.dayTypeRaw == dayRaw && !$0.isArchived },
            sort: [SortDescriptor(\.sortOrder)]
        )
    }

    var body: some View {
        Group {
            if workout.dayType == .rest {
                restDayView
            } else {
                List {
                    ForEach(dayExercises) { exercise in
                        Button {
                            selectedExercise = exercise
                        } label: {
                            ExerciseRow(exercise: exercise, workout: workout)
                        }
                        .listRowBackground(Theme.surface)
                        .listRowSeparatorTint(Theme.divider)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .sheet(item: $selectedExercise) { exercise in
            ExerciseLogSheet(exercise: exercise, workout: workout)
        }
    }

    private var restDayView: some View {
        VStack(spacing: 12) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 40))
                .foregroundStyle(Theme.accent(for: .rest))
            Text("Rest day logged")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
            Text("No exercises to track today. Recover up.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
        }
    }
}

private struct ExerciseRow: View {
    let exercise: Exercise
    let workout: Workout

    private var isLogged: Bool {
        workout.exerciseLogs?.contains { $0.exercise?.persistentModelID == exercise.persistentModelID } ?? false
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Text(exercise.muscleGroup)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Image(systemName: isLogged ? "checkmark.circle.fill" : "chevron.right")
                .foregroundStyle(isLogged ? Theme.accent(for: exercise.dayType) : Theme.textTertiary)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}
