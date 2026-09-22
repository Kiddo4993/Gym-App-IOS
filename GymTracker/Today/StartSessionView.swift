import SwiftUI
import SwiftData
import GymTrackerKit

/// Landing screen: lands directly on today's (auto-selected) day type. One tap starts the
/// session; if a session is already underway today it's shown immediately instead — minimizing
/// taps between opening the app and logging a set.
struct StartSessionView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]

    @State private var selectedDay: DayType?
    @State private var activeWorkout: Workout?

    private var suggestedDay: DayType {
        NextDayCalculator.nextDayType(afterLast: workouts.first)
    }

    private var todaysWorkout: Workout? {
        workouts.first { Calendar.current.isDateInToday($0.date) }
    }

    private var currentWorkout: Workout? { activeWorkout ?? todaysWorkout }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if let workout = currentWorkout {
                    SessionView(workout: workout)
                } else {
                    pickerView
                }
            }
            .navigationTitle(currentWorkout?.dayType.displayName ?? "")
        }
    }

    private var pickerView: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 8) {
                Text("NEXT UP")
                    .font(.caption.weight(.bold))
                    .tracking(2)
                    .foregroundStyle(Theme.textTertiary)
                Text((selectedDay ?? suggestedDay).displayName)
                    .font(.system(size: 52, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Image(systemName: (selectedDay ?? suggestedDay).symbolName)
                    .font(.system(size: 34))
                    .foregroundStyle(Theme.accent(for: selectedDay ?? suggestedDay))
                    .padding(.top, 4)
            }

            HStack(spacing: 10) {
                ForEach(DayType.allCases) { day in
                    DayChip(day: day, isSelected: (selectedDay ?? suggestedDay) == day) {
                        selectedDay = day
                    }
                }
            }

            Spacer()

            Button("Start Session") {
                startSession(day: selectedDay ?? suggestedDay)
            }
            .buttonStyle(PrimaryButtonStyle(tint: Theme.accent(for: selectedDay ?? suggestedDay)))
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
    }

    private func startSession(day: DayType) {
        let workout = Workout(dayType: day)
        context.insert(workout)
        try? context.save()
        activeWorkout = workout

        // A real workout is now logged, so the automatic rotation can take back over.
        DayOverrideStore.current = nil
        DayNotificationManager.refresh()
    }
}

private struct DayChip: View {
    let day: DayType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(day.displayName)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isSelected ? Theme.accent(for: day).opacity(0.18) : Theme.surface)
                .foregroundStyle(isSelected ? Theme.accent(for: day) : Theme.textSecondary)
                .overlay(
                    Capsule().stroke(isSelected ? Theme.accent(for: day) : .clear, lineWidth: 1.5)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
