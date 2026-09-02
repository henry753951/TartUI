import Foundation

struct SharedDirectoryDraft: Identifiable {
    let id = UUID()
    var name = ""
    var path = ""
    var tag = ""
    var readOnly = false

    init(path: String = "") {
        self.path = path
        if !path.isEmpty {
            name = URL(fileURLWithPath: path).lastPathComponent
        }
    }

    init(argument: String) {
        var location = argument
        if let split = RunAttachmentCodec.recognizedOptions(in: argument, allowingTag: true) {
            location = split.base
            readOnly = split.options.contains("ro")
            tag = split.options.first { $0.hasPrefix("tag=") }.map { String($0.dropFirst(4)) } ?? ""
        }

        if let colon = location.firstIndex(of: ":") {
            let candidateName = String(location[..<colon])
            let candidatePath = String(location[location.index(after: colon)...])
            if !candidateName.contains("/") && (candidatePath.hasPrefix("/") || candidatePath.hasPrefix("~")) {
                name = candidateName
                path = candidatePath
                return
            }
        }
        path = location
    }

    var isValid: Bool {
        !trimmedPath.isEmpty
            && !name.contains(":")
            && !tag.contains(":")
            && !tag.contains(",")
    }

    var argument: String? {
        guard isValid else { return nil }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTag = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        var value = trimmedName.isEmpty ? trimmedPath : "\(trimmedName):\(trimmedPath)"
        var options: [String] = []
        if readOnly { options.append("ro") }
        if !trimmedTag.isEmpty { options.append("tag=\(trimmedTag)") }
        if !options.isEmpty { value += ":" + options.joined(separator: ",") }
        return value
    }

    private var trimmedPath: String {
        path.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct DiskAttachmentDraft: Identifiable {
    let id = UUID()
    var source = ""
    var readOnly = false
    var disableSynchronization = false

    init(source: String = "") {
        self.source = source
    }

    init(argument: String) {
        if let split = RunAttachmentCodec.recognizedOptions(in: argument, allowingTag: false) {
            source = split.base
            readOnly = split.options.contains("ro")
            disableSynchronization = split.options.contains("sync=none")
        } else {
            source = argument
        }
    }

    var isValid: Bool {
        !source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var argument: String? {
        let trimmedSource = source.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSource.isEmpty else { return nil }
        var options: [String] = []
        if readOnly { options.append("ro") }
        if disableSynchronization { options.append("sync=none") }
        return options.isEmpty ? trimmedSource : trimmedSource + ":" + options.joined(separator: ",")
    }
}

enum RunAttachmentCodec {
    static func recognizedOptions(
        in argument: String,
        allowingTag: Bool
    ) -> (base: String, options: [String])? {
        guard let colon = argument.lastIndex(of: ":") else { return nil }
        let suffix = String(argument[argument.index(after: colon)...])
        let options = suffix.split(separator: ",").map(String.init)
        guard !options.isEmpty else { return nil }
        let recognized = options.allSatisfy { option in
            option == "ro"
                || (!allowingTag && option == "sync=none")
                || (allowingTag && option.hasPrefix("tag=") && option.count > 4)
        }
        guard recognized else { return nil }
        return (String(argument[..<colon]), options)
    }
}
