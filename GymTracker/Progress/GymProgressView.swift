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
        case weight = "Weight"
        case volume = "Volume"
        var id: String { rawValue }
    }

    private var trainableExercises: [Exercise] {
        exercises.filter { !$0.isArchived && $0.dayType != .rest }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                VStack(spacing: 16) {
                    Picker("Exercise", selection: $selected) {
                        Text("Select an exercise").tag(Exercise?.none)
                        ForEach(trainableExercises) { ex in
                            Text(ex.name).tag(Optional(ex))
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Theme.accent)
                    .padding(.horizontal)

                    if let exercise = selected {
                        Picker("Metric", selection: $metric) {
                            ForEach(Metric.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)

                        ExerciseProgressChart(exercise: exercise, metric: metric, unit: unit)
                    } else {
                        Spacer()
                        Text("Pick an exercise to see its progression")
                            .foregroundStyle(Theme.textSecondary)
                        Spacer()
                    }
                }
                .padding(.top, 12)
            }
            .navigationTitle("Progress")
        }
        .onAppear {
            if selected == nil { selected = trainableExercises.first }
        }
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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isLatestANewBest {
                Label("New personal best!", systemImage: "flame.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.accent(for: exercise.dayType))
                    .padding(.horizontal)
            }

            if points.isEmpty {
                Spacer()
                Text("No data yet for this exercise")
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
            } else {
                Chart {
                    ForEach(points) { point in
                        LineMark(x: .value("Date", point.date), y: .value(metric.rawValue, point.value))
                            .foregroundStyle(Theme.accent(for: exercise.dayType))
                            .interpolationMethod(.catmullRom)
                        PointMark(x: .value("Date", point.date), y: .value(metric.rawValue, point.value))
                            .foregroundStyle(Theme.accent(for: exercise.dayType))
                    }
                    if let best = personalBest {
                        PointMark(x: .value("Date", best.date), y: .value(metric.rawValue, best.value))
                            .symbolSize(140)
                            .foregroundStyle(Theme.textPrimary)
                            .annotation(position: .top) {
                                Text("Best").font(.caption2.weight(.bold)).foregroundStyle(Theme.textPrimary)
                            }
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisGridLine().foregroundStyle(Theme.divider)
                        AxisValueLabel().foregroundStyle(Theme.textTertiary)
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine().foregroundStyle(Theme.divider)
                        AxisValueLabel().foregroundStyle(Theme.textTertiary)
                    }
                }
                .padding()
                .cardStyle()
                .padding(.horizontal)
            }
        }
    }
}
