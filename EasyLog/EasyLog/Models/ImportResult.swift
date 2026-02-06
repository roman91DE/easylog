import Foundation

struct ImportResult {
    var sessionsImported: Int = 0
    var setsImported: Int = 0
    var exercisesCreated: Int = 0
    var rowsSkipped: Int = 0
    var errors: [String] = []

    var summary: String {
        var parts: [String] = []
        if sessionsImported > 0 { parts.append("\(sessionsImported) session(s) imported") }
        if setsImported > 0 { parts.append("\(setsImported) set(s) imported") }
        if exercisesCreated > 0 { parts.append("\(exercisesCreated) exercise(s) created") }
        if rowsSkipped > 0 { parts.append("\(rowsSkipped) row(s) skipped") }
        if !errors.isEmpty { parts.append("\(errors.count) error(s)") }
        return parts.isEmpty ? "Nothing to import" : parts.joined(separator: "\n")
    }
}
