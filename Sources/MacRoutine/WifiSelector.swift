import CoreWLAN
import Foundation

struct WifiSelector {
    struct Option: Equatable {
        let ssid: String
        let isKnown: Bool
    }

    static func run() -> [String] {
        T.section("Wi-Fi Conditions")
        T.info("These networks will trigger the routine (OR logic — any one matches)")

        var networks = fetchKnownNetworks()

        T.label("Select networks · or press  n  to add a custom SSID")
        var selectedIndices = T.multiSelect(
            title: "Wi-Fi Networks",
            items: networks,
            display: { $0.isKnown ? "\($0.ssid)  \(T.dim)(known)\(T.reset)" : $0.ssid }
        )

        var shouldLoop = true
        while shouldLoop {
            T.out("")
            T.out("  \(T.dim)a\(T.reset) Add custom SSID  ·  \(T.dim)Enter\(T.reset) Done with selection", terminator: "")
            let key = readLineKey()
            if key == "a" || key == "n" {
                let ssid = T.prompt("Custom SSID")
                if !ssid.isEmpty {
                    let opt = Option(ssid: ssid, isKnown: false)
                    if !networks.contains(opt) { networks.append(opt) }
                    let idx = networks.firstIndex(of: opt)!
                    selectedIndices.insert(idx)
                    T.success("Added \(T.bold)\(ssid)\(T.reset)")
                }
            } else {
                shouldLoop = false
            }
        }

        let result = selectedIndices.map { networks[$0].ssid }
        if result.isEmpty {
            T.warn("No networks selected — routine will never trigger.")
        } else {
            T.success("Selected: \(result.map { "\"\($0)\"" }.joined(separator: ", "))")
        }
        return result
    }

    private static func readLineKey() -> String {
        T.rawMode(true)
        defer { T.rawMode(false) }
        var c: UInt8 = 0
        read(STDIN_FILENO, &c, 1)
        T.out("")
        return String(Character(UnicodeScalar(c)))
    }

    private static func fetchKnownNetworks() -> [Option] {
        var result: [Option] = []
        T.spinner(label: "Fetching known Wi-Fi networks…") {
            let interfaceName = CWWiFiClient.shared().interface()?.interfaceName ?? "en0"
            let output = shell("/usr/sbin/networksetup -listpreferredwirelessnetworks \(interfaceName)")
            let lines = output
                .components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty && !$0.lowercased().hasPrefix("preferred") }
            result = lines.map { Option(ssid: $0, isKnown: true) }
        }
        if result.isEmpty {
            T.warn("Could not fetch known networks. Add SSIDs manually.")
        }
        return result
    }
}
