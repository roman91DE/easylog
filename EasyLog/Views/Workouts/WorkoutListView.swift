import SwiftUI

struct WorkoutListView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showingTemplateForm = false
    @State private var showingFreeWorkoutAlert = false
    @State private var freeWorkoutName = ""
    @State private var activeSessionNavigation = false

    var body: some View {
        NavigationStack {
            List {
                if let activeSession = dataStore.activeSession {
                    Section {
                        NavigationLink(value: activeSession.id) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Active Workout")
                                        .font(.headline)
                                        .foregroundColor(.green)
                                    Text(activeSession.templateName)
                                        .font(.subheadline)
                                    Text("Started \(DateFormatters.display.string(from: activeSession.startDate))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title2)
                            }
                        }
                    }
                }

                Section("Templates") {
                    if dataStore.templates.isEmpty {
                        VStack(spacing: 8) {
                            Text("No Templates Yet")
                                .font(.headline)
                            Text("Create a template to quickly start workouts")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    } else {
                        ForEach(dataStore.templates) { template in
                            TemplateRow(template: template)
                        }
                        .onDelete(perform: deleteTemplates)
                    }
                }
            }
            .navigationTitle("Workouts")
            .navigationDestination(for: UUID.self) { sessionID in
                if let session = dataStore.sessions.first(where: { $0.id == sessionID }) {
                    ActiveWorkoutView(session: session)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button { showingTemplateForm = true } label: {
                            Label("New Template", systemImage: "doc.badge.plus")
                        }
                        Button { showingFreeWorkoutAlert = true } label: {
                            Label("Free Workout", systemImage: "figure.run")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingTemplateForm) {
                TemplateFormView(template: nil)
            }
            .alert("Free Workout", isPresented: $showingFreeWorkoutAlert) {
                TextField("Workout name", text: $freeWorkoutName)
                Button("Start") {
                    let name = freeWorkoutName.trimmingCharacters(in: .whitespaces)
                    guard !name.isEmpty else { return }
                    let _ = dataStore.startFreeSession(name: name)
                    freeWorkoutName = ""
                }
                Button("Cancel", role: .cancel) { freeWorkoutName = "" }
            } message: {
                Text("Enter a name for your workout")
            }
        }
    }

    private func deleteTemplates(at offsets: IndexSet) {
        for index in offsets {
            dataStore.deleteTemplate(dataStore.templates[index])
        }
    }
}

private struct TemplateRow: View {
    @EnvironmentObject var dataStore: DataStore
    let template: WorkoutTemplate
    @State private var showingEdit = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(template.name)
                    .font(.headline)
                Spacer()
                if dataStore.activeSession == nil {
                    Button("Start") {
                        let _ = dataStore.startSession(from: template)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }

            let validIDs = dataStore.validExerciseIDs(in: template)
            let removed = dataStore.removedExerciseCount(in: template)
            let exerciseNames = validIDs.compactMap { dataStore.exercise(for: $0)?.name }

            if !exerciseNames.isEmpty {
                Text(exerciseNames.joined(separator: ", "))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            if removed > 0 {
                Text("\(removed) exercise(s) removed")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { showingEdit = true }
        .sheet(isPresented: $showingEdit) {
            TemplateFormView(template: template)
        }
    }
}
