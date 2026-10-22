import SwiftUI
import SwiftData
import GymTrackerKit

/// The exercise list for the active workout's day type — tap an exercise to log its sets.
struct SessionView: View {
    let workout: Workout

    @Query private var dayExercises: [Exercise]
    @AppStorage("preferredWeightUnit") private var unitRaw = WeightUnit.lb.rawValue
    @State private var selectedExercise: Exercise?

    private var unit: WeightUnit { WeightUnit(rawValue: unitRaw) ?? .lb }
    private var tint: Color { Theme.accent(for: workout.dayType) }

    init(workout: Workout) {
        self.workout = workout
        let dayRaw = workout.dayTypeRaw
        _dayExercises = Query(
            filter: #Predicate<Exercise> { $0.dayTypeRaw == dayRaw && !$0.isArchived },
            sort: [SortDescriptor(\.sortOrder)]
        )
    }

    private func isLogged(_ exercise: Exercise) -> Bool {
        workout.exerciseLogs?.contains { $0.exercise?.persistentModelID == exercise.persistentModelID } ?? false
    }

    private var loggedCount: Int { dayExercises.filter(isLogged).count }

    var body: some View {
        Group {
            if workout.dayType == .rest {
                restDayView
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        progressCard

                        VStack(spacing: 10) {
                            ForEach(Array(dayExercises.enumerated()), id: \.element.id) { index, exercise in
                                Button {
                                    selectedExercise = exercise
                                } label: {
                                    ExerciseRow(
                                        index: index + 1,
                                        exercise: exercise,
                                        isLogged: isLogged(exercise),
                                        lastText: exercise.lastTopSetText(in: unit, excluding: workout),
                                        tint: tint
                                    )
                                }
                                .buttonStyle(PressableRowStyle())
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
            }
        }
        .sheet(item: $selectedExercise) { exercise in
            ExerciseLogSheet(exercise: exercise, workout: workout)
        }
    }

    private var progressCard: some View {
        let total = max(dayExercises.count, 1)
        let done = loggedCount == dayExercises.count && !dayExercises.isEmpty
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(loggedCount)")
                    .font(.display(44))
                    .monospacedDigit()
                    .foregroundStyle(Theme.textPrimary)
                    .contentTransition(.numericText())
                Text("of \(dayExercises.count) logged")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                if done {
                    Label("Done", systemImage: "checkmark.seal.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(tint)
                }
            }
            ProgressView(value: Double(loggedCount), total: Double(total))
                .tint(tint)
                .scaleEffect(x: 1, y: 1.6, anchor: .center)
                .animation(.easeOut(duration: 0.3), value: loggedCount)
        }
        .cardStyle(padding: 18, tint: tint)
        .accessibilityElement(children: .combine)
    }

    private var restDayView: some View {
        ContentUnavailableView {
            Label("Rest day logged", systemImage: "moon.zzz.fill")
        } description: {
            Text("No exercises to track today. Recover well — your streak is safe.")
        }
        .foregroundStyle(Theme.textSecondary)
    }
}

private struct ExerciseRow: View {
    let index: Int
    let exercise: Exercise
    let isLogged: Bool
    let lastText: String?
    let tint: Color

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isLogged ? tint : tint.opacity(0.12))
                if isLogged {
                    Image(systemName: "checkmark")
                        .font(.footnote.weight(.heavy))
                        .foregroundStyle(.black)
                } else {
                    Text("\(index)")
                        .font(.footnote.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(tint)
                }
            }
            .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 3) {
                Text(exercise.name)
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.leading)
                HStack(spacing: 6) {
                    Text(exercise.muscleGroup)
                    if let lastText {
                        Text("·")
                        Text("Last \(lastText)").monospacedDigit()
                    }
                }
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.textTertiary)
        }
        .cardStyle(padding: 14)
        .opacity(isLogged ? 0.75 : 1)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityValue(isLogged ? "Logged" : "Not logged")
    }
}
