import Foundation

struct TartExecutableLocator: Sendable {
    func resolve() -> URL? {
        let configuredPath = UserDefaults.standard.string(forKey: PreferenceKey.tartExecutablePath) ?? ""
        let candidates =
            configuredPath.isEmpty
            ? ["/opt/homebrew/bin/tart", "/usr/local/bin/tart"]
            : [configuredPath, "/opt/homebrew/bin/tart", "/usr/local/bin/tart"]

        return
            candidates
            .map(URL.init(fileURLWithPath:))
            .first { FileManager.default.isExecutableFile(atPath: $0.path) }
    }
}
