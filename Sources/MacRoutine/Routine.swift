import Foundation

public struct Routine: Identifiable, Sendable {
    public let id: UUID
    public let name: String
    public let conditions: [any Condition]
    public let actions: [any Action]
    public let revertsOnExit: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        conditions: [any Condition],
        actions: [any Action],
        revertsOnExit: Bool = true
    ) {
        self.id = id
        self.name = name
        self.conditions = conditions
        self.actions = actions
        self.revertsOnExit = revertsOnExit
    }
}
