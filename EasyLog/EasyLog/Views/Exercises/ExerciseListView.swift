import SwiftUI

struct ExerciseListView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var searchText = ""
    @State private var showingAddSheet = false

    var filteredExercises: [Exercise] {
        if searchText.isEmpty {
            return dataStore.exercises.sorted { $0.name < $1.name }
        }
        return dataStore.exercises
            .filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.muscleGroup.localizedCaseInsensitiveContains(searchText) }
            .sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationStack {
            Group {
                if dataStore.exercises.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "dumbbell")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No Exercises Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Tap + to add your first exercise")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredExercises) { exercise in
                            NavigationLink(value: exercise) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(exercise.name)
                                        .font(.headline)
                                    HStack {
                                        Text(exercise.muscleGroup)
                                        Text("·")
                                        Text(exercise.category.rawValue)
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                }
                            }
                        }
                        .onDelete(perform: deleteExercises)
                    }
                    .searchable(text: $searchText, prompt: "Search exercises")
                }
            }
            .navigationTitle("Exercises")
            .navigationDestination(for: Exercise.self) { exercise in
                ExerciseDetailView(exercise: exercise)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAddSheet = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                ExerciseFormView(exercise: nil)
            }
        }
    }

    private func deleteExercises(at offsets: IndexSet) {
        let sorted = filteredExercises
        for index in offsets {
            dataStore.deleteExercise(sorted[index])
        }
    }
}
