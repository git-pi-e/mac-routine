import CoreWLAN
import Foundation

public struct WiFiCondition: Condition {
    public let name: String
    private let targetSSIDs: Set<String>
    private let pollInterval: Duration

    public init(ssids: Set<String>, pollInterval: Duration = .seconds(10)) {
        self.name = "Wi-Fi: \(ssids.sorted().joined(separator: " or "))"
        self.targetSSIDs = ssids
        self.pollInterval = pollInterval
    }

    public func monitor() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            let task = Task {
                var lastState: Bool?
                while !Task.isCancelled {
                    let matched = WiFiCondition.currentSSID().map { targetSSIDs.contains($0) } ?? false
                    if matched != lastState {
                        continuation.yield(matched)
                        lastState = matched
                    }
                    try? await Task.sleep(for: pollInterval)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private static func currentSSID() -> String? {
        CWWiFiClient.shared().interface()?.ssid()
    }
}
