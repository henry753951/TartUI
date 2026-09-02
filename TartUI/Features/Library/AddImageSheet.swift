import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct AddImageSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var options: ImagePullOptions
    let onAdd: (ImagePullOptions) -> Void

    init(defaultReference: String, onAdd: @escaping (ImagePullOptions) -> Void) {
        var options = ImagePullOptions()
        options.reference = defaultReference
        _options = State(initialValue: options)
        self.onAdd = onAdd
    }

    private let presets = [
        "ghcr.io/cirruslabs/macos-tahoe-base:latest",
        "ghcr.io/cirruslabs/macos-sequoia-base:latest",
        "ghcr.io/cirruslabs/ubuntu:latest",
    ]

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: "Pull Image", systemName: "square.and.arrow.down")
            Form {
                Section("Image") {
                    TextField("OCI reference", text: $options.reference)
                        .font(.system(.body, design: .monospaced))
                }

                Section("Common Images") {
                    ForEach(presets, id: \.self) { preset in
                        Button {
                            options.reference = preset
                        } label: {
                            HStack {
                                Text(preset)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundStyle(.primary)
                                Spacer()
                                if options.reference == preset {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section("Transfer") {
                    Stepper("Concurrency: \(options.concurrency)", value: $options.concurrency, in: 1...32)
                    Toggle("Allow an insecure HTTP registry", isOn: $options.insecure)
                }
            }
            .formStyle(.grouped)

            SheetButtons(primaryTitle: "Pull", isDisabled: trimmedReference.isEmpty) {
                options.reference = trimmedReference
                onAdd(options)
                dismiss()
            }
        }
        .frame(width: 680, height: 520)
    }

    private var trimmedReference: String {
        options.reference.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
