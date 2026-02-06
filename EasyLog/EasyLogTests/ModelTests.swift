import XCTest
@testable import EasyLog

final class ModelTests: XCTestCase {

    // MARK: - Exercise

    func testExerciseEncodeDecode() throws {
        let exercise = Exercise(name: "Bench Press", muscleGroup: "Chest", category: .barbell)
        let data = try JSONEncoder().encode(exercise)
        let decoded = try JSONDecoder().decode(Exercise.self, from: data)

        XCTAssertEqual(decoded.id, exercise.id)
        XCTAssertEqual(decoded.name, "Bench Press")
        XCTAssertEqual(decoded.muscleGroup, "Chest")
        XCTAssertEqual(decoded.category, .barbell)
    }

    func testExerciseDefaultID() {
        let e1 = Exercise(name: "A", muscleGroup: "B", category: .machine)
        let e2 = Exercise(name: "A", muscleGroup: "B", category: .machine)
        XCTAssertNotEqual(e1.id, e2.id)
    }

    // MARK: - WorkoutTemplate

    func testTemplateEncodeDecode() throws {
        let ids = [UUID(), UUID()]
        let template = WorkoutTemplate(name: "Push Day", exerciseIDs: ids)
        let data = try JSONEncoder().encode(template)
        let decoded = try JSONDecoder().decode(WorkoutTemplate.self, from: data)

        XCTAssertEqual(decoded.name, "Push Day")
        XCTAssertEqual(decoded.exerciseIDs, ids)
    }

    func testTemplateDefaultEmptyExercises() {
        let template = WorkoutTemplate(name: "Empty")
        XCTAssertTrue(template.exerciseIDs.isEmpty)
    }

    // MARK: - LoggedSet

    func testLoggedSetEncodeDecode() throws {
        let exerciseID = UUID()
        let set = LoggedSet(exerciseID: exerciseID, setNumber: 1, weight: 100.5, reps: 8, isCompleted: true)
        let data = try JSONEncoder().encode(set)
        let decoded = try JSONDecoder().decode(LoggedSet.self, from: data)

        XCTAssertEqual(decoded.exerciseID, exerciseID)
        XCTAssertEqual(decoded.setNumber, 1)
        XCTAssertEqual(decoded.weight, 100.5)
        XCTAssertEqual(decoded.reps, 8)
        XCTAssertTrue(decoded.isCompleted)
    }

    func testLoggedSetDefaults() {
        let set = LoggedSet(exerciseID: UUID(), setNumber: 1)
        XCTAssertEqual(set.weight, 0)
        XCTAssertEqual(set.reps, 0)
        XCTAssertFalse(set.isCompleted)
    }

    // MARK: - WorkoutSession

    func testSessionIsActive() {
        let active = WorkoutSession(templateName: "Test")
        XCTAssertTrue(active.isActive)

        let finished = WorkoutSession(templateName: "Test", endDate: Date())
        XCTAssertFalse(finished.isActive)
    }

    func testSessionEncodeDecode() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let session = WorkoutSession(
            templateID: UUID(),
            templateName: "Push Day",
            startDate: Date(),
            endDate: Date(),
            sets: [LoggedSet(exerciseID: UUID(), setNumber: 1, weight: 80, reps: 10, isCompleted: true)]
        )

        let data = try encoder.encode(session)
        let decoded = try decoder.decode(WorkoutSession.self, from: data)

        XCTAssertEqual(decoded.id, session.id)
        XCTAssertEqual(decoded.templateName, "Push Day")
        XCTAssertEqual(decoded.sets.count, 1)
        XCTAssertFalse(decoded.isActive)
    }

    // MARK: - ImportResult

    func testImportResultSummary() {
        var result = ImportResult()
        XCTAssertEqual(result.summary, "Nothing to import")

        result.sessionsImported = 2
        result.setsImported = 10
        result.exercisesCreated = 1
        XCTAssertTrue(result.summary.contains("2 session(s) imported"))
        XCTAssertTrue(result.summary.contains("10 set(s) imported"))
        XCTAssertTrue(result.summary.contains("1 exercise(s) created"))
    }
}
