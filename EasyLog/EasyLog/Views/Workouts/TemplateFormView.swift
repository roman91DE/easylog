import SwiftUI

struct TemplateFormView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) var dismiss

    let template: WorkoutTemplate?

    @State private var name: String
    @State private var exerciseIDs: [UUID]
    @State private var showingExercisePicker = false

    private var isEditing: Bool { template != nil }

    init(template: WorkoutTemplate?) {
        self.template = template
        _name = State(initialValue: template?.name ?? "")
        _exerciseIDs = State(initialValue: template?.exerciseIDs ?? [])
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Template name", text: $name)
                }

                Section {
                    if exerciseIDs.isEmpty {
                        Text("No exercises added")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(exerciseIDs, id: \.self) { exerciseID in
                            if let exercise = dataStore.exercise(for: exerciseID) {
                                HStack {
                                    Text(exercise.name)
                                    Spacer()
                                    Text(dataStore.muscleGroupNamesJoined(for: exercise))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Text("Unknown Exercise")
                                    .foregroundColor(.red)
                            }
                        }
                        .onDelete { offsets in
                            exerciseIDs.remove(atOffsets: offsets)
                        }
                        .onMove { from, to in
                            exerciseIDs.move(fromOffsets: from, toOffset: to)
                        }
                    }

                    Button { showingExercisePicker = true } label: {
                        Label("Add Exercises", systemImage: "plus.circle")
                    }
                } header: {
                    Text("Exercises")
                } footer: {
                    if !exerciseIDs.isEmpty {
                        Text("Drag to reorder, swipe to remove")
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Template" : "New Template")
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
            .environment(\.editMode, .constant(.active))
            .sheet(isPresented: $showingExercisePicker) {
                ExercisePickerView(selectedIDs: $exerciseIDs)
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        if let existing = template {
            var updated = existing
            updated.name = trimmedName
            updated.exerciseIDs = exerciseIDs
            dataStore.updateTemplate(updated)
        } else {
            let newTemplate = WorkoutTemplate(name: trimmedName, exerciseIDs: exerciseIDs)
            dataStore.addTemplate(newTemplate)
        }
        dismiss()
    }
}
