import SwiftUI

struct SessionDetailView: View {
    @EnvironmentObject var dataStore: DataStore
    let session: WorkoutSession

    private var exerciseGroups: [(UUID, String, [LoggedSet])] {
        var seen = Set<UUID>()
        var ordered: [(UUID, String, [LoggedSet])] = []

        for set in session.sets {
            if seen.insert(set.exerciseID).inserted {
                let name = dataStore.exercise(for: set.exerciseID)?.name ?? "Unknown Exercise"
                let sets = session.sets.filter { $0.exerciseID == set.exerciseID }.sorted { $0.setNumber < $1.setNumber }
                ordered.append((set.exerciseID, name, sets))
            }
        }

        return ordered
    }

    var body: some View {
        List {
            Section("Summary") {
                LabeledContent("Workout", value: session.templateName)
                LabeledContent("Date", value: DateFormatters.display.string(from: session.startDate))
                if let endDate = session.endDate {
                    LabeledContent("Duration", value: DateFormatters.duration(from: session.startDate, to: endDate))
                }
                let completed = session.sets.filter { $0.isCompleted }.count
                LabeledContent("Sets Completed", value: "\(completed)/\(session.sets.count)")
            }

            ForEach(exerciseGroups, id: \.0) { _, name, sets in
                Section(name) {
                    ForEach(sets) { set in
                        HStack {
                            Text("Set \(set.setNumber)")
                                .frame(width: 55, alignment: .leading)
                            Text("\(set.weight, specifier: "%.1f") kg")
                                .frame(width: 80, alignment: .trailing)
                            Text("× \(set.reps)")
                                .frame(width: 45, alignment: .trailing)
                            Spacer()
                            if set.isCompleted {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                            } else {
                                Image(systemName: "xmark.circle")
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                        }
                        .font(.body.monospacedDigit())
                    }
                }
            }
        }
        .navigationTitle("Session Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
