import SwiftUI

struct ExercisePickerView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) var dismiss
    @Binding var selectedIDs: [UUID]
    @State private var searchText = ""

    private var groupedExercises: [(String, [Exercise])] {
        let filtered: [Exercise]
        if searchText.isEmpty {
            filtered = dataStore.exercises
        } else {
            filtered = dataStore.exercises.filter { exercise in
                exercise.name.localizedCaseInsensitiveContains(searchText) ||
                dataStore.muscleGroupNames(for: exercise).contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }

        let grouped = Dictionary(grouping: filtered) { dataStore.primaryMuscleGroupName(for: $0) }
        return grouped.sorted { $0.key < $1.key }
    }

    var body: some View {
        NavigationStack {
            List {
                if dataStore.exercises.isEmpty {
                    Text("No exercises available. Add exercises in the Exercises tab first.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(groupedExercises, id: \.0) { group, exercises in
                        Section(group) {
                            ForEach(exercises) { exercise in
                                Button {
                                    toggleSelection(exercise.id)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(exercise.name)
                                                .foregroundColor(.primary)
                                            Text(exercise.category.rawValue)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        if selectedIDs.contains(exercise.id) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search exercises")
            .navigationTitle("Select Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func toggleSelection(_ id: UUID) {
        if let index = selectedIDs.firstIndex(of: id) {
            selectedIDs.remove(at: index)
        } else {
            selectedIDs.append(id)
        }
    }
}
