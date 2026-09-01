import SwiftUI
import SwiftData
import GymTrackerKit

/// A month grid of dots colored by day type, plus the current streak — which days were trained,
/// which day type each was, and which were rest days.
struct CalendarStreakView: View {
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]
    @State private var monthOffset = 0

    private var calendar: Calendar { .current }

    private var displayedMonth: Date {
        calendar.date(byAdding: .month, value: monthOffset, to: .now) ?? .now
    }

    private var streak: Int { StreakCalculator.currentStreak(workouts: workouts) }

    private var daysInMonth: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))
        else { return [] }

        let leadingEmpty = (calendar.component(.weekday, from: firstOfMonth) - calendar.firstWeekday + 7) % 7
        var days: [Date?] = Array(repeating: nil, count: leadingEmpty)
        days += range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: firstOfMonth) }
        return days
    }

    private func workout(on date: Date) -> Workout? {
        workouts.first { calendar.isDate($0.date, inSameDayAs: date) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                VStack(spacing: 24) {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill").foregroundStyle(Theme.accent)
                        Text("\(streak)-day streak")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .padding(.top, 8)

                    HStack {
                        Button { monthOffset -= 1 } label: {
                            Image(systemName: "chevron.left").foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                        Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                            .font(.headline)
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Button { monthOffset += 1 } label: {
                            Image(systemName: "chevron.right").foregroundStyle(Theme.textSecondary)
                        }
                    }
                    .padding(.horizontal, 32)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                        ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, date in
                            if let date {
                                if let workout = workout(on: date) {
                                    NavigationLink {
                                        WorkoutDayDetailView(workout: workout)
                                    } label: {
                                        DayCell(date: date, workout: workout)
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    DayCell(date: date, workout: nil)
                                }
                            } else {
                                Color.clear.frame(height: 36)
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    Legend().padding(.top, 8)

                    Spacer()
                }
            }
            .navigationTitle("Calendar")
        }
    }
}

private struct DayCell: View {
    let date: Date
    let workout: Workout?

    var body: some View {
        VStack(spacing: 3) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.caption2.weight(.medium))
                .foregroundStyle(Theme.textSecondary)
            Circle()
                .fill(workout != nil ? Theme.accent(for: workout!.dayType) : Theme.surface)
                .frame(width: 8, height: 8)
        }
        .frame(height: 36)
    }
}

private struct Legend: View {
    var body: some View {
        HStack(spacing: 14) {
            ForEach(DayType.allCases) { day in
                HStack(spacing: 5) {
                    Circle().fill(Theme.accent(for: day)).frame(width: 7, height: 7)
                    Text(day.displayName).font(.caption2).foregroundStyle(Theme.textTertiary)
                }
            }
        }
    }
}
