import Foundation

struct LocalVMConfiguration: Decodable, Sendable {
    let os: String
    let arch: String
    let cpuCount: Int
    let cpuCountMin: Int?
    let memorySize: UInt64
    let memorySizeMin: UInt64?
    let macAddress: String
    let diskFormat: String?
    let display: Display
    let displayRefit: Bool?

    struct Display: Decodable, Sendable {
        let width: Int
        let height: Int
        let unit: String?
    }

    var memoryMB: Int { Int(memorySize / 1_048_576) }
}

struct VMHostInfo: Sendable {
    let directory: URL
    let allocatedBytes: Int64

    var allocatedText: String {
        ByteCountFormatter.string(fromByteCount: allocatedBytes, countStyle: .file)
    }
}

struct VMRuntimeInfo: Sendable {
    var ipAddress: String?
    var resolver: IPResolver
    var guestAgentAvailable: Bool
    var operatingSystem: String?
    var hostname: String?
    var kernel: String?
    var architecture: String?
    var uptime: String?
    var diskUsage: String?
    var memoryUsage: String?
    var networkInterfaces: String?
    var refreshedAt: Date = .now
}

enum TartUIError: LocalizedError {
    case tartNotInstalled
    case commandFailed(arguments: [String], exitCode: Int32, output: String)
    case invalidResponse(String)

    var errorDescription: String? {
        switch self {
        case .tartNotInstalled:
            "Tart is not installed at /opt/homebrew/bin/tart or /usr/local/bin/tart."
        case let .commandFailed(arguments, exitCode, output):
            "tart \(arguments.joined(separator: " ")) failed (\(exitCode)).\n\(output)"
        case let .invalidResponse(message):
            message
        }
    }
}
