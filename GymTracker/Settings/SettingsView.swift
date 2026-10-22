import SwiftUI
import SwiftData
import GymTrackerKit

/// Units toggle plus a link into each day's exercise editor.
struct SettingsView: View {
    @AppStorage("preferredWeightUnit") private var unitRaw = WeightUnit.lb.rawValue
    @AppStorage(DayNotificationManager.enabledStorageKey) private var reminderEnabled = true
    @State private var dayOverride: DayType? = DayOverrideStore.current
    @Query(filter: #Predicate<Exercise> { !$0.isArchived }) private var exercises: [Exercise]

    private var unit: Binding<WeightUnit> {
        Binding(
            get: { WeightUnit(rawValue: unitRaw) ?? .lb },
            set: { unitRaw = $0.rawValue }
        )
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        SettingsLabel("Units", systemImage: "scalemass.fill", tint: Theme.accent(for: .pull))
                        Spacer()
                        Picker("Units", selection: unit) {
                            Text("lb").tag(WeightUnit.lb)
                            Text("kg").tag(WeightUnit.kg)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .frame(width: 112)
                    }
                    .listRowBackground(Theme.surface)
                } header: {
                    Text("Weight Units")
                }

                Section {
                    Toggle(isOn: $reminderEnabled) {
                        SettingsLabel("Morning Reminder", detail: "8:00 AM", systemImage: "bell.badge.fill", tint: Theme.accent)
                    }
                        .tint(Theme.accent)
                        .listRowBackground(Theme.surface)
                        .onChange(of: reminderEnabled) { _, enabled in
                            if enabled { DayNotificationManager.requestAuthorizationIfNeeded() }
                            DayNotificationManager.refresh()
                        }

                    Picker(selection: $dayOverride) {
                        Text("Auto").tag(DayType?.none)
                        ForEach(DayType.allCases) { day in
                            Text(day.displayName).tag(DayType?.some(day))
                        }
                    } label: {
                        SettingsLabel("Current Day", systemImage: "calendar.badge.clock", tint: Theme.accent(for: .legs))
                    }
                    .tint(Theme.textSecondary)
                    .listRowBackground(Theme.surface)
                    .onChange(of: dayOverride) { _, newValue in
                        DayOverrideStore.current = newValue
                        DayNotificationManager.refresh()
                    }
                } header: {
                    Text("Training Day")
                } footer: {
                    Text("Overrides the automatic Push → Pull → Legs → Rest rotation until you start a session, and updates the 8:00 AM reminder right away.")
                }

                Section {
                    ForEach([DayType.push, .pull, .legs]) { day in
                        NavigationLink {
                            ExerciseEditorView(dayType: day)
                        } label: {
                            LabeledContent {
                                Text("\(exercises.filter { $0.dayType == day }.count)")
                                    .monospacedDigit()
                                    .foregroundStyle(Theme.textTertiary)
                            } label: {
                                SettingsLabel("\(day.displayName) Exercises", systemImage: day.symbolName, tint: Theme.accent(for: day))
                            }
                        }
                        .listRowBackground(Theme.surface)
                    }
                } header: {
                    Text("Exercise Library")
                } footer: {
                    Text("Add, rename, reorder, or remove exercises. Removed exercises keep their history.")
                }
            }
            .listSectionSpacing(.compact)
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Settings")
        }
    }
}

/// A Settings-style row label: a colored icon tile, a title, and an optional quiet detail.
private struct SettingsLabel: View {
    let title: String
    var detail: String?
    let systemImage: String
    let tint: Color

    init(_ title: String, detail: String? = nil, systemImage: String, tint: Color) {
        self.title = title
        self.detail = detail
        self.systemImage = systemImage
        self.tint = tint
    }

    var body: some View {
        HStack(spacing: 12) {
            IconTile(systemName: systemImage, tint: tint, size: 30)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).foregroundStyle(Theme.textPrimary)
                if let detail {
                    Text(detail).font(.caption).foregroundStyle(Theme.textTertiary)
                }
            }
        }
    }
}
