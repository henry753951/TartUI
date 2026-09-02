import AppKit
import SwiftUI

struct SharedDirectoryRow: View {
    @Binding var directory: SharedDirectoryDraft
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "folder")
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
                TextField("Host folder", text: $directory.path)
                    .font(.system(.callout, design: .monospaced))
                Button("Choose…") {
                    if let url = chooseDirectory() {
                        directory.path = url.path
                        if directory.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            directory.name = url.lastPathComponent
                        }
                    }
                }
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .help("Remove shared folder")
            }

            HStack(spacing: 12) {
                TextField("Guest name (optional)", text: $directory.name)
                TextField("Mount tag (optional)", text: $directory.tag)
                Toggle("Read only", isOn: $directory.readOnly)
                    .toggleStyle(.checkbox)
                    .fixedSize()
            }
            .padding(.leading, 28)
        }
        .padding(12)
        .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct DiskAttachmentRow: View {
    @Binding var disk: DiskAttachmentDraft
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "externaldrive")
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
                TextField("Image path, VM, block device, OCI, or NBD URL", text: $disk.source)
                    .font(.system(.callout, design: .monospaced))
                Button("Choose…") {
                    if let url = chooseAnyFile() { disk.source = url.path }
                }
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .help("Remove disk attachment")
            }

            HStack(spacing: 16) {
                Toggle("Read only", isOn: $disk.readOnly)
                    .toggleStyle(.checkbox)
                Toggle("Disable synchronization", isOn: $disk.disableSynchronization)
                    .toggleStyle(.checkbox)
            }
            .padding(.leading, 28)
        }
        .padding(12)
        .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct AttachmentEmptyState: View {
    let systemName: String
    let text: LocalizedStringKey

    var body: some View {
        Label(text, systemImage: systemName)
            .font(.callout)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
    }
}
