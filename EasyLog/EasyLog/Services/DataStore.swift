import Foundation

class DataStore: ObservableObject {
    @Published var exercises: [Exercise] = []
    @Published var templates: [WorkoutTemplate] = []
    @Published var sessions: [WorkoutSession] = []
    @Published var muscleGroups: [MuscleGroup] = []

    private let documentsURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(directory: URL? = nil) {
        let dir = directory ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.documentsURL = dir
        self.encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        self.decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        muscleGroups = load(filename: "muscleGroups.json") ?? []
        if muscleGroups.isEmpty {
            muscleGroups = MuscleGroup.defaultGroups
            saveMuscleGroups()
        }

        exercises = load(filename: "exercises.json") ?? []
        templates = load(filename: "templates.json") ?? []
        sessions = load(filename: "sessions.json") ?? []
    }

    // MARK: - Persistence

    private func fileURL(_ filename: String) -> URL {
        documentsURL.appendingPathComponent(filename)
    }

    private func backupURL(_ filename: String) -> URL {
        documentsURL.appendingPathComponent(filename + ".bak")
    }

    private func load<T: Decodable>(filename: String) -> T? {
        let primary = fileURL(filename)
        let backup = backupURL(filename)

        if let data = try? Data(contentsOf: primary),
           let value = try? decoder.decode(T.self, from: data) {
            return value
        }

        if let data = try? Data(contentsOf: backup),
           let value = try? decoder.decode(T.self, from: data) {
            return value
        }

        return nil
    }

    private func save<T: Encodable>(_ value: T, filename: String) {
        let primary = fileURL(filename)
        let backup = backupURL(filename)
        let fm = FileManager.default

        // Rotate current to backup
        if fm.fileExists(atPath: primary.path) {
            try? fm.removeItem(at: backup)
            try? fm.copyItem(at: primary, to: backup)
        }

        if let data = try? encoder.encode(value) {
            try? data.write(to: primary, options: .atomic)
        }
    }

    private func saveExercises() { save(exercises, filename: "exercises.json") }
    private func saveTemplates() { save(templates, filename: "templates.json") }
    private func saveSessions() { save(sessions, filename: "sessions.json") }
    private func saveMuscleGroups() { save(muscleGroups, filename: "muscleGroups.json") }

    // MARK: - MuscleGroup CRUD

    func addMuscleGroup(_ group: MuscleGroup) {
        muscleGroups.append(group)
        saveMuscleGroups()
    }

    func updateMuscleGroup(_ group: MuscleGroup) {
        if let i = muscleGroups.firstIndex(where: { $0.id == group.id }) {
            muscleGroups[i] = group
            saveMuscleGroups()
        }
    }

    func deleteMuscleGroup(_ group: MuscleGroup) {
        muscleGroups.removeAll { $0.id == group.id }
        saveMuscleGroups()
    }

    func muscleGroup(for id: UUID) -> MuscleGroup? {
        muscleGroups.first { $0.id == id }
    }

    func muscleGroupNames(for exercise: Exercise) -> [String] {
        exercise.muscleGroupIDs.compactMap { muscleGroup(for: $0)?.name }
    }

    func muscleGroupNamesJoined(for exercise: Exercise) -> String {
        let names = muscleGroupNames(for: exercise)
        return names.isEmpty ? "No muscle group" : names.joined(separator: ", ")
    }

    func primaryMuscleGroupName(for exercise: Exercise) -> String {
        exercise.muscleGroupIDs.first.flatMap { muscleGroup(for: $0)?.name } ?? "Other"
    }

    func findOrCreateMuscleGroup(named name: String) -> MuscleGroup {
        if let existing = muscleGroups.first(where: { $0.name.lowercased() == name.lowercased() }) {
            return existing
        }
        let newGroup = MuscleGroup(name: name)
        addMuscleGroup(newGroup)
        return newGroup
    }

    // MARK: - Exercise CRUD

    func addExercise(_ exercise: Exercise) {
        exercises.append(exercise)
        saveExercises()
    }

