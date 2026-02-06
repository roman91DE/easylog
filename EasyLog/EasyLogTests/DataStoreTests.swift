import XCTest
@testable import EasyLog

final class DataStoreTests: XCTestCase {

    var testDir: URL!
    var store: DataStore!

    override func setUp() {
        super.setUp()
        testDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true)
        store = DataStore(directory: testDir)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: testDir)
        super.tearDown()
    }

    // MARK: - MuscleGroup CRUD

    func testDefaultMuscleGroupsSeeded() {
        XCTAssertEqual(store.muscleGroups.count, 10)
        XCTAssertEqual(store.muscleGroups.first?.name, "Chest")
    }

    func testAddMuscleGroup() {
        let group = MuscleGroup(name: "Forearms")
        store.addMuscleGroup(group)
        XCTAssertEqual(store.muscleGroups.count, 11)
    }

    func testUpdateMuscleGroup() {
        var group = store.muscleGroups.first!
        group.name = "Upper Chest"
        store.updateMuscleGroup(group)
        XCTAssertEqual(store.muscleGroups.first?.name, "Upper Chest")
    }

    func testDeleteMuscleGroup() {
        let group = store.muscleGroups.first!
        store.deleteMuscleGroup(group)
        XCTAssertEqual(store.muscleGroups.count, 9)
    }

    func testMuscleGroupLookup() {
        let group = store.muscleGroups.first!
        XCTAssertNotNil(store.muscleGroup(for: group.id))
        XCTAssertNil(store.muscleGroup(for: UUID()))
    }

    func testFindOrCreateMuscleGroup() {
        // Existing group (case-insensitive)
        let existing = store.findOrCreateMuscleGroup(named: "chest")
        XCTAssertEqual(existing.name, "Chest")
        XCTAssertEqual(store.muscleGroups.count, 10)

        // New group
        let newGroup = store.findOrCreateMuscleGroup(named: "Forearms")
        XCTAssertEqual(newGroup.name, "Forearms")
        XCTAssertEqual(store.muscleGroups.count, 11)
    }

    func testMuscleGroupNamesForExercise() {
        let chestID = store.muscleGroups.first { $0.name == "Chest" }!.id
        let shouldersID = store.muscleGroups.first { $0.name == "Shoulders" }!.id

        let exercise = Exercise(name: "Bench Press", muscleGroupIDs: [chestID, shouldersID], category: .barbell)
        store.addExercise(exercise)

        let names = store.muscleGroupNames(for: exercise)
        XCTAssertEqual(names, ["Chest", "Shoulders"])

        let joined = store.muscleGroupNamesJoined(for: exercise)
        XCTAssertEqual(joined, "Chest, Shoulders")

        let primary = store.primaryMuscleGroupName(for: exercise)
        XCTAssertEqual(primary, "Chest")
    }

    func testMuscleGroupNamesForExerciseEmpty() {
        let exercise = Exercise(name: "Test", category: .other)
        XCTAssertEqual(store.muscleGroupNamesJoined(for: exercise), "No muscle group")
        XCTAssertEqual(store.primaryMuscleGroupName(for: exercise), "Other")
    }

    // MARK: - Exercise CRUD

    func testAddExercise() {
        let legsID = store.muscleGroups.first { $0.name == "Legs" }!.id
        let exercise = Exercise(name: "Squat", muscleGroupIDs: [legsID], category: .barbell)
        store.addExercise(exercise)

        XCTAssertEqual(store.exercises.count, 1)
        XCTAssertEqual(store.exercises.first?.name, "Squat")
    }

    func testUpdateExercise() {
        let legsID = store.muscleGroups.first { $0.name == "Legs" }!.id
        var exercise = Exercise(name: "Squat", muscleGroupIDs: [legsID], category: .barbell)
        store.addExercise(exercise)

        exercise.name = "Back Squat"
        store.updateExercise(exercise)

        XCTAssertEqual(store.exercises.first?.name, "Back Squat")
    }

    func testDeleteExercise() {
        let exercise = Exercise(name: "Squat", muscleGroupIDs: [], category: .barbell)
        store.addExercise(exercise)
        store.deleteExercise(exercise)

        XCTAssertTrue(store.exercises.isEmpty)
    }

    func testExerciseLookup() {
        let exercise = Exercise(name: "Squat", muscleGroupIDs: [], category: .barbell)
        store.addExercise(exercise)

        XCTAssertNotNil(store.exercise(for: exercise.id))
        XCTAssertNil(store.exercise(for: UUID()))
    }

    // MARK: - Template CRUD

    func testAddTemplate() {
        let template = WorkoutTemplate(name: "Push Day", exerciseIDs: [UUID()])
        store.addTemplate(template)

        XCTAssertEqual(store.templates.count, 1)
        XCTAssertEqual(store.templates.first?.name, "Push Day")
    }

    func testUpdateTemplate() {
        var template = WorkoutTemplate(name: "Push Day")
        store.addTemplate(template)

        template.name = "Pull Day"
        store.updateTemplate(template)

        XCTAssertEqual(store.templates.first?.name, "Pull Day")
    }

    func testDeleteTemplate() {
        let template = WorkoutTemplate(name: "Push Day")
        store.addTemplate(template)
        store.deleteTemplate(template)

        XCTAssertTrue(store.templates.isEmpty)
    }

    // MARK: - Session CRUD

    func testStartSessionFromTemplate() {
        let template = WorkoutTemplate(name: "Leg Day")
        let session = store.startSession(from: template)

        XCTAssertEqual(store.sessions.count, 1)
        XCTAssertEqual(session.templateName, "Leg Day")
        XCTAssertTrue(session.isActive)
    }

    func testStartFreeSession() {
        let session = store.startFreeSession(name: "Quick Pump")
        XCTAssertEqual(session.templateName, "Quick Pump")
        XCTAssertNil(session.templateID)
        XCTAssertTrue(session.isActive)
    }

    func testActiveSession() {
        XCTAssertNil(store.activeSession)

        let template = WorkoutTemplate(name: "Test")
        let _ = store.startSession(from: template)

        XCTAssertNotNil(store.activeSession)
    }

    func testFinishSession() {
        let template = WorkoutTemplate(name: "Test")
        let session = store.startSession(from: template)
        store.finishSession(session)

        XCTAssertNil(store.activeSession)
        XCTAssertNotNil(store.sessions.first?.endDate)
    }

    func testDeleteSession() {
        let template = WorkoutTemplate(name: "Test")
        let session = store.startSession(from: template)
        store.deleteSession(session)

        XCTAssertTrue(store.sessions.isEmpty)
    }

    // MARK: - Set CRUD

    func testAddSet() {
        let template = WorkoutTemplate(name: "Test")
        let session = store.startSession(from: template)
        let set = LoggedSet(exerciseID: UUID(), setNumber: 1, weight: 100, reps: 10)

        store.addSet(to: session.id, set: set)

        XCTAssertEqual(store.sessions.first?.sets.count, 1)
    }

    func testUpdateSet() {
        let template = WorkoutTemplate(name: "Test")
        let session = store.startSession(from: template)
        var set = LoggedSet(exerciseID: UUID(), setNumber: 1, weight: 100, reps: 10)
        store.addSet(to: session.id, set: set)

        set.weight = 110
        set.isCompleted = true
        store.updateSet(in: session.id, set: set)

        let updatedSet = store.sessions.first?.sets.first
        XCTAssertEqual(updatedSet?.weight, 110)
        XCTAssertTrue(updatedSet?.isCompleted ?? false)
    }

    func testDeleteSet() {
        let template = WorkoutTemplate(name: "Test")
        let session = store.startSession(from: template)
        let set = LoggedSet(exerciseID: UUID(), setNumber: 1)
        store.addSet(to: session.id, set: set)
        store.deleteSet(in: session.id, setID: set.id)

        XCTAssertTrue(store.sessions.first?.sets.isEmpty ?? false)
    }

    // MARK: - Persistence

    func testPersistenceRoundTrip() {
        let backID = store.muscleGroups.first { $0.name == "Back" }!.id
        let exercise = Exercise(name: "Deadlift", muscleGroupIDs: [backID], category: .barbell)
        store.addExercise(exercise)

        let template = WorkoutTemplate(name: "Pull Day", exerciseIDs: [exercise.id])
        store.addTemplate(template)

        let session = store.startSession(from: template)
        store.addSet(to: session.id, set: LoggedSet(exerciseID: exercise.id, setNumber: 1, weight: 140, reps: 5, isCompleted: true))
        store.finishSession(store.sessions.first!)

        // Load fresh store from same directory
        let store2 = DataStore(directory: testDir)

        XCTAssertEqual(store2.exercises.count, 1)
        XCTAssertEqual(store2.exercises.first?.name, "Deadlift")
        XCTAssertEqual(store2.templates.count, 1)
        XCTAssertEqual(store2.sessions.count, 1)
        XCTAssertEqual(store2.sessions.first?.sets.count, 1)
        XCTAssertEqual(store2.sessions.first?.sets.first?.weight, 140)
        XCTAssertEqual(store2.muscleGroups.count, 10)
    }

    func testBackupRecovery() {
        let bicepsID = store.muscleGroups.first { $0.name == "Biceps" }!.id
        let exercise = Exercise(name: "Curl", muscleGroupIDs: [bicepsID], category: .dumbbell)
        store.addExercise(exercise)

        // Corrupt the primary file
        let primaryURL = testDir.appendingPathComponent("exercises.json")
        try? "corrupt data".write(to: primaryURL, atomically: true, encoding: .utf8)

        // Load should fall back to backup
        let store2 = DataStore(directory: testDir)
        XCTAssertEqual(store2.exercises.count, 1)
        XCTAssertEqual(store2.exercises.first?.name, "Curl")
    }

    func testMuscleGroupPersistence() {
        let newGroup = MuscleGroup(name: "Forearms")
        store.addMuscleGroup(newGroup)

        let store2 = DataStore(directory: testDir)
        XCTAssertEqual(store2.muscleGroups.count, 11)
        XCTAssertTrue(store2.muscleGroups.contains { $0.name == "Forearms" })
    }

    // MARK: - Queries

    func testCompletedSessions() {
        let t = WorkoutTemplate(name: "Test")
        let s1 = store.startSession(from: t)
        store.finishSession(s1)
        let _ = store.startFreeSession(name: "Active")

        let completed = store.completedSessions()
        XCTAssertEqual(completed.count, 1)
    }

    func testSessionsForExercise() {
        let exerciseID = UUID()
        let t = WorkoutTemplate(name: "Test")
        let session = store.startSession(from: t)
        store.addSet(to: session.id, set: LoggedSet(exerciseID: exerciseID, setNumber: 1, weight: 50, reps: 10, isCompleted: true))
        store.finishSession(store.sessions.first!)

        let results = store.sessions(for: exerciseID)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.sets.count, 1)
    }

    func testRemovedExerciseCount() {
        let exercise = Exercise(name: "Test", muscleGroupIDs: [], category: .other)
        store.addExercise(exercise)

        let template = WorkoutTemplate(name: "T", exerciseIDs: [exercise.id, UUID()])
        store.addTemplate(template)

        XCTAssertEqual(store.removedExerciseCount(in: template), 1)
        XCTAssertEqual(store.validExerciseIDs(in: template).count, 1)
    }

    // MARK: - Delete All

    func testDeleteAllData() {
        store.addExercise(Exercise(name: "A", muscleGroupIDs: [], category: .other))
        store.addTemplate(WorkoutTemplate(name: "T"))
        let _ = store.startFreeSession(name: "S")

        store.deleteAllData()

        XCTAssertTrue(store.exercises.isEmpty)
        XCTAssertTrue(store.templates.isEmpty)
        XCTAssertTrue(store.sessions.isEmpty)
        // Muscle groups reset to defaults
        XCTAssertEqual(store.muscleGroups.count, 10)
    }
}
