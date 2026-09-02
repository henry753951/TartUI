import Foundation

enum SheetRoute: String, Identifiable {
    case addImage
    case createVM
    case runVM
    case editVM

    var id: String { rawValue }
}

enum DiskImageFormat: String, CaseIterable, Identifiable, Sendable {
    case raw
    case asif

    var id: String { rawValue }
    var title: String { rawValue.uppercased() }
}

struct ImagePullOptions: Sendable {
    var reference = "ghcr.io/cirruslabs/macos-tahoe-base:latest"
    var insecure = false
    var concurrency = 4
}

enum VMCreationMode: String, CaseIterable, Identifiable, Sendable {
    case clone = "Clone"
    case macOS = "macOS IPSW"
    case linux = "Empty Linux"
    case importArchive = "Import .tvm"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .clone: String(localized: "Clone")
        case .macOS: String(localized: "macOS IPSW")
        case .linux: String(localized: "Empty Linux")
        case .importArchive: String(localized: "Import .tvm")
        }
    }
}

struct VMCreateOptions: Sendable {
    var mode: VMCreationMode = .clone
    var name = ""
    var source = ""
    var diskGB = 50
    var diskFormat: DiskImageFormat = .raw
    var insecure = false
    var concurrency = 4
    var pruneLimitGB = 100
    var ipswSource = "latest"
    var archivePath = ""
}

enum RunPresentation: String, CaseIterable, Identifiable, Codable, Sendable {
    case graphics = "Window"
    case headless = "Headless"
    case vnc = "Screen Sharing"
    case vncExperimental = "Experimental VNC"
    case serial = "Serial Console"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .graphics: String(localized: "Window")
        case .headless: String(localized: "Headless")
        case .vnc: String(localized: "Screen Sharing")
        case .vncExperimental: String(localized: "Experimental VNC")
        case .serial: String(localized: "Serial Console")
        }
    }
}

enum RunNetworkMode: String, CaseIterable, Identifiable, Codable, Sendable {
    case shared = "Shared (NAT)"
    case bridged = "Bridged"
    case softnet = "Softnet"
    case hostOnly = "Host Only"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .shared: String(localized: "Shared (NAT)")
        case .bridged: String(localized: "Bridged")
        case .softnet: "Softnet"
        case .hostOnly: String(localized: "Host Only")
        }
    }
}

enum RootDiskCaching: String, CaseIterable, Identifiable, Codable, Sendable {
    case automatic
    case cached
    case uncached

    var id: String { rawValue }
    var title: String {
        switch self {
        case .automatic: String(localized: "Automatic")
        case .cached: String(localized: "Cached")
        case .uncached: String(localized: "Uncached")
        }
    }
}

enum RootDiskSync: String, CaseIterable, Identifiable, Codable, Sendable {
    case none
    case fsync
    case full

    var id: String { rawValue }
    var title: String {
        switch self {
        case .none: String(localized: "None")
        case .fsync: "fsync"
        case .full: String(localized: "Full")
        }
    }
}

struct RunOptions: Codable, Sendable {
    var presentation: RunPresentation = .graphics
    var networkMode: RunNetworkMode = .shared
    var bridgedInterface = ""
    var softnetAllow = ""
    var softnetBlock = ""
    var softnetExpose = ""
    var noAudio = false
    var noClipboard = false
    var recovery = false
    var nested = false
    var suspendable = false
    var captureSystemKeys = false
    var noTrackpad = false
    var noPointer = false
    var noKeyboard = false
    var rosettaTag = ""
    var serialPath = ""
    var rootDiskReadOnly = false
    var rootDiskCaching: RootDiskCaching = .automatic
    var rootDiskSync: RootDiskSync = .full
    var directoryShares = ""
    var additionalDisks = ""

    var directoryShareArguments: [String] { nonEmptyLines(directoryShares) }
    var additionalDiskArguments: [String] { nonEmptyLines(additionalDisks) }

    private func nonEmptyLines(_ text: String) -> [String] {
        text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

enum IPResolver: String, CaseIterable, Identifiable, Sendable {
    case dhcp
    case arp
    case agent

    var id: String { rawValue }
    var title: String { rawValue.uppercased() }
}

struct VMEditOptions: Sendable {
    var originalName = ""
    var name = ""
    var cpu = 4
    var memoryMB = 4096
    var displayWidth = 1024
    var displayHeight = 768
    var displayUnit = "pt"
    var displayRefit = true
    var diskGB = 50
    var replacementDiskPath = ""
    var randomMAC = false
    var randomSerial = false

    var displayArgument: String {
        "\(displayWidth)x\(displayHeight)\(displayUnit)"
    }
}
