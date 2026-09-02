import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct CreateVMSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var options: VMCreateOptions
    @State private var showAdvanced = false

    let images: [TartImage]
    let virtualMachines: [TartVirtualMachine]
    let onCreate: (VMCreateOptions) -> Void

    init(
        images: [TartImage],
        virtualMachines: [TartVirtualMachine],
        preferredImage: TartImage?,
        onCreate: @escaping (VMCreateOptions) -> Void
    ) {
        self.images = images
        self.virtualMachines = virtualMachines
        self.onCreate = onCreate
        var initial = VMCreateOptions()
        initial.source = preferredImage?.reference ?? images.first?.reference ?? virtualMachines.first?.name ?? ""
        _options = State(initialValue: initial)
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: "Create Virtual Machine", systemName: "plus.rectangle.on.rectangle")
            Form {
                Section("Virtual Machine") {
                    TextField("Name", text: $options.name)
                    Picker("Create from", selection: $options.mode) {
                        ForEach(VMCreationMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                }

                sourceSection

                if options.mode == .macOS || options.mode == .linux {
                    Section("Disk") {
                        Stepper("Size: \(options.diskGB) GB", value: $options.diskGB, in: 20...2000, step: 10)
                        Picker("Format", selection: $options.diskFormat) {
                            ForEach(DiskImageFormat.allCases) { format in
                                Text(format.title).tag(format)
                            }
                        }
                        if options.diskFormat == .asif {
                            Label("ASIF requires macOS 26 or later.", systemImage: "info.circle")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if options.mode == .clone {
                    DisclosureGroup("Transfer Options", isExpanded: $showAdvanced) {
                        Stepper("Concurrency: \(options.concurrency)", value: $options.concurrency, in: 1...32)
                        Stepper(
                            "Automatic prune limit: \(options.pruneLimitGB) GB", value: $options.pruneLimitGB,
                            in: 0...1000, step: 10)
                        Toggle("Allow an insecure HTTP registry", isOn: $options.insecure)
                    }
                }
            }
            .formStyle(.grouped)

            SheetButtons(primaryTitle: "Create", isDisabled: !canCreate) {
                normalizeOptions()
                onCreate(options)
                dismiss()
            }
        }
        .frame(width: 700, height: 570)
    }

    @ViewBuilder
    private var sourceSection: some View {
        switch options.mode {
        case .clone:
            Section("Source") {
                TextField("Image or local VM", text: $options.source)
                    .font(.system(.body, design: .monospaced))
                if !sourceCandidates.isEmpty {
                    Picker("Available", selection: $options.source) {
                        ForEach(sourceCandidates, id: \.value) { item in
                            Text("\(item.name) — \(item.kind)").tag(item.value)
                        }
                    }
                }
            }
        case .macOS:
            Section("Restore Image") {
                HStack {
                    TextField("latest, URL, or IPSW path", text: $options.ipswSource)
                        .font(.system(.body, design: .monospaced))
                    Button("Choose…") {
                        if let url = chooseFile(extensions: ["ipsw"]) {
                            options.ipswSource = url.path
                        }
                    }
                }
            }
        case .linux:
            Section("Installation") {
                Label(
                    "Attach an installer image from Run > Additional Disks on first boot.",
                    systemImage: "opticaldiscdrive"
                )
                .foregroundStyle(.secondary)
            }
        case .importArchive:
            Section("Archive") {
                HStack {
                    TextField(".tvm path", text: $options.archivePath)
                        .font(.system(.body, design: .monospaced))
                    Button("Choose…") {
                        if let url = chooseFile(extensions: ["tvm"]) {
                            options.archivePath = url.path
                        }
                    }
                }
            }
        }
    }

    private var sourceCandidates: [(name: String, kind: String, value: String)] {
        images.map { ($0.title, "OCI image", $0.reference) }
            + virtualMachines.map { ($0.name, "local VM", $0.name) }
    }

    private var canCreate: Bool {
        guard !trimmedName.isEmpty else { return false }
        switch options.mode {
        case .clone: return !options.source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .macOS: return !options.ipswSource.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .linux: return true
        case .importArchive: return !options.archivePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private var trimmedName: String {
        options.name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func normalizeOptions() {
        options.name = trimmedName
        options.source = options.source.trimmingCharacters(in: .whitespacesAndNewlines)
        options.ipswSource = options.ipswSource.trimmingCharacters(in: .whitespacesAndNewlines)
        options.archivePath = options.archivePath.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
