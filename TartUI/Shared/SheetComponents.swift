import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct SheetHeader: View {
    let title: LocalizedStringKey
    let systemName: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.tint)
                .frame(width: 36, height: 36)
                .background(.quaternary, in: Circle())
            Text(title)
                .font(.title2.weight(.semibold))
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 8)
    }
}

struct SheetButtons: View {
    @Environment(\.dismiss) private var dismiss
    let primaryTitle: LocalizedStringKey
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        HStack {
            Spacer()
            Button("Cancel", role: .cancel) { dismiss() }
                .keyboardShortcut(.cancelAction)
            Button(primaryTitle, action: action)
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(isDisabled)
        }
        .padding(16)
    }
}

@MainActor
func chooseFile(extensions: [String]) -> URL? {
    let panel = NSOpenPanel()
    panel.canChooseDirectories = false
    panel.canChooseFiles = true
    panel.allowsMultipleSelection = false
    panel.allowedContentTypes = extensions.compactMap { UTType(filenameExtension: $0) }
    return panel.runModal() == .OK ? panel.url : nil
}

@MainActor
func chooseDirectory() -> URL? {
    let panel = NSOpenPanel()
    panel.canChooseDirectories = true
    panel.canChooseFiles = false
    panel.allowsMultipleSelection = false
    panel.canCreateDirectories = true
    return panel.runModal() == .OK ? panel.url : nil
}

@MainActor
func chooseAnyFile() -> URL? {
    let panel = NSOpenPanel()
    panel.canChooseDirectories = false
    panel.canChooseFiles = true
    panel.allowsMultipleSelection = false
    return panel.runModal() == .OK ? panel.url : nil
}
