import Foundation

public struct ShellAction: Action {
    public let name: String
    private let command: String
    private let revertCommand: String?

    public init(name: String, command: String, revertCommand: String? = nil) {
        self.name = name
        self.command = command
        self.revertCommand = revertCommand
    }

    public func execute() async throws { try await run(command) }

    public func revert() async throws {
        guard let cmd = revertCommand else { return }
        try await run(cmd)
    }

    private func run(_ cmd: String) async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", cmd]
        let errPipe = Pipe()
        process.standardError = errPipe
        try process.run()
        await withCheckedContinuation { c in process.terminationHandler = { _ in c.resume() } }
        if process.terminationStatus != 0 {
            let msg = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            throw ActionError.executionFailed("'\(cmd)' exited \(process.terminationStatus): \(msg)")
        }
    }
}
