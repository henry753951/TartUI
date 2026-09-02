import Foundation

struct TartCLIService: Sendable {
    let decoder = JSONDecoder()

    var executableURL: URL? {
        TartExecutableLocator().resolve()
    }

    var tartHomeURL: URL {
        if let path = ProcessInfo.processInfo.environment["TART_HOME"], !path.isEmpty {
            return URL(fileURLWithPath: path, isDirectory: true)
        }
        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".tart", isDirectory: true)
    }

    func vmDirectory(for name: String) -> URL {
        tartHomeURL.appendingPathComponent("vms", isDirectory: true)
            .appendingPathComponent(name, isDirectory: true)
    }

    func list(source: String) async throws -> [TartListRecord] {
        let result = try await run(["list", "--source", source, "--format", "json"])
        do {
            return try decoder.decode([TartListRecord].self, from: Data(result.output.utf8))
        } catch {
            throw TartUIError.invalidResponse("Tart returned an unreadable \(source) list.")
        }
    }

    func resolvedExecutableURL() throws -> URL {
        guard let executableURL else { throw TartUIError.tartNotInstalled }
        return executableURL
    }

    func run(_ arguments: [String]) async throws -> CommandResult {
        let executableURL = try resolvedExecutableURL()
        return try await Task.detached(priority: .userInitiated) {
            let process = Process()
            let outputPipe = Pipe()
            process.executableURL = executableURL
            process.arguments = arguments
            process.standardOutput = outputPipe
            process.standardError = outputPipe

            try process.run()
            let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()

            let output = String(decoding: data, as: UTF8.self)
            guard process.terminationStatus == 0 else {
                throw TartUIError.commandFailed(
                    arguments: arguments,
                    exitCode: process.terminationStatus,
                    output: output.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }
            return CommandResult(output: output, exitCode: process.terminationStatus)
        }.value
    }
}
