import Foundation

struct LicenseDocument: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let owner: String
    let licenseName: String
    let rawLicenseURL: URL
    let projectURL: URL

    static let included: [LicenseDocument] = [
        LicenseDocument(
            id: "tartui",
            name: "TartUI",
            owner: "Henry753951",
            licenseName: "MIT License",
            rawLicenseURL: URL(string: "https://raw.githubusercontent.com/henry753951/TartUI/main/LICENSE")!,
            projectURL: URL(string: "https://github.com/henry753951/TartUI")!
        ),
        LicenseDocument(
            id: "tart",
            name: "Tart",
            owner: "OpenAI",
            licenseName: "FSL-1.1-ALv2",
            rawLicenseURL: URL(string: "https://raw.githubusercontent.com/openai/tart/main/LICENSE")!,
            projectURL: URL(string: "https://github.com/openai/tart")!
        ),
        LicenseDocument(
            id: "tart-guest-agent",
            name: "tart-guest-agent",
            owner: "Cirrus Labs",
            licenseName: "FSL-1.1-Apache-2.0",
            rawLicenseURL: URL(string: "https://raw.githubusercontent.com/cirruslabs/tart-guest-agent/main/LICENSE")!,
            projectURL: URL(string: "https://github.com/cirruslabs/tart-guest-agent")!
        ),
        LicenseDocument(
            id: "sparkle",
            name: "Sparkle",
            owner: "Sparkle contributors",
            licenseName: "MIT License",
            rawLicenseURL: URL(string: "https://raw.githubusercontent.com/sparkle-project/Sparkle/2.x/LICENSE")!,
            projectURL: URL(string: "https://github.com/sparkle-project/Sparkle")!
        ),
    ]
}
