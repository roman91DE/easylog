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

    // MARK: - Exercise CRUD

    func testAddExercise() {
        let exercise = Exercise(name: "Squat", muscleGroup: "Legs", category: .barbell)
        store.addExercise(exercise)

        XCTAssertEqual(store.exercises.count, 1)
        XCTAssertEqual(store.exercises.first?.name, "Squat")
    }

    func testUpdateExercise() {
        var exercise = Exercise(name: "Squat", muscleGroup: "Legs", category: .barbell)
        store.addExercise(exercise)

        exercise.name = "Back Squat"
        store.updateExercise(exercise)

        XCTAssertEqual(store.exercises.first?.name, "Back Squat")
    }

    func testDeleteExercise() {
        let exercise = Exercise(name: "Squat", muscleGroup: "Legs", category: .barbell)
        store.addExercise(exercise)
        store.deleteExercise(exercise)

        XCTAssertTrue(store.exercises.isEmpty)
    }

    func testExerciseLookup() {
        let exercise = Exercise(name: "Squat", muscleGroup: "Legs", category: .barbell)
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
        let exercise = Exercise(name: "Deadlift", muscleGroup: "Back", category: .barbell)
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
    }

    func testBackupRecovery() {
        let exercise = Exercise(name: "Curl", muscleGroup: "Biceps", category: .dumbbell)
        store.addExercise(exercise)

        // Corrupt the primary file
        let primaryURL = testDir.appendingPathComponent("exercises.json")
        try? "corrupt data".write(to: primaryURL, atomically: true, encoding: .utf8)

        // Load should fall back to backup
        let store2 = DataStore(directory: testDir)
        XCTAssertEqual(store2.exercises.count, 1)
        XCTAssertEqual(store2.exercises.first?.name, "Curl")
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
        let exercise = Exercise(name: "Test", muscleGroup: "Test", category: .other)
        store.addExercise(exercise)

        let template = WorkoutTemplate(name: "T", exerciseIDs: [exercise.id, UUID()])
        store.addTemplate(template)

        XCTAssertEqual(store.removedExerciseCount(in: template), 1)
        XCTAssertEqual(store.validExerciseIDs(in: template).count, 1)
    }

    // MARK: - Delete All

    func testDeleteAllData() {
        store.addExercise(Exercise(name: "A", muscleGroup: "B", category: .other))
        store.addTemplate(WorkoutTemplate(name: "T"))
        let _ = store.startFreeSession(name: "S")

        store.deleteAllData()

        XCTAssertTrue(store.exercises.isEmpty)
        XCTAssertTrue(store.templates.isEmpty)
        XCTAssertTrue(store.sessions.isEmpty)
    }
}
