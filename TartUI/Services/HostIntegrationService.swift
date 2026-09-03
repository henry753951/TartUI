import AppKit
import UniformTypeIdentifiers

@MainActor
struct HostIntegrationService {
    func copyToPasteboard(_ value: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
    }

    func revealInFinder(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func chooseExportDestination(suggestedName: String) -> URL? {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = suggestedName
        panel.allowedContentTypes = [.archive]
        return panel.runModal() == .OK ? panel.url : nil
    }

    func chooseExecutable() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.prompt = String(localized: "Choose")
        return panel.runModal() == .OK ? panel.url : nil
    }

    func openSSHInTerminal(username: String, address: String) throws {
        let destination = username.isEmpty ? address : "\(username)@\(address)"
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("TartUI-Terminal", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let scriptURL = directory.appendingPathComponent("ssh-\(UUID().uuidString).command")
        let script = """
            #!/bin/zsh
            /bin/rm -f \(shellQuoted(scriptURL.path))
            exec /usr/bin/ssh \(shellQuoted(destination))
            """
        try script.write(to: scriptURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o700],
            ofItemAtPath: scriptURL.path
        )

        guard NSWorkspace.shared.open(scriptURL) else {
            try? FileManager.default.removeItem(at: scriptURL)
            throw TartUIError.invalidResponse(String(localized: "Terminal could not be opened."))
        }
    }

    private func shellQuoted(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
