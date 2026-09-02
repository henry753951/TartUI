import SwiftUI

struct LicenseBrowserView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selection = LicenseDocument.included.first?.id

    var body: some View {
        NavigationSplitView {
            List(LicenseDocument.included, selection: $selection) { document in
                VStack(alignment: .leading, spacing: 3) {
                    Text(document.name)
                        .fontWeight(.medium)
                    Text(document.licenseName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .tag(document.id)
            }
            .navigationTitle("Licenses")
            .navigationSplitViewColumnWidth(min: 190, ideal: 220, max: 260)
        } detail: {
            if let document = selectedDocument {
                LicenseDocumentView(document: document)
            } else {
                ContentUnavailableView("Select a License", systemImage: "doc.text")
            }
        }
        .frame(minWidth: 760, minHeight: 560)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }

    private var selectedDocument: LicenseDocument? {
        LicenseDocument.included.first { $0.id == selection }
    }
}

private struct LicenseDocumentView: View {
    let document: LicenseDocument
    @State private var text = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var reloadToken = UUID()
    private let service = LicenseService()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: "doc.text")
                    .font(.title2)
                    .foregroundStyle(.tint)
                    .frame(width: 42, height: 42)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 11))
                VStack(alignment: .leading, spacing: 3) {
                    Text(document.name)
                        .font(.title2.weight(.semibold))
                    Text("\(document.owner) · \(document.licenseName)")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Link("Project", destination: document.projectURL)
            }
            .padding(22)

            Divider()

            Group {
                if isLoading && text.isEmpty {
                    ProgressView("Loading license…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage, text.isEmpty {
                    ContentUnavailableView {
                        Label("License Unavailable", systemImage: "wifi.exclamationmark")
                    } description: {
                        Text(errorMessage)
                    } actions: {
                        Button("Try Again") { reloadToken = UUID() }
                    }
                } else {
                    ScrollView {
                        Text(text)
                            .font(.system(.callout, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(22)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle(document.name)
        .task(id: "\(document.id)-\(reloadToken)") {
            await load(reload: errorMessage != nil)
        }
    }

    private func load(reload: Bool) async {
        isLoading = true
        errorMessage = nil
        do {
            text = try await service.text(for: document, reload: reload)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
