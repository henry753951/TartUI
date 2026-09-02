import AppKit
import SwiftUI

struct VMDetailView: View {
    @Bindable var model: TartAppModel
    let vm: TartVirtualMachine
    let onDelete: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ResourceHeader(
                    systemName: "macwindow",
                    color: .primary,
                    title: vm.name,
                    status: vm.state.title,
                    isRunning: vm.running
                ) {
                    actionBar
                }
                MetadataStrip(items: metadataItems)
                configurationSection
                networkSection
                guestSection
                storageSection
            }
            .padding(.horizontal, 36)
            .padding(.vertical, 32)
            .frame(maxWidth: 880, alignment: .leading)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var actionBar: some View {
        HStack(spacing: 10) {
            if vm.running {
                Button {
                    Task { await model.stopSelectedVM() }
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                Button {
                    model.openSSH()
                } label: {
                    Image(systemName: "terminal")
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.circle)
                .tint(.green)
                .help("Open SSH in Terminal")
                .disabled(model.sshCommand == nil)
            } else {
                Button {
                    Task { await model.quickRunSelectedVM() }
                } label: {
                    Label("Run", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                Button {
                    model.prepareRunSheet()
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .help("Run With Options…")
                Button {
                    model.prepareEditSheet()
                } label: {
                    Image(systemName: "gearshape.fill")
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.circle)
                .help("Edit Settings…")
            }

            Menu {
                if vm.running {
                    Button("Suspend") { Task { await model.suspendSelectedVM() } }
                    Divider()
                } else {
                    Button("Export…") { Task { await model.exportSelectedVM() } }
                }
                Button("Reveal in Finder") { model.revealSelectedVMLocation() }
                Divider()
                Button("Delete Virtual Machine", role: .destructive, action: onDelete)
            } label: {
                Image(systemName: "ellipsis")
            }
            .menuStyle(.button)
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            .menuIndicator(.hidden)
            .help("More Actions")
        }
        .controlSize(.large)
        .disabled(model.isPerformingAction)
    }

    private var metadataItems: [MetadataStrip.Item] {
        [
            .init(
                systemName: "internaldrive",
                value: model.selectedVMDetails.map { "\($0.disk) GB disk" } ?? "—"
            ),
            .init(
                systemName: "externaldrive",
                value: model.selectedVMHostInfo?.allocatedText ?? String(localized: "Calculating…")
            ),
            .init(systemName: "server.rack", value: "Local"),
        ]
    }

    private var configurationSection: some View {
        SectionPanel("Configuration") {
            InfoGrid(items: configurationItems)
            if let macAddress = model.selectedVMConfiguration?.macAddress {
                InfoRow("MAC address", value: macAddress, monospaced: true)
            }
        }
    }

    private var networkSection: some View {
        SectionPanel("Network") {
            if vm.running {
                HStack {
                    Picker("Resolver", selection: $model.ipResolver) {
                        ForEach(IPResolver.allCases) { resolver in
                            Text(resolver.title).tag(resolver)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 300)
                    Spacer()
                    Button {
                        Task { await model.refreshRuntimeInformation(wait: 5) }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .disabled(model.isRefreshingRuntime)
                }
                .onChange(of: model.ipResolver) { _, _ in
                    Task { await model.refreshRuntimeInformation(wait: 2) }
                }

                InfoRow(
                    "IP address", value: model.runtimeInfo?.ipAddress ?? String(localized: "Unavailable"),
                    monospaced: true)

                if let interfaces = model.runtimeInfo?.networkInterfaces {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("Guest interfaces")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(interfaces)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack {
                    TextField("Username", text: $model.sshUsername)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 150)
                    Text(model.sshCommand ?? String(localized: "Waiting for an IP address"))
                        .font(.system(.callout, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .textSelection(.enabled)
                    Spacer()
                    Button("Copy") { model.copySSHCommand() }
                        .disabled(model.sshCommand == nil)
                    Button("Open Terminal") { model.openSSH() }
                        .disabled(model.sshCommand == nil)
                }
            } else {
                UnavailableRow(
                    systemName: "network.slash",
                    text: "Network information is available while the virtual machine is running.")
            }
        }
    }

    private var guestSection: some View {
        SectionPanel("Guest System") {
            if vm.running, let runtime = model.runtimeInfo {
                if runtime.guestAgentAvailable {
                    InfoRow("Operating system", value: runtime.operatingSystem ?? String(localized: "Unknown"))
                    InfoRow("Hostname", value: runtime.hostname ?? String(localized: "Unknown"))
                    InfoRow("Kernel", value: runtime.kernel ?? String(localized: "Unknown"))
                    InfoRow("Architecture", value: runtime.architecture ?? String(localized: "Unknown"))
                    InfoRow("Uptime", value: runtime.uptime ?? String(localized: "Unknown"))
                    InfoRow("Memory", value: runtime.memoryUsage ?? String(localized: "Unknown"))
                    InfoRow("Root disk", value: runtime.diskUsage ?? String(localized: "Unknown"))
                } else {
                    UnavailableRow(
                        systemName: "bolt.horizontal.circle",
                        text: "Tart Guest Agent is unavailable. IP resolution may still work through DHCP or ARP.")
                }
            } else if vm.running {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                UnavailableRow(
                    systemName: "power", text: "Start the virtual machine to query its operating system and usage.")
            }
        }
    }

    private var storageSection: some View {
        SectionPanel("Storage") {
            InfoRow("Reported size", value: "\(vm.sizeGB) GB")
            InfoRow(
                "Host allocation", value: model.selectedVMHostInfo?.allocatedText ?? String(localized: "Calculating…"))
            if let path = model.selectedVMHostInfo?.directory.path {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Location")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack {
                        Text(path)
                            .font(.system(.callout, design: .monospaced))
                            .textSelection(.enabled)
                            .lineLimit(2)
                        Spacer()
                        Button("Show in Finder") { model.revealSelectedVMLocation() }
                    }
                }
            }
        }
    }

    private var configurationItems: [InfoGrid.Item] {
        let details = model.selectedVMDetails
        let config = model.selectedVMConfiguration
        return [
            .init(label: "Operating system", value: details?.osName ?? config?.os.capitalized ?? "—"),
            .init(label: "Architecture", value: config?.arch ?? "—"),
            .init(label: "CPU", value: details.map { "\($0.cpu) cores" } ?? "—"),
            .init(label: "Memory", value: details?.memoryText ?? "—"),
            .init(label: "Display", value: details?.display ?? "—"),
            .init(label: "Virtual disk", value: details.map { "\($0.disk) GB" } ?? "—"),
            .init(label: "Disk format", value: details?.diskFormat?.uppercased() ?? "—"),
        ]
    }
}
