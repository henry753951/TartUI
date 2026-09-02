import Foundation

extension TartCLIService {
    func runArguments(name: String, options: RunOptions) -> [String] {
        var arguments = ["run"]
        switch options.presentation {
        case .graphics:
            break
        case .headless:
            arguments.append("--no-graphics")
        case .vnc:
            arguments.append("--vnc")
        case .vncExperimental:
            arguments.append("--vnc-experimental")
        case .serial:
            if options.serialPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                arguments.append("--serial")
            } else {
                arguments += ["--serial-path", options.serialPath]
            }
        }

        if options.noAudio { arguments.append("--no-audio") }
        if options.noClipboard { arguments.append("--no-clipboard") }
        if options.recovery { arguments.append("--recovery") }
        if options.nested { arguments.append("--nested") }
        if options.suspendable { arguments.append("--suspendable") }
        if options.captureSystemKeys { arguments.append("--capture-system-keys") }
        if options.noTrackpad { arguments.append("--no-trackpad") }
        if options.noPointer { arguments.append("--no-pointer") }
        if options.noKeyboard { arguments.append("--no-keyboard") }

        let rosetta = options.rosettaTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !rosetta.isEmpty { arguments += ["--rosetta", rosetta] }

        switch options.networkMode {
        case .shared:
            break
        case .bridged:
            let interface = options.bridgedInterface.trimmingCharacters(in: .whitespacesAndNewlines)
            if !interface.isEmpty { arguments += ["--net-bridged", interface] }
        case .softnet:
            arguments.append("--net-softnet")
            let allow = options.softnetAllow.trimmingCharacters(in: .whitespacesAndNewlines)
            let block = options.softnetBlock.trimmingCharacters(in: .whitespacesAndNewlines)
            let expose = options.softnetExpose.trimmingCharacters(in: .whitespacesAndNewlines)
            if !allow.isEmpty { arguments += ["--net-softnet-allow", allow] }
            if !block.isEmpty { arguments += ["--net-softnet-block", block] }
            if !expose.isEmpty { arguments += ["--net-softnet-expose", expose] }
        case .hostOnly:
            arguments.append("--net-host")
        }

        for share in options.directoryShareArguments { arguments += ["--dir", share] }
        for disk in options.additionalDiskArguments { arguments += ["--disk", disk] }

        var rootOptions = [
            "caching=\(options.rootDiskCaching.rawValue)",
            "sync=\(options.rootDiskSync.rawValue)",
        ]
        if options.rootDiskReadOnly { rootOptions.insert("ro", at: 0) }
        arguments += ["--root-disk-opts", rootOptions.joined(separator: ",")]
        arguments.append(name)
        return arguments
    }
}
