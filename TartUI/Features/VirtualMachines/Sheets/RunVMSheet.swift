import SwiftUI

struct RunVMSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var options: RunOptions
    @State private var sharedDirectories: [SharedDirectoryDraft]
    @State private var diskAttachments: [DiskAttachmentDraft]
    @FocusState private var rosettaFieldFocused: Bool
    let vm: TartVirtualMachine
    let onRun: (RunOptions) -> Void

    init(vm: TartVirtualMachine, initialOptions: RunOptions, onRun: @escaping (RunOptions) -> Void) {
        self.vm = vm
        self.onRun = onRun
        _options = State(initialValue: initialOptions)
        _sharedDirectories = State(
            initialValue: initialOptions.directoryShareArguments.map(SharedDirectoryDraft.init(argument:))
        )
        _diskAttachments = State(
            initialValue: initialOptions.additionalDiskArguments.map(DiskAttachmentDraft.init(argument:))
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: "Run \(vm.name)", systemName: "play.fill")
            Form {
                Section("Presentation") {
                    Picker("Mode", selection: $options.presentation) {
                        ForEach(RunPresentation.allCases) { presentation in
                            Text(presentation.title).tag(presentation)
                        }
                    }
                    if options.presentation == .serial {
                        TextField("Serial path (optional)", text: $options.serialPath)
                    }
                    Toggle("Recovery mode", isOn: $options.recovery)
                }

                Section("Network") {
                    Picker("Mode", selection: $options.networkMode) {
                        ForEach(RunNetworkMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    if options.networkMode == .bridged {
                        TextField("Interface name", text: $options.bridgedInterface)
                    }
                    if options.networkMode == .softnet {
                        TextField("Allowed CIDRs", text: $options.softnetAllow)
                        TextField("Blocked CIDRs", text: $options.softnetBlock)
                        TextField("Exposed ports", text: $options.softnetExpose)
                    }
                }

                Section("Devices") {
                    Toggle("Disable audio", isOn: $options.noAudio)
                    Toggle("Disable clipboard", isOn: $options.noClipboard)
                    Toggle("Nested virtualization", isOn: $options.nested)
                    Toggle("Suspendable", isOn: $options.suspendable)
                    Toggle("Capture system keys", isOn: $options.captureSystemKeys)
                    Toggle("Disable trackpad", isOn: $options.noTrackpad)
                    Toggle("Disable pointer", isOn: $options.noPointer)
                    Toggle("Disable keyboard", isOn: $options.noKeyboard)
                    TextField("Rosetta share tag (Linux)", text: $options.rosettaTag)
                        .focused($rosettaFieldFocused)
                }

                Section("Shared Directories") {
                    if sharedDirectories.isEmpty {
                        AttachmentEmptyState(
                            systemName: "folder.badge.plus",
                            text: "No folders are shared with this virtual machine."
                        )
                    } else {
                        ForEach($sharedDirectories) { $directory in
                            SharedDirectoryRow(directory: $directory) {
                                sharedDirectories.removeAll { $0.id == directory.id }
                            }
                        }
                    }

                    HStack {
                        Button("Add Folder…", systemImage: "plus") {
                            if let url = chooseDirectory() {
                                sharedDirectories.append(SharedDirectoryDraft(path: url.path))
                            }
                        }
                        Spacer()
                        Text("\(sharedDirectories.count) shared")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Additional Disks") {
                    if diskAttachments.isEmpty {
                        AttachmentEmptyState(
                            systemName: "externaldrive.badge.plus",
                            text: "No additional disks are attached."
                        )
                    } else {
                        ForEach($diskAttachments) { $disk in
                            DiskAttachmentRow(disk: $disk) {
                                diskAttachments.removeAll { $0.id == disk.id }
                            }
                        }
                    }

                    HStack {
                        Button("Add Disk Image…", systemImage: "plus") {
                            if let url = chooseAnyFile() {
                                diskAttachments.append(DiskAttachmentDraft(source: url.path))
                            }
                        }
                        Button("Add Reference") {
                            diskAttachments.append(DiskAttachmentDraft())
                        }
                        Spacer()
                        Text("\(diskAttachments.count) attached")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Root Disk") {
                    Toggle("Read only", isOn: $options.rootDiskReadOnly)
                    Picker("Caching", selection: $options.rootDiskCaching) {
                        ForEach(RootDiskCaching.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    Picker("Synchronization", selection: $options.rootDiskSync) {
                        ForEach(RootDiskSync.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                }
            }
            .formStyle(.grouped)

            SheetButtons(primaryTitle: "Run \(vm.name)", isDisabled: !canRun) {
                options.directoryShares = sharedDirectories.compactMap(\.argument).joined(separator: "\n")
                options.additionalDisks = diskAttachments.compactMap(\.argument).joined(separator: "\n")
                onRun(options)
                dismiss()
            }
        }
        .frame(width: 720, height: 720)
        .onAppear {
            Task { @MainActor in
                await Task.yield()
                rosettaFieldFocused = false
            }
        }
    }

    private var canRun: Bool {
        let networkIsValid =
            options.networkMode != .bridged
            || !options.bridgedInterface.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return networkIsValid
            && sharedDirectories.allSatisfy(\.isValid)
            && diskAttachments.allSatisfy(\.isValid)
    }
}
