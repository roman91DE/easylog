import Foundation

struct LoggedSet: Codable, Identifiable {
    let id: UUID
    var exerciseID: UUID
    var setNumber: Int
    var weight: Double
    var reps: Int
    var isCompleted: Bool

    init(id: UUID = UUID(), exerciseID: UUID, setNumber: Int, weight: Double = 0, reps: Int = 0, isCompleted: Bool = false) {
        self.id = id
        self.exerciseID = exerciseID
        self.setNumber = setNumber
        self.weight = weight
        self.reps = reps
        self.isCompleted = isCompleted
    }
}

struct WorkoutSession: Codable, Identifiable {
    let id: UUID
    var templateID: UUID?
    var templateName: String
    var startDate: Date
    var endDate: Date?
    var sets: [LoggedSet]

    var isActive: Bool {
        endDate == nil
    }

    init(id: UUID = UUID(), templateID: UUID? = nil, templateName: String, startDate: Date = Date(), endDate: Date? = nil, sets: [LoggedSet] = []) {
        self.id = id
        self.templateID = templateID
        self.templateName = templateName
        self.startDate = startDate
        self.endDate = endDate
        self.sets = sets
    }
}
