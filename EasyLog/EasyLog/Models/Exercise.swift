import Foundation

struct Exercise: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var muscleGroupIDs: [UUID]
    var category: Category

    enum Category: String, Codable, CaseIterable {
        case barbell = "Barbell"
        case dumbbell = "Dumbbell"
        case machine = "Machine"
        case bodyweight = "Bodyweight"
        case cable = "Cable"
        case other = "Other"
    }

    init(id: UUID = UUID(), name: String, muscleGroupIDs: [UUID] = [], category: Category) {
        self.id = id
        self.name = name
        self.muscleGroupIDs = muscleGroupIDs
        self.category = category
    }
}
