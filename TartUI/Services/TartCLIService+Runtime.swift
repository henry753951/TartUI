import Foundation

extension TartCLIService {
    func ipAddress(for name: String, resolver: IPResolver, wait: Int) async throws -> String {
        let result = try await run([
            "ip", name,
            "--wait", String(wait),
            "--resolver", resolver.rawValue,
        ])
        let address = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !address.isEmpty else {
            throw TartUIError.invalidResponse("Tart did not return an IP address for \(name).")
        }
        return address
    }

    func guestInformation(for name: String, ipAddress: String?, resolver: IPResolver) async -> VMRuntimeInfo {
        let script = """
            if command -v sw_vers >/dev/null 2>&1; then printf 'OS=%s %s\\n' "$(sw_vers -productName)" "$(sw_vers -productVersion)"; elif test -r /etc/os-release; then . /etc/os-release; printf 'OS=%s\\n' "${PRETTY_NAME:-Linux}"; else printf 'OS=%s\\n' "$(uname -s)"; fi
            printf 'HOSTNAME=%s\\n' "$(hostname)"
            printf 'KERNEL=%s\\n' "$(uname -sr)"
            printf 'ARCH=%s\\n' "$(uname -m)"
            printf 'UPTIME=%s\\n' "$(uptime | sed 's/^[[:space:]]*//')"
            printf 'DISK=%s\\n' "$(df -h / | awk 'NR==2 {print $3 " used of " $2 " (" $5 ")"}')"
            if command -v sysctl >/dev/null 2>&1; then printf 'MEMORY=%s\\n' "$(sysctl -n hw.memsize 2>/dev/null | awk '{printf "%.1f GB", $1/1073741824}')"; elif command -v free >/dev/null 2>&1; then printf 'MEMORY=%s\\n' "$(free -h | awk '/^Mem:/ {print $3 " used of " $2}')"; fi
            printf 'NETWORK_BEGIN\\n'
            ifconfig 2>/dev/null | awk '/^[[:alnum:]][^:]*: flags=/{gsub(":", "", $1); interface=$1} /inet /{print interface ": " $2} /inet6 / && $2 !~ /^fe80/{print interface ": " $2}'
            """

        do {
            let result = try await run(["exec", name, "/bin/sh", "-lc", script])
            var values: [String: String] = [:]
            var networkLines: [String] = []
            var readingNetwork = false
            for line in result.output.components(separatedBy: .newlines) {
                if line == "NETWORK_BEGIN" {
                    readingNetwork = true
                } else if readingNetwork {
                    if !line.isEmpty { networkLines.append(line) }
                } else if let equals = line.firstIndex(of: "=") {
                    values[String(line[..<equals])] = String(line[line.index(after: equals)...])
                }
            }
            return VMRuntimeInfo(
                ipAddress: ipAddress,
                resolver: resolver,
                guestAgentAvailable: true,
                operatingSystem: values["OS"],
                hostname: values["HOSTNAME"],
                kernel: values["KERNEL"],
                architecture: values["ARCH"],
                uptime: values["UPTIME"],
                diskUsage: values["DISK"],
                memoryUsage: values["MEMORY"],
                networkInterfaces: networkLines.isEmpty ? nil : networkLines.joined(separator: "\n")
            )
        } catch {
            return VMRuntimeInfo(
                ipAddress: ipAddress,
                resolver: resolver,
                guestAgentAvailable: false
            )
        }
    }
}
