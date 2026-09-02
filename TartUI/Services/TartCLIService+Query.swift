import Foundation

extension TartCLIService {
    func version() async throws -> String {
        let result = try await run(["--version"])
        return result.output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func images() async throws -> [TartImage] {
        let records = try await list(source: "oci")
        let taggedRepositories = Set(
            records
                .filter { !$0.name.contains("@sha256:") }
                .map {
                    TartImage(reference: $0.name, diskGB: $0.disk, sizeGB: $0.size, accessed: $0.accessed)
                        .repositoryWithoutReference
                }
        )

        return
            records
            .map { TartImage(reference: $0.name, diskGB: $0.disk, sizeGB: $0.size, accessed: $0.accessed) }
            .filter { !$0.isDigestReference || !taggedRepositories.contains($0.repositoryWithoutReference) }
            .sorted { $0.reference.localizedCaseInsensitiveCompare($1.reference) == .orderedAscending }
    }

    func virtualMachines() async throws -> [TartVirtualMachine] {
        try await list(source: "local")
            .map {
                TartVirtualMachine(
                    name: $0.name,
                    diskGB: $0.disk,
                    sizeGB: $0.size,
                    running: $0.running,
                    rawState: $0.state,
                    accessed: $0.accessed
                )
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func details(for name: String) async throws -> TartVMDetails {
        let result = try await run(["get", name, "--format", "json"])
        do {
            return try decoder.decode(TartVMDetails.self, from: Data(result.output.utf8))
        } catch {
            throw TartUIError.invalidResponse("Could not read details for \(name).")
        }
    }

    func localConfiguration(for name: String) async -> LocalVMConfiguration? {
        let url = vmDirectory(for: name).appendingPathComponent("config.json")
        return await Task.detached(priority: .utility) {
            guard let data = try? Data(contentsOf: url) else { return nil }
            return try? JSONDecoder().decode(LocalVMConfiguration.self, from: data)
        }.value
    }

    func hostInfo(for name: String) async -> VMHostInfo {
        let directory = vmDirectory(for: name)
        let allocatedBytes = await Task.detached(priority: .utility) {
            var total: Int64 = 0
            let keys: Set<URLResourceKey> = [.isRegularFileKey, .totalFileAllocatedSizeKey, .fileAllocatedSizeKey]
            guard
                let enumerator = FileManager.default.enumerator(
                    at: directory,
                    includingPropertiesForKeys: Array(keys),
                    options: [.skipsHiddenFiles]
                )
            else { return total }

            while let fileURL = enumerator.nextObject() as? URL {
                guard let values = try? fileURL.resourceValues(forKeys: keys), values.isRegularFile == true else {
                    continue
                }
                total += Int64(values.totalFileAllocatedSize ?? values.fileAllocatedSize ?? 0)
            }
            return total
        }.value
        return VMHostInfo(directory: directory, allocatedBytes: allocatedBytes)
    }
}
