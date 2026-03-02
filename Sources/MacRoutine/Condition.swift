import Foundation

public protocol Condition: Sendable {
    var name: String { get }
    func monitor() -> AsyncStream<Bool>
}

public enum ConditionState: Equatable, Sendable {
    case met, notMet
}
