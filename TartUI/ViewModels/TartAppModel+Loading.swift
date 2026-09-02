import Foundation

@MainActor
extension TartAppModel {
    func dismissError() {
        errorMessage = nil
    }

    var displayComponents: (width: Int, height: Int) {
        guard let display = selectedVMDetails?.display else { return (1024, 768) }
        let value = display.replacingOccurrences(of: "pt", with: "").replacingOccurrences(of: "px", with: "")
        let parts = value.split(separator: "x").compactMap { Int($0) }
        return parts.count == 2 ? (parts[0], parts[1]) : (1024, 768)
    }

    func loadSelectedVMInformation(includeRuntime: Bool) async {
        guard let vm = selectedVM else {
            selectedVMDetails = nil
            selectedVMConfiguration = nil
            selectedVMHostInfo = nil
            runtimeInfo = nil
            return
        }

        async let details = try? service.details(for: vm.name)
        async let configuration = service.localConfiguration(for: vm.name)
        async let hostInfo = service.hostInfo(for: vm.name)
        selectedVMDetails = await details
        selectedVMConfiguration = await configuration
        selectedVMHostInfo = await hostInfo

        if includeRuntime && vm.running {
            await refreshRuntimeInformation()
        } else if !vm.running {
            runtimeInfo = nil
        }
    }

    func perform(message: String, _ operation: () async throws -> Void) async {
        guard !isPerformingAction else { return }
        isPerformingAction = true
        activityMessage = message
        errorMessage = nil
        defer {
            isPerformingAction = false
            activityMessage = nil
        }
        do {
            try await operation()
            await refresh()
        } catch {
            present(error)
        }
    }

    func validSelection<T: Equatable>(_ selection: T?, in values: [T]) -> T? {
        guard let selection, values.contains(selection) else { return nil }
        return selection
    }

    func present(_ error: Error) {
        errorMessage = error.localizedDescription
    }
}
