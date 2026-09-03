import AppKit
import SwiftUI

struct ImageDetailView: View {
    let image: TartImage
    let onCreateVM: () -> Void
    let onDelete: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ResourceHeader(
                    systemName: "square.stack.3d.up.fill",
                    color: .blue,
                    title: image.title,
                    status: "OCI Image"
                ) {
                    HStack(spacing: 8) {
                        Button("Create Virtual Machine", action: onCreateVM)
                            .buttonStyle(.borderedProminent)
                        Menu {
                            Button("Delete Image", role: .destructive, action: onDelete)
                        } label: {
                            Image(systemName: "ellipsis")
                        }
                        .menuStyle(.borderlessButton)
                        .fixedSize()
                    }
                }

                MetadataStrip(items: [
                    .init(systemName: "shippingbox", value: "OCI"),
                    .init(systemName: "internaldrive", value: "\(image.diskGB) GB disk"),
                    .init(systemName: "externaldrive", value: "\(image.sizeGB) GB stored"),
                    .init(systemName: "tag", value: image.version),
                ])

                SectionPanel("Image", systemName: "square.stack.3d.up") {
                    InfoRow("Registry", value: image.registry)
                    InfoRow("Repository", value: image.repository)
                    InfoRow("Version", value: image.version)
                    InfoRow("Virtual disk", value: "\(image.diskGB) GB")
                    InfoRow("Stored size", value: "\(image.sizeGB) GB")
                }

                SectionPanel("Reference", systemName: "link") {
                    CodeWell(image.reference)
                }
            }
            .padding(.horizontal, 36)
            .padding(.vertical, 32)
            .frame(maxWidth: 880, alignment: .leading)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
