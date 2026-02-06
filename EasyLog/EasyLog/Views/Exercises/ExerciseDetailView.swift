import SwiftUI

struct ExerciseDetailView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showingEditSheet = false

    let exercise: Exercise

    private var currentExercise: Exercise {
        dataStore.exercise(for: exercise.id) ?? exercise
    }

    private var history: [(session: WorkoutSession, sets: [LoggedSet])] {
        dataStore.sessions(for: exercise.id)
    }

    var body: some View {
        List {
            Section("Details") {
                LabeledContent("Muscle Group", value: currentExercise.muscleGroup)
                LabeledContent("Category", value: currentExercise.category.rawValue)
            }

            Section("History") {
                if history.isEmpty {
                    Text("No logged sets yet")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(history, id: \.session.id) { entry in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(DateFormatters.display.string(from: entry.session.startDate))
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            ForEach(entry.sets) { set in
                                HStack {
                                    Text("Set \(set.setNumber)")
                                        .frame(width: 50, alignment: .leading)
                                    Text("\(set.weight, specifier: "%.1f") kg")
                                        .frame(width: 80, alignment: .trailing)
                                    Text("× \(set.reps)")
                                        .frame(width: 40, alignment: .trailing)
                                    if set.isCompleted {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.caption)
                                    }
                                }
                                .font(.body.monospacedDigit())
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle(currentExercise.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") { showingEditSheet = true }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            ExerciseFormView(exercise: currentExercise)
        }
    }
}
