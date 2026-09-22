import SwiftUI
import SwiftData
import GymTrackerKit

/// Units toggle plus a link into each day's exercise editor.
struct SettingsView: View {
    @AppStorage("preferredWeightUnit") private var unitRaw = WeightUnit.lb.rawValue
    @AppStorage(DayNotificationManager.enabledStorageKey) private var reminderEnabled = true
    @State private var dayOverride: DayType? = DayOverrideStore.current

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
                    Picker("Units", selection: unit) {
                        Text("lb").tag(WeightUnit.lb)
                        Text("kg").tag(WeightUnit.kg)
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Theme.surface)
                } header: {
                    Text("Weight Units")
                }

                Section {
                    Toggle("Morning Reminder (8:00 AM)", isOn: $reminderEnabled)
                        .tint(Theme.accent)
                        .listRowBackground(Theme.surface)
                        .onChange(of: reminderEnabled) { _, enabled in
                            if enabled { DayNotificationManager.requestAuthorizationIfNeeded() }
                            DayNotificationManager.refresh()
                        }

                    Picker("Set Current Day", selection: $dayOverride) {
                        Text("Auto").tag(DayType?.none)
                        ForEach(DayType.allCases) { day in
                            Text(day.displayName).tag(DayType?.some(day))
                        }
                    }
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
                            HStack {
                                Image(systemName: day.symbolName).foregroundStyle(Theme.accent(for: day))
                                Text("Manage \(day.displayName) Exercises")
                                    .foregroundStyle(Theme.textPrimary)
                            }
                        }
                        .listRowBackground(Theme.surface)
                    }
                } header: {
                    Text("Exercise Library")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Settings")
        }
    }
}
