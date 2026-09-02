import SwiftUI

struct EditVMSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var options: VMEditOptions
    private let minimumDiskGB: Int
    let onSave: (VMEditOptions) -> Void

    init(initialOptions: VMEditOptions, onSave: @escaping (VMEditOptions) -> Void) {
        _options = State(initialValue: initialOptions)
        minimumDiskGB = initialOptions.diskGB
        self.onSave = onSave
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: "Edit VM Settings", systemName: "gearshape.fill")
            Form {
                Section("General") {
                    TextField("Name", text: $options.name)
                }

                Section("Hardware") {
                    Stepper("CPU: \(options.cpu)", value: $options.cpu, in: 1...64)
                    Stepper("Memory: \(memoryText)", value: $options.memoryMB, in: 1024...262_144, step: 1024)
                }

                Section("Display") {
                    HStack {
                        TextField("Width", value: $options.displayWidth, format: .number)
                        Text("×")
                        TextField("Height", value: $options.displayHeight, format: .number)
                        Picker("", selection: $options.displayUnit) {
                            Text("pt").tag("pt")
                            Text("px").tag("px")
                        }
                        .labelsHidden()
                        .frame(width: 80)
                    }
                    Toggle("Automatically fit the display to the window", isOn: $options.displayRefit)
                }

                Section("Storage") {
                    Stepper("Disk: \(options.diskGB) GB", value: $options.diskGB, in: minimumDiskGB...2000, step: 10)
                    HStack {
                        TextField("Replacement disk path (optional)", text: $options.replacementDiskPath)
                            .font(.system(.body, design: .monospaced))
                        Button("Choose…") {
                            if let url = chooseFile(extensions: ["img", "raw"]) {
                                options.replacementDiskPath = url.path
                            }
                        }
                    }
                    if !options.replacementDiskPath.isEmpty {
                        Label(
                            "This replaces the VM disk contents when settings are saved.",
                            systemImage: "exclamationmark.triangle"
                        )
                        .font(.caption)
                        .foregroundStyle(.orange)
                    }
                }

                Section("Identity") {
                    Toggle("Generate a new MAC address", isOn: $options.randomMAC)
                    Toggle("Generate a new macOS serial number", isOn: $options.randomSerial)
                }
            }
            .formStyle(.grouped)

            SheetButtons(primaryTitle: "Save", isDisabled: !canSave) {
                options.name = options.name.trimmingCharacters(in: .whitespacesAndNewlines)
                onSave(options)
                dismiss()
            }
        }
        .frame(width: 680, height: 650)
    }

    private var memoryText: String {
        options.memoryMB.isMultiple(of: 1024)
            ? "\(options.memoryMB / 1024) GB"
            : "\(options.memoryMB) MB"
    }

    private var canSave: Bool {
        !options.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && options.displayWidth > 0
            && options.displayHeight > 0
    }
}
