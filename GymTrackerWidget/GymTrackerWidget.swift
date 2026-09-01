import WidgetKit
import SwiftUI
import SwiftData
import GymTrackerKit

struct GymEntry: TimelineEntry {
    let date: Date
    let snapshot: DashboardSnapshot

    /// Today is always the last entry in `lastSevenDays` (see `DashboardSnapshot.load`).
    var startedToday: Bool { snapshot.lastSevenDays.last?.dayType != nil }
}

struct GymTrackerTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> GymEntry {
        GymEntry(date: .now, snapshot: .empty)
    }

    func getSnapshot(in context: Context, completion: @escaping (GymEntry) -> Void) {
        completion(GymEntry(date: .now, snapshot: currentSnapshot()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GymEntry>) -> Void) {
        let entry = GymEntry(date: .now, snapshot: currentSnapshot())
        let nextMidnight = Calendar.current.nextDate(
            after: .now,
            matching: DateComponents(hour: 0, minute: 5),
            matchingPolicy: .nextTime
        ) ?? .now.addingTimeInterval(6 * 3600)
        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }

    private func currentSnapshot() -> DashboardSnapshot {
        DashboardSnapshot.load(from: SharedModelContainer.make())
    }
}

struct GymTrackerWidget: Widget {
    let kind = "GymTrackerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GymTrackerTimelineProvider()) { entry in
            GymWidgetView(entry: entry)
        }
        .configurationDisplayName("Next Session")
        .description("Shows your next training day and current streak. Tap Start to log today's session without opening the app.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryCircular])
    }
}

struct GymWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: GymEntry

    var body: some View {
        switch family {
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .accessoryRectangular:
            RectangularWidgetView(entry: entry)
        case .accessoryCircular:
            CircularWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Home Screen

private struct SmallWidgetView: View {
    let entry: GymEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.caption2)
                    .foregroundStyle(Theme.accent)
                Text("\(entry.snapshot.streak) DAY STREAK")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(0.5)
                    .foregroundStyle(Theme.textTertiary)
            }

            Spacer()

            Image(systemName: entry.snapshot.nextDayType.symbolName)
                .font(.system(size: 22))
                .foregroundStyle(Theme.accent(for: entry.snapshot.nextDayType))

            Text(entry.snapshot.nextDayType.displayName.uppercased())
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.textPrimary)

            Spacer()

            SessionActionButton(entry: entry)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) { Theme.background }
    }
}

private struct MediumWidgetView: View {
    let entry: GymEntry

    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("NEXT UP")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(Theme.textTertiary)
                HStack(spacing: 8) {
                    Image(systemName: entry.snapshot.nextDayType.symbolName)
                        .font(.system(size: 18))
                        .foregroundStyle(Theme.accent(for: entry.snapshot.nextDayType))
                    Text(entry.snapshot.nextDayType.displayName)
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                }
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill").font(.caption2).foregroundStyle(Theme.accent)
                    Text("\(entry.snapshot.streak)-day streak")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer(minLength: 8)

                SessionActionButton(entry: entry)
            }

            Spacer()

            HStack(spacing: 6) {
                ForEach(entry.snapshot.lastSevenDays) { day in
                    VStack(spacing: 4) {
                        Circle()
                            .fill(day.dayType != nil ? Theme.accent(for: day.dayType!) : Theme.surface)
                            .frame(width: 10, height: 10)
                        Text(day.date.formatted(.dateTime.weekday(.narrow)))
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) { Theme.background }
    }
}

/// The interactive element: starts today's session in-place via `StartSessionIntent` without
/// opening the app, or shows a quiet confirmation once it's already been started.
private struct SessionActionButton: View {
    let entry: GymEntry

    var body: some View {
        if entry.startedToday {
            HStack(spacing: 5) {
                Image(systemName: "checkmark.circle.fill")
                Text("Session started")
            }
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(Theme.accent(for: entry.snapshot.nextDayType))
        } else {
            Button(intent: StartSessionIntent()) {
                HStack(spacing: 5) {
                    Image(systemName: "play.fill")
                    Text("Start \(entry.snapshot.nextDayType.displayName)")
                }
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.black)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Theme.accent(for: entry.snapshot.nextDayType), in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Lock Screen

private struct RectangularWidgetView: View {
    let entry: GymEntry

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: entry.snapshot.nextDayType.symbolName)
                .widgetAccentable()
            VStack(alignment: .leading, spacing: 1) {
                Text(entry.snapshot.nextDayType.displayName)
                    .font(.headline)
                Text("\(entry.snapshot.streak)-day streak")
                    .font(.caption2)
                    .opacity(0.75)
            }
            Spacer(minLength: 0)
        }
        .containerBackground(for: .widget) { Color.clear }
    }
}

private struct CircularWidgetView: View {
    let entry: GymEntry

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: entry.snapshot.nextDayType.symbolName)
                .widgetAccentable()
            Text("\(entry.snapshot.streak)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
        }
        .containerBackground(for: .widget) { Color.clear }
    }
}
