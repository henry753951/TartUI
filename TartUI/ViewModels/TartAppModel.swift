import Observation
import SwiftUI

@Observable
@MainActor
final class TartAppModel {
    var selection: AppSection? = .virtualMachines
    var images: [TartImage] = []
    var virtualMachines: [TartVirtualMachine] = []
    var selectedImageID: TartImage.ID?
    var selectedVMID: TartVirtualMachine.ID?
    var selectedVMDetails: TartVMDetails?
    var selectedVMConfiguration: LocalVMConfiguration?
    var selectedVMHostInfo: VMHostInfo?
    var runtimeInfo: VMRuntimeInfo?
    var settings = AppSettings.shared
    var searchText = ""
    var sheetRoute: SheetRoute?
    var runOptions = RunOptions()
    var editOptions = VMEditOptions()
    var isRefreshing = false
    var isRefreshingRuntime = false
    var isPerformingAction = false
    var tartVersion = ""
    var activityMessage: String?
    var errorMessage: String?

    let service = TartCLIService()
    let hostIntegration = HostIntegrationService()
    let runOptionsStore = RunOptionsStore()

    var ipResolver: IPResolver {
        get { settings.ipResolver }
        set { settings.ipResolver = newValue }
    }

    var sshUsername: String {
        get { settings.sshUsername }
        set { settings.sshUsername = newValue }
    }

    var currentSection: AppSection { selection ?? .images }

    var filteredImages: [TartImage] {
        guard !searchText.isEmpty else { return images }
        return images.filter { $0.reference.localizedCaseInsensitiveContains(searchText) }
    }

    var filteredVMs: [TartVirtualMachine] {
        guard !searchText.isEmpty else { return virtualMachines }
        return virtualMachines.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
                || $0.state.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }

    var selectedImage: TartImage? {
        guard let selectedImageID else { return filteredImages.first }
        return images.first { $0.id == selectedImageID }
    }

    var selectedVM: TartVirtualMachine? {
        guard let selectedVMID else { return filteredVMs.first }
        return virtualMachines.first { $0.id == selectedVMID }
    }

    var sshCommand: String? {
        guard let address = runtimeInfo?.ipAddress else { return nil }
        let username = sshUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        return username.isEmpty ? "ssh \(address)" : "ssh \(username)@\(address)"
    }

    func load() async {
        guard tartVersion.isEmpty else { return }
        do {
            tartVersion = try await service.version()
            await refresh()
        } catch {
            present(error)
        }
    }

    func selectSection(_ section: AppSection) {
        selection = section
        searchText = ""
    }

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            async let loadedImages = service.images()
            async let loadedVMs = service.virtualMachines()
            let (images, vms) = try await (loadedImages, loadedVMs)
            self.images = images
            virtualMachines = vms
            selectedImageID = validSelection(selectedImageID, in: images.map(\.id)) ?? images.first?.id
            selectedVMID = validSelection(selectedVMID, in: vms.map(\.id)) ?? vms.first?.id
            await loadSelectedVMInformation(includeRuntime: true)
        } catch {
            present(error)
        }
    }

    func selectImage(_ image: TartImage) {
        selectedImageID = image.id
    }

    func selectVM(_ vm: TartVirtualMachine) async {
        selectedVMID = vm.id
        runtimeInfo = nil
        await loadSelectedVMInformation(includeRuntime: true)
    }

    func showAddSheet() {
        sheetRoute = currentSection == .images ? .addImage : .createVM
    }

    func showCreateVM(from image: TartImage? = nil) {
        if let image { selectedImageID = image.id }
        sheetRoute = .createVM
    }

    func prepareRunSheet() {
        guard let vm = selectedVM else { return }
        runOptions = runOptionsStore.load(for: vm.name) ?? RunOptions()
        sheetRoute = .runVM
    }

    func quickRunSelectedVM() async {
        guard let vm = selectedVM else { return }
        await runSelectedVM(options: runOptionsStore.load(for: vm.name) ?? RunOptions())
    }

    func prepareEditSheet() {
        guard let vm = selectedVM else { return }
        let config = selectedVMConfiguration
        editOptions = VMEditOptions(
            originalName: vm.name,
            name: vm.name,
            cpu: config?.cpuCount ?? selectedVMDetails?.cpu ?? 4,
            memoryMB: config?.memoryMB ?? selectedVMDetails?.memory ?? 4096,
            displayWidth: config?.display.width ?? displayComponents.width,
            displayHeight: config?.display.height ?? displayComponents.height,
            displayUnit: config?.display.unit ?? "pt",
            displayRefit: config?.displayRefit ?? true,
            diskGB: selectedVMDetails?.disk ?? vm.diskGB
        )
        sheetRoute = .editVM
    }
}
