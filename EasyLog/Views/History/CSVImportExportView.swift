import SwiftUI

struct CSVImportExportView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showingImporter = false
    @State private var importResult: ImportResult?
    @State private var showingImportResult = false
    @State private var exportURL: URL?

    var body: some View {
        List {
            Section {
                if let url = exportURL {
                    ShareLink("Share CSV Export", item: url)
                }

                Button {
                    exportURL = CSVManager.exportToFile(from: dataStore)
                } label: {
                    Label("Generate CSV Export", systemImage: "square.and.arrow.up")
                }
            } header: {
                Text("Export")
            } footer: {
                Text("Exports all completed workout sessions as a CSV file.")
            }

            Section {
                Button {
                    showingImporter = true
                } label: {
                    Label("Import from CSV", systemImage: "square.and.arrow.down")
                }
            } header: {
                Text("Import")
            } footer: {
                Text("Import workout data from a previously exported CSV file. Duplicate sessions will be skipped.")
            }

            if let result = importResult {
                Section("Last Import Result") {
                    Text(result.summary)
                        .font(.body.monospacedDigit())

                    if !result.errors.isEmpty {
                        DisclosureGroup("Errors (\(result.errors.count))") {
                            ForEach(result.errors, id: \.self) { error in
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Import / Export")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.commaSeparatedText, .plainText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    importResult = CSVManager.importCSV(from: url, into: dataStore)
                }
            case .failure(let error):
                importResult = ImportResult(errors: [error.localizedDescription])
            }
        }
    }
}
