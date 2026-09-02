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
        let command = "ssh " + shellQuoted(destination)
        let appleScriptCommand =
            command
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let script = """
            tell application "Terminal"
                activate
                do script "\(appleScriptCommand)"
            end tell
            """
        var error: NSDictionary?
        NSAppleScript(source: script)?.executeAndReturnError(&error)
        if let error { throw TartUIError.invalidResponse(error.description) }
    }

    private func shellQuoted(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
