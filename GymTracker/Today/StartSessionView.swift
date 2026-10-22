import SwiftUI
import SwiftData
import GymTrackerKit

/// Landing screen: lands directly on today's (auto-selected) day type. One tap starts the
/// session; if a session is already underway today it's shown immediately instead — minimizing
/// taps between opening the app and logging a set.
struct StartSessionView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]
    @Query(filter: #Predicate<Exercise> { !$0.isArchived }, sort: \Exercise.sortOrder)
    private var exercises: [Exercise]
    @AppStorage("preferredWeightUnit") private var unitRaw = WeightUnit.lb.rawValue

    @State private var selectedDay: DayType?
    @State private var activeWorkout: Workout?

    private var unit: WeightUnit { WeightUnit(rawValue: unitRaw) ?? .lb }

    private var suggestedDay: DayType {
        NextDayCalculator.nextDayType(afterLast: workouts.first)
    }

    private var day: DayType { selectedDay ?? suggestedDay }

    private var todaysWorkout: Workout? {
        workouts.first { Calendar.current.isDateInToday($0.date) }
    }

    private var currentWorkout: Workout? { activeWorkout ?? todaysWorkout }

    private var plan: [Exercise] { exercises.filter { $0.dayType == day } }

    private var muscleGroups: String {
        var seen = Set<String>()
        return plan.map(\.muscleGroup).filter { seen.insert($0).inserted }.joined(separator: " · ")
    }

    private var lastTimeTrained: Workout? { workouts.first { $0.dayType == day } }

    private var sessionsThisWeek: Int {
        workouts.filter { Calendar.current.isDate($0.date, equalTo: .now, toGranularity: .weekOfYear) }.count
    }

    var body: some View {
        NavigationStack {
            Group {
                if let workout = currentWorkout {
                    SessionView(workout: workout)
                } else {
                    pickerView
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(currentWorkout.map { "\($0.dayType.displayName) Day" } ?? "Today")
        }
    }

    private var pickerView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.top, -8)

                heroCard
                statsRow

                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Switch day")
                    HStack(spacing: 8) {
                        ForEach(DayType.allCases) { option in
                            DayChip(day: option, isSelected: day == option, isSuggested: option == suggestedDay) {
                                withAnimation(.snappy(duration: 0.2)) { selectedDay = option }
                            }
                        }
                    }
                }

                if !plan.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Today's plan", trailing: "\(plan.count) exercises")
                        VStack(spacing: 0) {
                            ForEach(Array(plan.enumerated()), id: \.element.id) { index, exercise in
                                PlanRow(index: index + 1, exercise: exercise, lastText: exercise.lastTopSetText(in: unit), tint: Theme.accent(for: day))
                                if index < plan.count - 1 {
                                    Divider().overlay(Theme.divider).padding(.leading, 52)
                                }
                            }
                        }
                        .cardStyle(padding: 0)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom) { startButton }
    }

    private var heroCard: some View {
        let tint = Theme.accent(for: day)
        return VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text(day == suggestedDay ? "NEXT UP" : "CHOSEN DAY")
                    .font(.caption.weight(.bold))
                    .tracking(1.6)
                    .foregroundStyle(tint)
                Spacer()
                if day != suggestedDay {
                    Button("Reset") { withAnimation(.snappy(duration: 0.2)) { selectedDay = nil } }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.textSecondary)
                }
            }

            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(day.displayName)
                        .font(.display(60))
                        .foregroundStyle(Theme.textPrimary)
                        .contentTransition(.opacity)
                    Text(day == .rest ? "Recovery — log it to keep your streak" : muscleGroups)
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(2)
                }
                Spacer(minLength: 8)
                Image(systemName: day.symbolName)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 76, height: 76)
                    .background(tint.opacity(0.14), in: Circle())
                    .accessibilityHidden(true)
            }

            Divider().overlay(Theme.divider)

            HStack(spacing: 20) {
                Label(day == .rest ? "No lifting" : "\(plan.count) exercises", systemImage: "list.bullet")
                Label(lastTrainedText, systemImage: "clock.arrow.circlepath")
            }
            .font(.footnote.weight(.medium))
            .foregroundStyle(Theme.textSecondary)
        }
        .cardStyle(padding: 20, tint: tint)
    }

    private var lastTrainedText: String {
        guard let last = lastTimeTrained else { return "First time" }
        if Calendar.current.isDateInYesterday(last.date) { return "Last: yesterday" }
        return "Last: \(last.date.formatted(.dateTime.month(.abbreviated).day()))"
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            StatTile(
                value: "\(StreakCalculator.currentStreak(workouts: workouts))",
                label: "Day streak",
                systemImage: "flame.fill",
                tint: Theme.accent
            )
            StatTile(value: "\(sessionsThisWeek)", label: "This week", systemImage: "calendar")
            StatTile(value: "\(workouts.count)", label: "All time", systemImage: "trophy.fill")
        }
    }

    private var startButton: some View {
        Button {
            startSession(day: day)
        } label: {
            Label(day == .rest ? "Log Rest Day" : "Start \(day.displayName) Session",
                  systemImage: day == .rest ? "moon.zzz.fill" : "play.fill")
        }
        .buttonStyle(PrimaryButtonStyle(tint: Theme.accent(for: day)))
        .sensoryFeedback(.impact(weight: .medium), trigger: activeWorkout?.persistentModelID)
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background {
            // Fades the scrolling content out under the button instead of a hard edge.
            LinearGradient(
                stops: [.init(color: Theme.background.opacity(0), location: 0), .init(color: Theme.background, location: 0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
                .ignoresSafeArea()
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
    let isSuggested: Bool
    let action: () -> Void

    var body: some View {
        let tint = Theme.accent(for: day)
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: day.symbolName)
                    .font(.system(size: 17, weight: .semibold))
                Text(day.displayName)
                    .font(.footnote.weight(.semibold))
            }
            .frame(maxWidth: .infinity, minHeight: 64)
            .foregroundStyle(isSelected ? tint : Theme.textSecondary)
            .background(
                isSelected ? tint.opacity(0.14) : Theme.surface,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isSelected ? tint.opacity(0.8) : Theme.stroke, lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(PressableRowStyle())
        .accessibilityLabel(isSuggested ? "\(day.displayName), suggested" : day.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct PlanRow: View {
    let index: Int
    let exercise: Exercise
    let lastText: String?
    let tint: Color

    var body: some View {
        HStack(spacing: 14) {
            Text("\(index)")
                .font(.footnote.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(tint)
                .frame(width: 26, height: 26)
                .background(tint.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(exercise.muscleGroup)
                    .font(.caption)
                    .foregroundStyle(Theme.textTertiary)
            }
            Spacer()
            if let lastText {
                Text(lastText)
                    .font(.caption.weight(.medium))
                    .monospacedDigit()
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }
}
