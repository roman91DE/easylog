import SwiftUI

struct ExerciseFormView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) var dismiss

    let exercise: Exercise?

    @State private var name: String
    @State private var selectedMuscleGroupIDs: Set<UUID>
    @State private var category: Exercise.Category
    @State private var newMuscleGroupName = ""

    private var isEditing: Bool { exercise != nil }

    init(exercise: Exercise?) {
        self.exercise = exercise
        _name = State(initialValue: exercise?.name ?? "")
        _selectedMuscleGroupIDs = State(initialValue: Set(exercise?.muscleGroupIDs ?? []))
        _category = State(initialValue: exercise?.category ?? .barbell)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Exercise name", text: $name)
                        .autocorrectionDisabled()
                }

                Section {
                    ForEach(dataStore.muscleGroups) { group in
                        Button {
                            toggleGroup(group.id)
                        } label: {
                            HStack {
                                Text(group.name)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedMuscleGroupIDs.contains(group.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }

                    HStack {
                        TextField("New muscle group", text: $newMuscleGroupName)
                            .autocorrectionDisabled()
                        Button {
                            addCustomMuscleGroup()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                        .disabled(newMuscleGroupName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                } header: {
                    Text("Muscle Groups")
                } footer: {
                    if !selectedMuscleGroupIDs.isEmpty {
                        let names = dataStore.muscleGroups
                            .filter { selectedMuscleGroupIDs.contains($0.id) }
                            .map { $0.name }
                        Text("Selected: \(names.joined(separator: ", "))")
                    }
                }

                Section("Category") {
                    Menu {
                        ForEach(Exercise.Category.allCases, id: \.self) { cat in
                            Button {
                                category = cat
                            } label: {
                                if cat == category {
                                    Label(cat.rawValue, systemImage: "checkmark")
                                } else {
                                    Text(cat.rawValue)
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text("Category")
                            Spacer()
                            Text(category.rawValue)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Exercise" : "New Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func toggleGroup(_ id: UUID) {
        if selectedMuscleGroupIDs.contains(id) {
            selectedMuscleGroupIDs.remove(id)
        } else {
            selectedMuscleGroupIDs.insert(id)
        }
    }

    private func addCustomMuscleGroup() {
        let trimmed = newMuscleGroupName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let group = dataStore.findOrCreateMuscleGroup(named: trimmed)
        selectedMuscleGroupIDs.insert(group.id)
        newMuscleGroupName = ""
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        // Preserve order from the muscleGroups array
        let orderedIDs = dataStore.muscleGroups
            .filter { selectedMuscleGroupIDs.contains($0.id) }
            .map { $0.id }

        if let existing = exercise {
            var updated = existing
            updated.name = trimmedName
            updated.muscleGroupIDs = orderedIDs
            updated.category = category
            dataStore.updateExercise(updated)
        } else {
            let newExercise = Exercise(
                name: trimmedName,
                muscleGroupIDs: orderedIDs,
                category: category
            )
            dataStore.addExercise(newExercise)
        }
        dismiss()
    }
}