    func updateExercise(_ exercise: Exercise) {
        if let i = exercises.firstIndex(where: { $0.id == exercise.id }) {
            exercises[i] = exercise
            saveExercises()
        }
    }

    func deleteExercise(_ exercise: Exercise) {
        exercises.removeAll { $0.id == exercise.id }
        saveExercises()
    }

    func exercise(for id: UUID) -> Exercise? {
        exercises.first { $0.id == id }
    }

    // MARK: - Template CRUD

    func addTemplate(_ template: WorkoutTemplate) {
        templates.append(template)
        saveTemplates()
    }

    func updateTemplate(_ template: WorkoutTemplate) {
        if let i = templates.firstIndex(where: { $0.id == template.id }) {
            templates[i] = template
            saveTemplates()
        }
    }

    func deleteTemplate(_ template: WorkoutTemplate) {
        templates.removeAll { $0.id == template.id }
        saveTemplates()
    }

    // MARK: - Session CRUD

    var activeSession: WorkoutSession? {
        sessions.first { $0.isActive }
    }

    func startSession(from template: WorkoutTemplate) -> WorkoutSession {
        let session = WorkoutSession(
            templateID: template.id,
            templateName: template.name
        )
        sessions.append(session)
        saveSessions()
        return session
    }

    func startFreeSession(name: String) -> WorkoutSession {
        let session = WorkoutSession(templateName: name)
        sessions.append(session)
        saveSessions()
        return session
    }

    func updateSession(_ session: WorkoutSession) {
        if let i = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[i] = session
            saveSessions()
        }
    }

    func finishSession(_ session: WorkoutSession) {
        if let i = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[i].endDate = Date()
            saveSessions()
        }
    }

    func deleteSession(_ session: WorkoutSession) {
        sessions.removeAll { $0.id == session.id }
        saveSessions()
    }

    func addSet(to sessionID: UUID, set: LoggedSet) {
        if let i = sessions.firstIndex(where: { $0.id == sessionID }) {
            sessions[i].sets.append(set)
            saveSessions()
        }
    }

    func updateSet(in sessionID: UUID, set: LoggedSet) {
        if let i = sessions.firstIndex(where: { $0.id == sessionID }),
           let j = sessions[i].sets.firstIndex(where: { $0.id == set.id }) {
            sessions[i].sets[j] = set
            saveSessions()
        }
    }

    func deleteSet(in sessionID: UUID, setID: UUID) {
        if let i = sessions.firstIndex(where: { $0.id == sessionID }) {
            sessions[i].sets.removeAll { $0.id == setID }
            saveSessions()
        }
    }

    // MARK: - Queries

    func completedSessions() -> [WorkoutSession] {
        sessions.filter { !$0.isActive }.sorted { $0.startDate > $1.startDate }
    }

    func sessions(for exerciseID: UUID) -> [(session: WorkoutSession, sets: [LoggedSet])] {
        completedSessions().compactMap { session in
            let matchingSets = session.sets.filter { $0.exerciseID == exerciseID }
            guard !matchingSets.isEmpty else { return nil }
            return (session, matchingSets)
        }
    }

    func validExerciseIDs(in template: WorkoutTemplate) -> [UUID] {
        template.exerciseIDs.filter { id in exercises.contains { $0.id == id } }
    }

    func removedExerciseCount(in template: WorkoutTemplate) -> Int {
        template.exerciseIDs.count - validExerciseIDs(in: template).count
    }

    // MARK: - Import Support

    func addSessionFromImport(_ session: WorkoutSession) {
        sessions.append(session)
        saveSessions()
    }

    func addExerciseFromImport(_ exercise: Exercise) {
        exercises.append(exercise)
        saveExercises()
    }

    // MARK: - Danger Zone

    func deleteAllData() {
        exercises = []
        templates = []
        sessions = []
        muscleGroups = MuscleGroup.defaultGroups
        saveExercises()
        saveTemplates()
        saveSessions()
        saveMuscleGroups()
    }
}
