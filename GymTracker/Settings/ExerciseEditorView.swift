import SwiftUI
import SwiftData
import GymTrackerKit

/// Add, rename, reorder, or remove exercises within one day type. Removing archives an exercise
/// rather than deleting it, so its history stays intact.
struct ExerciseEditorView: View {
    let dayType: DayType

    @Environment(\.modelContext) private var context
    @Query private var dayExercises: [Exercise]
    @State private var showingAdd = false
    @State private var newName = ""
    @State private var newMuscle = ""

    init(dayType: DayType) {
        self.dayType = dayType
        let dayRaw = dayType.rawValue
        _dayExercises = Query(
            filter: #Predicate<Exercise> { $0.dayTypeRaw == dayRaw && !$0.isArchived },
            sort: [SortDescriptor(\.sortOrder)]
        )
    }

    var body: some View {
        List {
            ForEach(dayExercises) { exercise in
                HStack {
                    TextField("Name", text: Binding(
                        get: { exercise.name },
                        set: { exercise.name = $0; try? context.save() }
                    ))
                    .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Text(exercise.muscleGroup)
                        .font(.caption)
                        .foregroundStyle(Theme.textTertiary)
                }
                .listRowBackground(Theme.surface)
            }
            .onMove(perform: move)
            .onDelete(perform: archive)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("\(dayType.displayName) Exercises")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAdd = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .foregroundStyle(Theme.accent(for: dayType))
            }
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton().foregroundStyle(Theme.textSecondary)
            }
        }
        .alert("New Exercise", isPresented: $showingAdd) {
            TextField("Name", text: $newName)
            TextField("Muscle group", text: $newMuscle)
            Button("Cancel", role: .cancel) { newName = ""; newMuscle = "" }
            Button("Add") { addExercise() }
        }
    }

    private func addExercise() {
        let trimmedName = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        let nextOrder = (dayExercises.map(\.sortOrder).max() ?? -1) + 1
        let muscle = newMuscle.trimmingCharacters(in: .whitespaces)
        let exercise = Exercise(
            name: trimmedName,
            muscleGroup: muscle.isEmpty ? dayType.displayName : muscle,
            dayType: dayType,
            sortOrder: nextOrder
        )
        context.insert(exercise)
        try? context.save()
        newName = ""
        newMuscle = ""
    }

    private func move(from source: IndexSet, to destination: Int) {
        var reordered = dayExercises
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, exercise) in reordered.enumerated() {
            exercise.sortOrder = index
        }
        try? context.save()
    }

    private func archive(at offsets: IndexSet) {
        for index in offsets {
            dayExercises[index].isArchived = true
        }
        try? context.save()
    }
}
