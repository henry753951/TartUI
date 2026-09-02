import Foundation

enum DeleteTarget: Identifiable {
    case image(String)
    case virtualMachine(String)

    var id: String {
        switch self {
        case let .image(reference): "image:\(reference)"
        case let .virtualMachine(name): "vm:\(name)"
        }
    }

    var title: String {
        switch self {
        case .image: String(localized: "Delete Image?")
        case .virtualMachine: String(localized: "Delete Virtual Machine?")
        }
    }

    var message: String {
        switch self {
        case let .image(reference): String(localized: "This will remove \(reference) from Tart's OCI cache.")
        case let .virtualMachine(name): String(localized: "This will permanently delete \(name).")
        }
    }
}
