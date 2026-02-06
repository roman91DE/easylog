import Foundation

struct MuscleGroup: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }

    static let defaultGroups: [MuscleGroup] = [
        MuscleGroup(name: "Chest"),
        MuscleGroup(name: "Back"),
        MuscleGroup(name: "Shoulders"),
        MuscleGroup(name: "Biceps"),
        MuscleGroup(name: "Triceps"),
        MuscleGroup(name: "Legs"),
        MuscleGroup(name: "Glutes"),
        MuscleGroup(name: "Core"),
        MuscleGroup(name: "Full Body"),
        MuscleGroup(name: "Cardio"),
    ]
}
