import Foundation

enum CSVManager {
    static let header = "session_id,session_date,session_end_date,template_name,exercise_name,muscle_group,category,set_number,weight,reps,completed"

    // MARK: - Export

    static func exportCSV(from dataStore: DataStore) -> String {
        var lines = [header]

        for session in dataStore.completedSessions() {
            let sessionID = session.id.uuidString
            let startDate = DateFormatters.csv.string(from: session.startDate)
            let endDate = session.endDate.map { DateFormatters.csv.string(from: $0) } ?? ""

            for set in session.sets {
                let exercise = dataStore.exercise(for: set.exerciseID)
                let exerciseName = csvEscape(exercise?.name ?? "Unknown Exercise")
                let muscleGroupNames = exercise.map { dataStore.muscleGroupNames(for: $0).joined(separator: ";") } ?? "Unknown"
                let muscleGroup = csvEscape(muscleGroupNames)
                let category = exercise?.category.rawValue ?? "Other"

                let line = [
                    sessionID,
                    startDate,
                    endDate,
                    csvEscape(session.templateName),
                    exerciseName,
                    muscleGroup,
                    category,
                    "\(set.setNumber)",
                    "\(set.weight)",
                    "\(set.reps)",
                    set.isCompleted ? "true" : "false"
                ].joined(separator: ",")

                lines.append(line)
            }
        }

        return lines.joined(separator: "\n")
    }

    static func exportToFile(from dataStore: DataStore) -> URL? {
        let csv = exportCSV(from: dataStore)
        let filename = "easylog_export_\(DateFormatters.csv.string(from: Date())).csv"
            .replacingOccurrences(of: ":", with: "-")
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        do {
            try csv.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            return nil
        }
    }

    // MARK: - Import

    static func importCSV(from url: URL, into dataStore: DataStore) -> ImportResult {
        var result = ImportResult()

        guard url.startAccessingSecurityScopedResource() else {
            result.errors.append("Cannot access file")
            return result
        }
        defer { url.stopAccessingSecurityScopedResource() }

        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            result.errors.append("Cannot read file")
            return result
        }

        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard lines.count > 1 else {
            result.errors.append("File is empty or has no data rows")
            return result
        }

        let headerLine = lines[0].trimmingCharacters(in: .whitespaces)
        let expectedFields = header.components(separatedBy: ",")
        let actualFields = headerLine.components(separatedBy: ",")
        guard actualFields.count == expectedFields.count else {
            result.errors.append("Invalid header: expected \(expectedFields.count) columns, got \(actualFields.count)")
            return result
        }

        let existingSessionIDs = Set(dataStore.sessions.map { $0.id })

        // Group rows by session
        var sessionRows: [UUID: [(Int, [String])]] = [:]

        for (lineIndex, line) in lines.dropFirst().enumerated() {
            let fields = parseCSVLine(line)
            guard fields.count == expectedFields.count else {
                result.rowsSkipped += 1
                continue
            }

            guard let sessionID = UUID(uuidString: fields[0]) else {
                result.rowsSkipped += 1
                result.errors.append("Row \(lineIndex + 2): invalid session ID")
                continue
            }

            if existingSessionIDs.contains(sessionID) {
                result.rowsSkipped += 1
                continue
            }

            sessionRows[sessionID, default: []].append((lineIndex + 2, fields))
        }

        // Process each session
        for (sessionID, rows) in sessionRows {
            guard let firstRow = rows.first else { continue }
            let fields = firstRow.1

            let startDate = DateFormatters.csv.date(from: fields[1]) ?? Date()
            let endDate = fields[2].isEmpty ? nil : DateFormatters.csv.date(from: fields[2])
            let templateName = csvUnescape(fields[3])

            var sets: [LoggedSet] = []

            for (rowNum, rowFields) in rows {
                let exerciseName = csvUnescape(rowFields[4])
                let muscleGroupField = csvUnescape(rowFields[5])
                let categoryStr = rowFields[6]
                let category = Exercise.Category(rawValue: categoryStr) ?? .other

                // Parse semicolon-separated muscle group names and resolve to IDs
                let muscleGroupIDs = muscleGroupField
                    .split(separator: ";")
                    .map { String($0).trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
                    .map { dataStore.findOrCreateMuscleGroup(named: $0).id }

                // Find or create exercise
                var exercise = dataStore.exercises.first {
                    $0.name.lowercased() == exerciseName.lowercased()
                }
                if exercise == nil {
                    let newExercise = Exercise(name: exerciseName, muscleGroupIDs: muscleGroupIDs, category: category)
                    dataStore.addExerciseFromImport(newExercise)
                    exercise = newExercise
                    result.exercisesCreated += 1
                }

                guard let setNumber = Int(rowFields[7]),
                      let weight = Double(rowFields[8]),
                      let reps = Int(rowFields[9]) else {
                    result.rowsSkipped += 1
                    result.errors.append("Row \(rowNum): invalid numeric values")
                    continue
                }

                let completed = rowFields[10].trimmingCharacters(in: .whitespaces).lowercased() == "true"

                let loggedSet = LoggedSet(
                    exerciseID: exercise!.id,
                    setNumber: setNumber,
                    weight: weight,
                    reps: reps,
                    isCompleted: completed
                )
                sets.append(loggedSet)
                result.setsImported += 1
            }

            let session = WorkoutSession(
                id: sessionID,
                templateName: templateName,
                startDate: startDate,
                endDate: endDate,
                sets: sets
            )
            dataStore.addSessionFromImport(session)
            result.sessionsImported += 1
        }

        return result
    }

    // MARK: - CSV Helpers

    private static func csvEscape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }

    private static func csvUnescape(_ value: String) -> String {
        var s = value.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("\"") && s.hasSuffix("\"") {
            s = String(s.dropFirst().dropLast())
            s = s.replacingOccurrences(of: "\"\"", with: "\"")
        }
        return s
    }

    static func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false

        for char in line {
            if char == "\"" {
                inQuotes.toggle()
                current.append(char)
            } else if char == "," && !inQuotes {
                fields.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }
        fields.append(current)
        return fields
    }
}
