import Foundation
import Observation

enum PreferenceKey {
    static let defaultImageReference = "defaultImageReference"
    static let ipResolver = "ipResolver"
    static let sshUsername = "sshUsername"
    static let tartExecutablePath = "tartExecutablePath"
}

@Observable
@MainActor
final class AppSettings {
    static let shared = AppSettings()

    var defaultImageReference: String {
        didSet { defaults.set(defaultImageReference, forKey: PreferenceKey.defaultImageReference) }
    }

    var ipResolver: IPResolver {
        didSet { defaults.set(ipResolver.rawValue, forKey: PreferenceKey.ipResolver) }
    }

    var sshUsername: String {
        didSet { defaults.set(sshUsername, forKey: PreferenceKey.sshUsername) }
    }

    var tartExecutablePath: String {
        didSet { defaults.set(tartExecutablePath, forKey: PreferenceKey.tartExecutablePath) }
    }

    private let defaults: UserDefaults

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaultImageReference =
            defaults.string(forKey: PreferenceKey.defaultImageReference)
            ?? "ghcr.io/cirruslabs/macos-tahoe-base:latest"
        ipResolver =
            defaults.string(forKey: PreferenceKey.ipResolver)
            .flatMap(IPResolver.init(rawValue:)) ?? .dhcp
        sshUsername = defaults.string(forKey: PreferenceKey.sshUsername) ?? "admin"
        tartExecutablePath = defaults.string(forKey: PreferenceKey.tartExecutablePath) ?? ""
    }

    func resetGeneralSettings() {
        defaultImageReference = "ghcr.io/cirruslabs/macos-tahoe-base:latest"
        ipResolver = .dhcp
        sshUsername = "admin"
        tartExecutablePath = ""
    }
}
