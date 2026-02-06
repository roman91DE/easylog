import SwiftUI

struct ActiveWorkoutView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) var dismiss

    let session: WorkoutSession
    @State private var showingFinishAlert = false
    @State private var showingAddExerciseSheet = false
    @State private var showingDiscardAlert = false

    private var currentSession: WorkoutSession {
        dataStore.sessions.first { $0.id == session.id } ?? session
    }

    private var exerciseIDsInSession: [UUID] {
        var seen = Set<UUID>()
        var ordered: [UUID] = []

        // Start with template exercises
        if let templateID = currentSession.templateID,
           let template = dataStore.templates.first(where: { $0.id == templateID }) {
            for id in template.exerciseIDs {
                if seen.insert(id).inserted {
                    ordered.append(id)
                }
            }
        }

        // Add any exercises that have sets but aren't in the template
        for set in currentSession.sets {
            if seen.insert(set.exerciseID).inserted {
                ordered.append(set.exerciseID)
            }
        }

        return ordered
    }

    var body: some View {
        List {
            Section {
                HStack {
                    VStack(alignment: .leading) {
                        Text(currentSession.templateName)
                            .font(.headline)
                        Text("Started \(DateFormatters.display.string(from: currentSession.startDate))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(currentSession.totalSetsCount) sets · \(currentSession.totalRepsCount) reps · \(currentSession.totalVolume, specifier: "%.0f") kg")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(DateFormatters.duration(from: currentSession.startDate, to: Date()))
                        .font(.title3.monospacedDigit())
                        .foregroundColor(.secondary)
                }
            }

            ForEach(exerciseIDsInSession, id: \.self) { exerciseID in
                ExerciseSetSection(
                    sessionID: currentSession.id,
                    exerciseID: exerciseID,
                    exerciseName: dataStore.exercise(for: exerciseID)?.name ?? "Unknown Exercise"
                )
            }

            Section {
                Button { showingAddExerciseSheet = true } label: {
                    Label("Add Exercise", systemImage: "plus.circle")
                }
            }
        }
        .navigationTitle("Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button { showingFinishAlert = true } label: {
                        Label("Finish Workout", systemImage: "checkmark.circle")
                    }
                    Button(role: .destructive) { showingDiscardAlert = true } label: {
                        Label("Discard Workout", systemImage: "trash")
                    }
                } label: {
                    Text("Done")
                        .fontWeight(.semibold)
                }
            }
        }
        .alert("Finish Workout?", isPresented: $showingFinishAlert) {
            Button("Finish", role: .destructive) {
                dataStore.finishSession(currentSession)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            let completedSets = currentSession.sets.filter { $0.isCompleted }.count
            Text("\(completedSets) completed set(s) will be saved.")
        }
        .alert("Discard Workout?", isPresented: $showingDiscardAlert) {
            Button("Discard", role: .destructive) {
                dataStore.deleteSession(currentSession)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This workout and all logged sets will be permanently deleted.")
        }
        .sheet(isPresented: $showingAddExerciseSheet) {
            AddExerciseToSessionView(sessionID: currentSession.id)
        }
    }
}

private struct ExerciseSetSection: View {
    @EnvironmentObject var dataStore: DataStore
    let sessionID: UUID
    let exerciseID: UUID
    let exerciseName: String

    private var sets: [LoggedSet] {
        guard let session = dataStore.sessions.first(where: { $0.id == sessionID }) else { return [] }
        return session.sets
            .filter { $0.exerciseID == exerciseID }
            .sorted { $0.setNumber < $1.setNumber }
    }

    var body: some View {
        Section {
            ForEach(sets) { set in
                SetRow(sessionID: sessionID, set: set)
            }
            .onDelete { offsets in
                let setsToDelete = offsets.map { sets[$0] }
                for set in setsToDelete {
                    dataStore.deleteSet(in: sessionID, setID: set.id)
                }
            }

            Button { addSet() } label: {
                Label("Add Set", systemImage: "plus")
                    .font(.subheadline)
            }
        } header: {
            Text(exerciseName)
        }
    }

    private func addSet() {
        let nextNumber = (sets.last?.setNumber ?? 0) + 1
        let previousSet = sets.last
        let newSet = LoggedSet(
            exerciseID: exerciseID,
            setNumber: nextNumber,
            weight: previousSet?.weight ?? 0,
            reps: previousSet?.reps ?? 0
        )
        dataStore.addSet(to: sessionID, set: newSet)
    }
}

private struct SetRow: View {
    @EnvironmentObject var dataStore: DataStore
    let sessionID: UUID
    let set: LoggedSet

    @State private var weightText: String
    @State private var repsText: String

    init(sessionID: UUID, set: LoggedSet) {
        self.sessionID = sessionID
        self.set = set
        _weightText = State(initialValue: set.weight == 0 ? "" : "\(set.weight)")
        _repsText = State(initialValue: set.reps == 0 ? "" : "\(set.reps)")
    }

    var body: some View {
        HStack(spacing: 12) {
            Text("\(set.setNumber)")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.secondary)
                .frame(width: 24)

            HStack(spacing: 4) {
                TextField("0", text: $weightText)
                    .keyboardType(.decimalPad)
                    .frame(width: 60)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: weightText) { _ in updateSet() }
                Text("kg")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 4) {
                TextField("0", text: $repsText)
                    .keyboardType(.numberPad)
                    .frame(width: 50)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: repsText) { _ in updateSet() }
                Text("reps")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                var updated = set
                updated.isCompleted.toggle()
                dataStore.updateSet(in: sessionID, set: updated)
            } label: {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(set.isCompleted ? .green : .gray)
                    .font(.title2)
            }
            .buttonStyle(.plain)
        }
    }

    private func updateSet() {
        var updated = set
        updated.weight = Double(weightText) ?? 0
        updated.reps = Int(repsText) ?? 0
        dataStore.updateSet(in: sessionID, set: updated)
    }
}

private struct AddExerciseToSessionView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) var dismiss
    let sessionID: UUID

    var body: some View {
        NavigationStack {
            List {
                ForEach(dataStore.exercises.sorted { $0.name < $1.name }) { exercise in
                    Button {
                        let newSet = LoggedSet(exerciseID: exercise.id, setNumber: 1)
                        dataStore.addSet(to: sessionID, set: newSet)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading) {
                            Text(exercise.name)
                                .foregroundColor(.primary)
                            Text("\(dataStore.muscleGroupNamesJoined(for: exercise)) · \(exercise.category.rawValue)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

private extension WorkoutSession {
    var totalSetsCount: Int {
        sets.count
    }

    var totalRepsCount: Int {
        sets.reduce(0) { $0 + $1.reps }
    }

    var totalVolume: Double {
        sets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }
}
