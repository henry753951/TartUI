import Foundation

@MainActor
extension TartAppModel {
    func pullImage(_ options: ImagePullOptions) async {
        await perform(message: String(localized: "Pulling image…")) { try await service.pullImage(options) }
    }

    func createVM(_ options: VMCreateOptions) async {
        await perform(message: String(localized: "Creating \(options.name)…")) { try await service.createVM(options) }
        guard errorMessage == nil else { return }
        selection = .virtualMachines
        searchText = ""
        selectedVMID = options.name
        await loadSelectedVMInformation(includeRuntime: false)
    }

    func runSelectedVM(options: RunOptions) async {
        guard let vm = selectedVM else { return }
        isPerformingAction = true
        activityMessage = String(localized: "Starting \(vm.name)…")
        defer {
            isPerformingAction = false
            activityMessage = nil
        }
        do {
            try service.runVM(name: vm.name, options: options)
            runOptionsStore.save(options, for: vm.name)
            try? await Task.sleep(for: .seconds(1))
            await refresh()
        } catch {
            present(error)
        }
    }

    func stopSelectedVM() async {
        guard let vm = selectedVM else { return }
        await perform(message: String(localized: "Stopping \(vm.name)…")) { try await service.stopVM(name: vm.name) }
    }

    func suspendSelectedVM() async {
        guard let vm = selectedVM else { return }
        await perform(message: String(localized: "Suspending \(vm.name)…")) {
            try await service.suspendVM(name: vm.name)
        }
    }

    func saveVMSettings(_ options: VMEditOptions) async {
        var resultingName: String?
        await perform(message: String(localized: "Saving \(options.originalName)…")) {
            resultingName = try await service.updateVM(options)
        }
        if let resultingName {
            if resultingName != options.originalName {
                runOptionsStore.move(from: options.originalName, to: resultingName)
            }
            selectedVMID = resultingName
            await loadSelectedVMInformation(includeRuntime: true)
        }
    }

    func deleteSelectedVM() async {
        guard let vm = selectedVM else { return }
        await perform(message: String(localized: "Deleting \(vm.name)…")) { try await service.deleteVM(name: vm.name) }
        if errorMessage == nil { runOptionsStore.remove(for: vm.name) }
    }

    func deleteSelectedImage() async {
        guard let image = selectedImage else { return }
        await perform(message: String(localized: "Deleting image…")) { try await service.deleteImage(image.reference) }
    }

    func refreshRuntimeInformation(wait: Int = 0) async {
        guard let vm = selectedVM, vm.running else {
            runtimeInfo = nil
            return
        }
        guard !isRefreshingRuntime else { return }
        isRefreshingRuntime = true
        defer { isRefreshingRuntime = false }

        let address = try? await service.ipAddress(for: vm.name, resolver: ipResolver, wait: wait)
        runtimeInfo = await service.guestInformation(
            for: vm.name,
            ipAddress: address,
            resolver: ipResolver
        )
    }

    func openSSH() {
        guard let address = runtimeInfo?.ipAddress else { return }
        do {
            try hostIntegration.openSSHInTerminal(
                username: sshUsername.trimmingCharacters(in: .whitespacesAndNewlines),
                address: address
            )
        } catch {
            present(error)
        }
    }

    func copySSHCommand() {
        guard let sshCommand else { return }
        hostIntegration.copyToPasteboard(sshCommand)
        let copiedMessage = String(localized: "SSH command copied")
        activityMessage = copiedMessage
        Task {
            try? await Task.sleep(for: .seconds(2))
            if activityMessage == copiedMessage { activityMessage = nil }
        }
    }

    func revealSelectedVMLocation() {
        guard let url = selectedVMHostInfo?.directory else { return }
        hostIntegration.revealInFinder(url)
    }

    func exportSelectedVM() async {
        guard let vm = selectedVM else { return }
        guard let url = hostIntegration.chooseExportDestination(suggestedName: "\(vm.name).tvm") else { return }
        await perform(message: String(localized: "Exporting \(vm.name)…")) {
            try await service.exportVM(name: vm.name, to: url.path)
        }
    }
}
