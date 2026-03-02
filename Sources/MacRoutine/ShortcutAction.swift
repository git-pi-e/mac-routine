import Foundation

public struct ShortcutAction: Action {
    public let name: String
    private let shortcutName: String
    private let revertShortcutName: String?

    public init(shortcutName: String, revertShortcutName: String? = nil) {
        self.name = "Shortcut: \(shortcutName)"
        self.shortcutName = shortcutName
        self.revertShortcutName = revertShortcutName
    }

    public func execute() async throws { try await run(shortcutName) }

    public func revert() async throws {
        guard let name = revertShortcutName else { return }
        try await run(name)
    }

    private func run(_ shortcut: String) async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
        process.arguments = ["run", shortcut]
        let errPipe = Pipe()
        process.standardError = errPipe
        try process.run()
        await withCheckedContinuation { c in process.terminationHandler = { _ in c.resume() } }
        if process.terminationStatus != 0 {
            let msg = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            throw ActionError.executionFailed("'\(shortcut)' exited \(process.terminationStatus): \(msg)")
        }
    }
}
