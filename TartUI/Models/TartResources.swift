import Foundation

enum AppSection: String, CaseIterable, Identifiable {
    case images
    case virtualMachines

    var id: String { rawValue }

    var title: String {
        switch self {
        case .images: String(localized: "Images")
        case .virtualMachines: String(localized: "Virtual Machines")
        }
    }

    var systemImage: String {
        switch self {
        case .images: "square.stack.3d.up"
        case .virtualMachines: "macwindow"
        }
    }
}

struct TartListRecord: Decodable, Sendable {
    let name: String
    let source: String
    let disk: Int
    let size: Int
    let running: Bool
    let state: String
    let accessed: String?

    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case source = "Source"
        case disk = "Disk"
        case size = "Size"
        case running = "Running"
        case state = "State"
        case accessed = "Accessed"
    }
}

struct TartImage: Identifiable, Hashable, Sendable {
    let reference: String
    let diskGB: Int
    let sizeGB: Int
    let accessed: String?

    var id: String { reference }

    var title: String {
        let component = reference.split(separator: "/").last.map(String.init) ?? reference
        return component.split(separator: "@", maxSplits: 1).first.map(String.init) ?? component
    }

    var registry: String {
        reference.split(separator: "/").first.map(String.init) ?? reference
    }

    var repository: String {
        let withoutDigest = reference.split(separator: "@", maxSplits: 1).first.map(String.init) ?? reference
        guard let slash = withoutDigest.firstIndex(of: "/") else { return withoutDigest }
        let remainder = withoutDigest[withoutDigest.index(after: slash)...]
        if let colon = remainder.lastIndex(of: ":") {
            return String(remainder[..<colon])
        }
        return String(remainder)
    }

    var version: String {
        if let digestRange = reference.range(of: "@sha256:") {
            return "sha256:" + reference[digestRange.upperBound...].prefix(12)
        }
        let lastSlash = reference.lastIndex(of: "/")
        if let colon = reference.lastIndex(of: ":"), lastSlash == nil || colon > lastSlash! {
            return String(reference[reference.index(after: colon)...])
        }
        return "latest"
    }

    var repositoryWithoutReference: String {
        let withoutDigest = reference.split(separator: "@", maxSplits: 1).first.map(String.init) ?? reference
        let lastSlash = withoutDigest.lastIndex(of: "/")
        if let colon = withoutDigest.lastIndex(of: ":"), lastSlash == nil || colon > lastSlash! {
            return String(withoutDigest[..<colon])
        }
        return withoutDigest
    }

    var isDigestReference: Bool { reference.contains("@sha256:") }
}

struct TartVirtualMachine: Identifiable, Hashable, Sendable {
    let name: String
    let diskGB: Int
    let sizeGB: Int
    let running: Bool
    let rawState: String
    let accessed: String?

    var id: String { name }

    var state: VMState {
        if running { return .running }
        if rawState.caseInsensitiveCompare("suspended") == .orderedSame { return .suspended }
        return .stopped
    }
}

enum VMState: String, Sendable {
    case running = "Running"
    case stopped = "Stopped"
    case suspended = "Suspended"

    var title: String {
        switch self {
        case .running: String(localized: "Running")
        case .stopped: String(localized: "Stopped")
        case .suspended: String(localized: "Suspended")
        }
    }

    var symbol: String {
        switch self {
        case .running: "play.fill"
        case .stopped: "stop.fill"
        case .suspended: "pause.fill"
        }
    }
}

struct TartVMDetails: Decodable, Hashable, Sendable {
    let os: String
    let memory: Int
    let disk: Int
    let display: String
    let cpu: Int
    let diskFormat: String?
    let size: String

    enum CodingKeys: String, CodingKey {
        case os = "OS"
        case memory = "Memory"
        case disk = "Disk"
        case display = "Display"
        case cpu = "CPU"
        case diskFormat = "DiskFormat"
        case size = "Size"
    }

    var osName: String {
        switch os.lowercased() {
        case "darwin": "macOS"
        case "linux": "Linux"
        default: os.capitalized
        }
    }

    var memoryText: String {
        if memory >= 1024, memory.isMultiple(of: 1024) { return "\(memory / 1024) GB" }
        return "\(memory) MB"
    }
}

struct CommandResult: Sendable {
    let output: String
    let exitCode: Int32
}
