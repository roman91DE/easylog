import Foundation

struct WorkoutTemplate: Codable, Identifiable {
    let id: UUID
    var name: String
    var exerciseIDs: [UUID]

    init(id: UUID = UUID(), name: String, exerciseIDs: [UUID] = []) {
        self.id = id
        self.name = name
        self.exerciseIDs = exerciseIDs
    }
}
