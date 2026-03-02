import Foundation

actor ConditionStateTracker {
    private var states: [Int: Bool] = [:]
    private let conditionCount: Int

    init(conditionCount: Int) {
        self.conditionCount = conditionCount
    }

    func update(index: Int, matched: Bool) -> Bool {
        states[index] = matched
        return states.count == conditionCount && states.values.allSatisfy { $0 }
    }
}
