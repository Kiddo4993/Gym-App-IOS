import SwiftUI
import SwiftData
import GymTrackerKit

/// A month grid colored by day type, plus the current streak — which days were trained,
/// which day type each was, and which were rest days.
struct CalendarStreakView: View {
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]
    @State private var monthOffset = 0

    private var calendar: Calendar { .current }

    private var displayedMonth: Date {
        calendar.date(byAdding: .month, value: monthOffset, to: .now) ?? .now
    }

    private var streak: Int { StreakCalculator.currentStreak(workouts: workouts) }

    private var monthWorkouts: [Workout] {
        workouts.filter { calendar.isDate($0.date, equalTo: displayedMonth, toGranularity: .month) }
    }

    private var daysInMonth: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))
        else { return [] }

        let leadingEmpty = (calendar.component(.weekday, from: firstOfMonth) - calendar.firstWeekday + 7) % 7
        var days: [Date?] = Array(repeating: nil, count: leadingEmpty)
        days += range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: firstOfMonth) }
        return days
    }

    /// Weekday initials starting from the locale's first weekday (Sunday in the US).
    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let start = calendar.firstWeekday - 1
        return Array(symbols[start...] + symbols[..<start])
    }

    private func workout(on date: Date) -> Workout? {
        workouts.first { calendar.isDate($0.date, inSameDayAs: date) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    streakCard
                    monthCard
                    Legend()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Calendar")
        }
    }

    private var streakCard: some View {
        HStack(spacing: 16) {
            Image(systemName: "flame.fill")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 64, height: 64)
                .background(Theme.accent.opacity(0.14), in: Circle())
                .symbolEffect(.bounce, value: streak)
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(streak)")
                        .font(.display(44))
                        .monospacedDigit()
                        .foregroundStyle(Theme.textPrimary)
                    Text("day streak")
                        .font(.headline)
                        .foregroundStyle(Theme.textSecondary)
                }
                Text(streak == 0 ? "Log a session today to start one." : "Keep it going — rest days count too.")
                    .font(.footnote)
                    .foregroundStyle(Theme.textTertiary)
            }
            Spacer(minLength: 0)
        }
        .cardStyle(padding: 18, tint: Theme.accent)
        .accessibilityElement(children: .combine)
    }

    private var monthCard: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(monthWorkouts.count) sessions")
                        .font(.caption)
                        .foregroundStyle(Theme.textTertiary)
                }
                Spacer()
                MonthButton(systemName: "chevron.left", label: "Previous month") { monthOffset -= 1 }
                MonthButton(systemName: "chevron.right", label: "Next month") { monthOffset += 1 }
                    .disabled(monthOffset >= 0)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 6) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 2)
                }
                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, date in
                    if let date {
                        if let workout = workout(on: date) {
                            NavigationLink {
                                WorkoutDayDetailView(workout: workout)
                            } label: {
                                DayCell(date: date, workout: workout)
                            }
                            .buttonStyle(PressableRowStyle())
                        } else {
                            DayCell(date: date, workout: nil)
                        }
                    } else {
                        Color.clear.frame(height: 40)
                    }
                }
            }
        }
        .cardStyle(padding: 16)
        .animation(.snappy(duration: 0.25), value: monthOffset)
    }
}

private struct MonthButton: View {
    let systemName: String
    let label: String
    let action: () -> Void
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.footnote.weight(.bold))
                .foregroundStyle(isEnabled ? Theme.textPrimary : Theme.textTertiary)
                .frame(width: 36, height: 36)
                .background(Theme.surfaceRaised, in: Circle())
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressableRowStyle())
        .accessibilityLabel(label)
    }
}

private struct DayCell: View {
    let date: Date
    let workout: Workout?

    private var isToday: Bool { Calendar.current.isDateInToday(date) }
    private var isFuture: Bool { date > .now && !isToday }

    var body: some View {
        let tint = workout.map { Theme.accent(for: $0.dayType) }
        Text("\(Calendar.current.component(.day, from: date))")
            .font(.subheadline.weight(workout != nil || isToday ? .bold : .regular))
            .monospacedDigit()
            .foregroundStyle(tint ?? (isFuture ? Theme.textTertiary : Theme.textSecondary))
            .frame(width: 38, height: 38)
            .background {
                if let tint { Circle().fill(tint.opacity(0.18)) }
            }
            .overlay {
                if isToday { Circle().strokeBorder(Theme.textPrimary.opacity(0.8), lineWidth: 1.5) }
            }
            .frame(maxWidth: .infinity, minHeight: 40)
            .accessibilityElement()
            .accessibilityLabel(date.formatted(date: .complete, time: .omitted))
            .accessibilityValue(workout.map { "\($0.dayType.displayName) day" } ?? "No workout")
    }
}

private struct Legend: View {
    var body: some View {
        HStack(spacing: 0) {
            item("Workout") { Circle().fill(Theme.accent.opacity(0.35)) }
            item("Rest") { Circle().fill(Theme.accent(for: .rest).opacity(0.35)) }
            item("Today") { Circle().strokeBorder(Theme.textPrimary.opacity(0.8), lineWidth: 1.5) }
        }
        .cardStyle(padding: 12)
    }

    private func item(_ title: String, @ViewBuilder swatch: () -> some View) -> some View {
        HStack(spacing: 6) {
            swatch().frame(width: 10, height: 10)
            Text(title).font(.caption.weight(.medium)).foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}
