import SwiftUI

struct ExerciseFormView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) var dismiss

    let exercise: Exercise?

    @State private var name: String
    @State private var muscleGroup: String
    @State private var category: Exercise.Category

    private var isEditing: Bool { exercise != nil }

    static let commonMuscleGroups = ["Chest", "Back", "Shoulders", "Biceps", "Triceps", "Legs", "Glutes", "Core", "Full Body", "Cardio"]

    init(exercise: Exercise?) {
        self.exercise = exercise
        _name = State(initialValue: exercise?.name ?? "")
        _muscleGroup = State(initialValue: exercise?.muscleGroup ?? "")
        _category = State(initialValue: exercise?.category ?? .barbell)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Exercise name", text: $name)
                        .autocorrectionDisabled()
                }

                Section("Muscle Group") {
                    TextField("Muscle group", text: $muscleGroup)
                        .autocorrectionDisabled()

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(Self.commonMuscleGroups, id: \.self) { group in
                                Button(group) {
                                    muscleGroup = group
                                }
                                .buttonStyle(.bordered)
                                .tint(muscleGroup == group ? .blue : .gray)
                            }
                        }
                    }
                }

                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(Exercise.Category.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                    .pickerStyle(.segmented)
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

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedGroup = muscleGroup.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        if let existing = exercise {
            var updated = existing
            updated.name = trimmedName
            updated.muscleGroup = trimmedGroup.isEmpty ? "Other" : trimmedGroup
            updated.category = category
            dataStore.updateExercise(updated)
        } else {
            let newExercise = Exercise(
                name: trimmedName,
                muscleGroup: trimmedGroup.isEmpty ? "Other" : trimmedGroup,
                category: category
            )
            dataStore.addExercise(newExercise)
        }
        dismiss()
    }
}
