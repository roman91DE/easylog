# EasyLog AI coding guide

## Architecture overview
- SwiftUI app with a single shared state object: `DataStore` is created in EasyLogApp and injected via `environmentObject` into all views.
- Data is purely local: JSON files are stored in the app’s Documents directory with a simple backup rotation (.bak) on each save.
- Core domain models live in EasyLog/Models (Exercise, WorkoutTemplate, WorkoutSession, LoggedSet, MuscleGroup, ImportResult).
- Features are split by tab in EasyLog/ContentView.swift:
  - Exercises: list/detail/edit + muscle-group assignment.
  - Workouts: templates + active workout logging.
  - History: completed sessions + CSV import/export.

## Key data flows & patterns
- All mutations go through `DataStore` CRUD methods (add/update/delete). Those methods also persist immediately (JSON encode with ISO-8601 dates).
- Active workout state is just a `WorkoutSession` with `endDate == nil`; `DataStore.activeSession` derives it.
- Workout logging stores `LoggedSet` rows inside a session; views read/update sets by ID and re-save the session.
- Muscle groups are normalized IDs; `DataStore.muscleGroupNames*` helpers translate IDs to display names.
- CSV import/export is centralized in `Services/CSVManager.swift` and uses semicolon-separated muscle-group names.

## Project-specific conventions
- Date formatting is centralized in `Helpers/DateFormatters.swift` (display, date-only, CSV ISO-8601).
- Template editing keeps `exerciseIDs` ordered; UI uses `.environment(\.editMode, .constant(.active))` to enable reordering in place.
- Exercise forms preserve muscle-group order based on `DataStore.muscleGroups`.

## Integration points
- `CSVImportExportView` uses `CSVManager.exportToFile` and `fileImporter` for import; import resolves/creates exercises and muscle groups.
- `CSVManager.importCSV` skips duplicate sessions by session ID and reports results via `ImportResult.summary`.

## Tests & validation
- Unit tests are in EasyLogTests and instantiate `DataStore(directory:)` with a temp folder to avoid touching real user data.
- CSV round-trip behavior is covered in `CSVManagerTests` and relies on ISO-8601 date encoding.
