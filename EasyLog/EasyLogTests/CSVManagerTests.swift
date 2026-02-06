import XCTest
@testable import EasyLog

final class CSVManagerTests: XCTestCase {

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

    // MARK: - Export

    func testExportEmptyStore() {
        let csv = CSVManager.exportCSV(from: store)
        let lines = csv.components(separatedBy: "\n")
        XCTAssertEqual(lines.count, 1) // header only
        XCTAssertTrue(lines[0].hasPrefix("session_id,"))
    }

    func testExportWithData() {
        let exercise = Exercise(name: "Bench Press", muscleGroup: "Chest", category: .barbell)
        store.addExercise(exercise)

        let template = WorkoutTemplate(name: "Push Day", exerciseIDs: [exercise.id])
        store.addTemplate(template)

        let session = store.startSession(from: template)
        store.addSet(to: session.id, set: LoggedSet(exerciseID: exercise.id, setNumber: 1, weight: 100, reps: 10, isCompleted: true))
        store.addSet(to: session.id, set: LoggedSet(exerciseID: exercise.id, setNumber: 2, weight: 100, reps: 8, isCompleted: true))
        store.finishSession(store.sessions.first!)

        let csv = CSVManager.exportCSV(from: store)
        let lines = csv.components(separatedBy: "\n")
        XCTAssertEqual(lines.count, 3) // header + 2 sets

        // Verify header
        XCTAssertEqual(lines[0], CSVManager.header)

        // Verify data
        XCTAssertTrue(lines[1].contains("Bench Press"))
        XCTAssertTrue(lines[1].contains("Chest"))
        XCTAssertTrue(lines[1].contains("Barbell"))
        XCTAssertTrue(lines[1].contains("100.0"))
    }

    func testExportToFile() {
        let exercise = Exercise(name: "Squat", muscleGroup: "Legs", category: .barbell)
        store.addExercise(exercise)

        let template = WorkoutTemplate(name: "Legs")
        let session = store.startSession(from: template)
        store.addSet(to: session.id, set: LoggedSet(exerciseID: exercise.id, setNumber: 1, weight: 140, reps: 5, isCompleted: true))
        store.finishSession(store.sessions.first!)

        let url = CSVManager.exportToFile(from: store)
        XCTAssertNotNil(url)

        if let url = url {
            let content = try? String(contentsOf: url, encoding: .utf8)
            XCTAssertNotNil(content)
            XCTAssertTrue(content?.contains("Squat") ?? false)
            try? FileManager.default.removeItem(at: url)
        }
    }

    // MARK: - CSV Parsing

    func testParseCSVLine() {
        let simple = CSVManager.parseCSVLine("a,b,c")
        XCTAssertEqual(simple, ["a", "b", "c"])

        let quoted = CSVManager.parseCSVLine("\"hello, world\",b,c")
        XCTAssertEqual(quoted.count, 3)
        XCTAssertEqual(quoted[0], "\"hello, world\"")
    }

    // MARK: - Round Trip

    func testExportImportRoundTrip() throws {
        // Create data
        let exercise1 = Exercise(name: "Bench Press", muscleGroup: "Chest", category: .barbell)
        let exercise2 = Exercise(name: "Squat", muscleGroup: "Legs", category: .barbell)
        store.addExercise(exercise1)
        store.addExercise(exercise2)

        let template = WorkoutTemplate(name: "Full Body", exerciseIDs: [exercise1.id, exercise2.id])
        store.addTemplate(template)

        let session = store.startSession(from: template)
        store.addSet(to: session.id, set: LoggedSet(exerciseID: exercise1.id, setNumber: 1, weight: 80, reps: 10, isCompleted: true))
        store.addSet(to: session.id, set: LoggedSet(exerciseID: exercise2.id, setNumber: 1, weight: 100, reps: 8, isCompleted: true))
        store.finishSession(store.sessions.first!)

        // Export
        let csv = CSVManager.exportCSV(from: store)

        // Create a new store for import
        let importDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: importDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: importDir) }

        let importStore = DataStore(directory: importDir)

        // Write CSV to temp file
        let csvURL = importDir.appendingPathComponent("test_import.csv")
        try csv.write(to: csvURL, atomically: true, encoding: .utf8)

        // Import
        let result = CSVManager.importCSV(from: csvURL, into: importStore)

        XCTAssertEqual(result.sessionsImported, 1)
        XCTAssertEqual(result.setsImported, 2)
        XCTAssertEqual(result.exercisesCreated, 2) // exercises are new in import store
        XCTAssertEqual(result.rowsSkipped, 0)
        XCTAssertTrue(result.errors.isEmpty)

        // Verify imported data
        XCTAssertEqual(importStore.sessions.count, 1)
        XCTAssertEqual(importStore.sessions.first?.sets.count, 2)
        XCTAssertEqual(importStore.exercises.count, 2)
    }

    func testImportSkipsDuplicates() throws {
        let exercise = Exercise(name: "Curl", muscleGroup: "Biceps", category: .dumbbell)
        store.addExercise(exercise)

        let session = store.startSession(from: WorkoutTemplate(name: "Arms"))
        store.addSet(to: session.id, set: LoggedSet(exerciseID: exercise.id, setNumber: 1, weight: 15, reps: 12, isCompleted: true))
        store.finishSession(store.sessions.first!)

        let csv = CSVManager.exportCSV(from: store)

        // Write and re-import into same store
        let csvURL = testDir.appendingPathComponent("test_dup.csv")
        try csv.write(to: csvURL, atomically: true, encoding: .utf8)

        let result = CSVManager.importCSV(from: csvURL, into: store)

        // Should skip because session ID already exists
        XCTAssertEqual(result.sessionsImported, 0)
        XCTAssertEqual(result.rowsSkipped, 1)
        XCTAssertEqual(store.sessions.count, 1) // still just one session
    }

    func testImportInvalidHeaders() throws {
        let csv = "bad,header,format\n1,2,3"
        let csvURL = testDir.appendingPathComponent("bad.csv")
        try csv.write(to: csvURL, atomically: true, encoding: .utf8)

        let result = CSVManager.importCSV(from: csvURL, into: store)
        XCTAssertFalse(result.errors.isEmpty)
        XCTAssertTrue(result.errors.first?.contains("Invalid header") ?? false)
    }
}
