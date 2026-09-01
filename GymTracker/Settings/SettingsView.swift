import SwiftUI
import SwiftData
import GymTrackerKit

/// Units toggle plus a link into each day's exercise editor.
struct SettingsView: View {
    @AppStorage("preferredWeightUnit") private var unitRaw = WeightUnit.lb.rawValue

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
