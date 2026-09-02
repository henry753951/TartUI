import Foundation

extension TartCLIService {
    func pullImage(_ options: ImagePullOptions) async throws {
        var arguments = ["pull", options.reference]
        if options.insecure { arguments.append("--insecure") }
        arguments += ["--concurrency", String(options.concurrency)]
        _ = try await run(arguments)
    }

    func deleteImage(_ reference: String) async throws {
        _ = try await run(["delete", reference])
    }

    func createVM(_ options: VMCreateOptions) async throws {
        switch options.mode {
        case .clone:
            var arguments = ["clone", options.source, options.name]
            if options.insecure { arguments.append("--insecure") }
            arguments += [
                "--concurrency", String(options.concurrency),
                "--prune-limit", String(options.pruneLimitGB),
            ]
            _ = try await run(arguments)
        case .macOS:
            _ = try await run([
                "create", options.name,
                "--from-ipsw", options.ipswSource,
                "--disk-size", String(options.diskGB),
                "--disk-format", options.diskFormat.rawValue,
            ])
        case .linux:
            _ = try await run([
                "create", options.name,
                "--linux",
                "--disk-size", String(options.diskGB),
                "--disk-format", options.diskFormat.rawValue,
            ])
        case .importArchive:
            _ = try await run(["import", options.archivePath, options.name])
        }
    }

    func runVM(name: String, options: RunOptions) throws {
        let process = Process()
        process.executableURL = try resolvedExecutableURL()
        process.arguments = runArguments(name: name, options: options)
        try process.run()
    }

    func stopVM(name: String) async throws {
        _ = try await run(["stop", name])
    }

    func suspendVM(name: String) async throws {
        _ = try await run(["suspend", name])
    }

    func deleteVM(name: String) async throws {
        _ = try await run(["delete", name])
    }

    func updateVM(_ options: VMEditOptions) async throws -> String {
        var arguments = [
            "set", options.originalName,
            "--cpu", String(options.cpu),
            "--memory", String(options.memoryMB),
            "--display", options.displayArgument,
            options.displayRefit ? "--display-refit" : "--no-display-refit",
            "--disk-size", String(options.diskGB),
        ]
        if options.randomMAC { arguments.append("--random-mac") }
        if options.randomSerial { arguments.append("--random-serial") }
        let replacementPath = options.replacementDiskPath.trimmingCharacters(in: .whitespacesAndNewlines)
        if !replacementPath.isEmpty { arguments += ["--disk", replacementPath] }
        _ = try await run(arguments)

        let trimmedName = options.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName != options.originalName {
            _ = try await run(["rename", options.originalName, trimmedName])
            return trimmedName
        }
        return options.originalName
    }

    func exportVM(name: String, to path: String) async throws {
        _ = try await run(["export", name, path])
    }
}
