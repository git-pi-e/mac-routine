import Foundation

public protocol Action: Sendable {
    var name: String { get }
    func execute() async throws
    func revert() async throws
}

public extension Action {
    func revert() async throws {}
}

public enum ActionError: LocalizedError {
    case executionFailed(String)
    case revertFailed(String)

    public var errorDescription: String? {
        switch self {
        case .executionFailed(let r): "Execution failed: \(r)"
        case .revertFailed(let r): "Revert failed: \(r)"
        }
    }
}
