import SwiftUI

struct HistoryListView: View {
    @EnvironmentObject var dataStore: DataStore

    private var completedSessions: [WorkoutSession] {
        dataStore.completedSessions()
    }

    var body: some View {
        NavigationStack {
            Group {
                if completedSessions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "clock")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No Workout History")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Completed workouts will appear here")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(completedSessions) { session in
                            NavigationLink(value: session.id) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(session.templateName)
                                        .font(.headline)
                                    HStack {
                                        Text(DateFormatters.display.string(from: session.startDate))
                                        if let endDate = session.endDate {
                                            Text("· \(DateFormatters.duration(from: session.startDate, to: endDate))")
                                        }
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                    let completedSets = session.sets.filter { $0.isCompleted }.count
                                    Text("\(completedSets)/\(session.sets.count) sets completed")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                        Text("\(session.totalSetsCount) sets · \(session.totalRepsCount) reps · \(session.totalVolume, specifier: "%.0f") kg")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                }
                            }
                        }
                        .onDelete(perform: deleteSessions)
                    }
                }
            }
            .navigationTitle("History")
            .navigationDestination(for: UUID.self) { sessionID in
                if let session = dataStore.sessions.first(where: { $0.id == sessionID }) {
                    SessionDetailView(session: session)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        CSVImportExportView()
                    } label: {
                        Image(systemName: "square.and.arrow.up.on.square")
                    }
                }
            }
        }
    }

    private func deleteSessions(at offsets: IndexSet) {
        let sessions = completedSessions
        for index in offsets {
            dataStore.deleteSession(sessions[index])
        }
    }
}

private extension WorkoutSession {
    var totalSetsCount: Int {
        sets.count
    }

    var totalRepsCount: Int {
        sets.reduce(0) { $0 + $1.reps }
    }

    var totalVolume: Double {
        sets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }
}
