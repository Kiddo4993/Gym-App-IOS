import SwiftUI
import SwiftData
import Charts
import GymTrackerKit

/// Per-exercise progression: a chart of working weight or estimated volume over time, with the
/// best session highlighted.
struct GymProgressView: View {
    @Query(sort: [SortDescriptor(\Exercise.dayTypeRaw), SortDescriptor(\Exercise.sortOrder)])
    private var exercises: [Exercise]
    @AppStorage("preferredWeightUnit") private var unitRaw = WeightUnit.lb.rawValue

    @State private var selected: Exercise?
    @State private var metric: Metric = .weight

    private var unit: WeightUnit { WeightUnit(rawValue: unitRaw) ?? .lb }

    enum Metric: String, CaseIterable, Identifiable {
        case weight = "Top Weight"
        case volume = "Volume"
        var id: String { rawValue }
    }

    private var trainableExercises: [Exercise] {
        exercises.filter { !$0.isArchived && $0.dayType != .rest }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    exerciseMenu

                    if let exercise = selected {
                        Picker("Metric", selection: $metric) {
                            ForEach(Metric.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)

                        ExerciseProgressChart(exercise: exercise, metric: metric, unit: unit)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Progress")
        }
        .onAppear {
            if selected == nil { selected = trainableExercises.first }
        }
    }

    /// A card-sized menu button: the native `.menu` picker is a small tinted link that's easy
    /// to miss, and the exercise choice drives everything else on this screen.
    private var exerciseMenu: some View {
        Menu {
            ForEach([DayType.push, .pull, .legs]) { day in
                Section(day.displayName) {
                    ForEach(trainableExercises.filter { $0.dayType == day }) { ex in
                        Button(ex.name) { selected = ex }
                    }
                }
            }
        } label: {
            HStack(spacing: 12) {
                IconTile(
                    systemName: selected?.dayType.symbolName ?? "dumbbell",
                    tint: selected.map { Theme.accent(for: $0.dayType) } ?? Theme.accent,
                    size: 40
                )
                VStack(alignment: .leading, spacing: 2) {
                    Text("EXERCISE")
                        .font(.caption2.weight(.bold))
                        .tracking(1.2)
                        .foregroundStyle(Theme.textTertiary)
                    Text(selected?.name ?? "Choose an exercise")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
            .cardStyle(padding: 14)
        }
        .buttonStyle(PressableRowStyle())
    }
}

private struct ProgressPoint: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let value: Double
}

private struct ExerciseProgressChart: View {
    let exercise: Exercise
    let metric: GymProgressView.Metric
    let unit: WeightUnit

    private var tint: Color { Theme.accent(for: exercise.dayType) }

    private var points: [ProgressPoint] {
        let sessions = (exercise.logs ?? [])
            .compactMap { log -> (Date, [SetLog])? in
                guard let date = log.workout?.date, let sets = log.sets, !sets.isEmpty else { return nil }
                return (date, sets)
            }
            .sorted { $0.0 < $1.0 }

        return sessions.map { date, sets in
            let value: Double
            switch metric {
            case .weight: value = VolumeCalculator.topWeight(for: sets, in: unit)
            case .volume: value = VolumeCalculator.estimatedVolume(for: sets, in: unit)
            }
            return ProgressPoint(date: date, value: value)
        }
    }

    private var personalBest: ProgressPoint? {
        points.max { $0.value < $1.value }
    }

    private var isLatestANewBest: Bool {
        guard let last = points.last, let best = personalBest else { return false }
        return last.id == best.id && points.dropLast().allSatisfy { $0.value < last.value }
    }

    /// Percent change from the first logged session to the latest one.
    private var changeText: String {
        guard let first = points.first?.value, let last = points.last?.value, first > 0, points.count > 1 else { return "–" }
        let pct = (last - first) / first * 100
        return (pct >= 0 ? "+" : "") + String(format: "%.0f%%", pct)
    }

    var body: some View {
        if points.isEmpty {
            ContentUnavailableView(
                "No data yet",
                systemImage: "chart.xyaxis.line",
                description: Text("Log \(exercise.name) in a session and your progress shows up here.")
            )
            .padding(.top, 40)
        } else {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 10) {
                    StatTile(value: personalBest.map { $0.value.weightText } ?? "–", label: "Best (\(unit.symbol))", systemImage: "trophy.fill", tint: tint)
                    StatTile(value: points.last.map { $0.value.weightText } ?? "–", label: "Latest", systemImage: "clock")
                    StatTile(value: changeText, label: "Change", systemImage: "arrow.up.right")
                }

                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text(metric == .weight ? "Top set weight" : "Estimated volume")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        if isLatestANewBest {
                            Label("New best", systemImage: "flame.fill")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(tint, in: Capsule())
                        }
                    }

                    chart
                        .frame(height: 220)
                }
                .cardStyle(padding: 16)

                Text("\(points.count) sessions logged · partial reps count at half weight in volume.")
                    .font(.caption)
                    .foregroundStyle(Theme.textTertiary)
            }
        }
    }

    private var chart: some View {
        Chart {
            ForEach(points) { point in
                AreaMark(x: .value("Date", point.date), y: .value(metric.rawValue, point.value))
                    .foregroundStyle(LinearGradient(colors: [tint.opacity(0.28), tint.opacity(0)], startPoint: .top, endPoint: .bottom))
                    .interpolationMethod(.monotone)
                LineMark(x: .value("Date", point.date), y: .value(metric.rawValue, point.value))
                    .foregroundStyle(tint)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .interpolationMethod(.monotone)
            }
            if let best = personalBest {
                PointMark(x: .value("Date", best.date), y: .value(metric.rawValue, best.value))
                    .symbolSize(90)
                    .foregroundStyle(Theme.textPrimary)
                    .annotation(position: .top, spacing: 6) {
                        Text(best.value.weightText)
                            .font(.caption2.weight(.bold))
                            .monospacedDigit()
                            .foregroundStyle(Theme.textPrimary)
                    }
            }
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine().foregroundStyle(Theme.divider)
                AxisValueLabel(format: .dateTime.month(.abbreviated).day()).foregroundStyle(Theme.textTertiary)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine().foregroundStyle(Theme.divider)
                AxisValueLabel().foregroundStyle(Theme.textTertiary)
            }
        }
        .accessibilityLabel("\(metric.rawValue) chart for \(exercise.name)")
        .accessibilityValue("Best \(personalBest?.value.weightText ?? "none"), latest \(points.last?.value.weightText ?? "none")")
    }
}
