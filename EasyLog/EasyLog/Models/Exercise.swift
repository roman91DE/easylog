import Foundation

struct Exercise: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var muscleGroup: String
    var category: Category

    enum Category: String, Codable, CaseIterable {
        case barbell = "Barbell"
        case dumbbell = "Dumbbell"
        case machine = "Machine"
        case bodyweight = "Bodyweight"
        case cable = "Cable"
        case other = "Other"
    }

    init(id: UUID = UUID(), name: String, muscleGroup: String, category: Category) {
        self.id = id
        self.name = name
        self.muscleGroup = muscleGroup
        self.category = category
    }
}
