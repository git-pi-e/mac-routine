import Foundation
import Observation

@MainActor
@Observable
public final class RoutineMonitor {
    public private(set) var activeRoutineIDs: Set<UUID> = []
    public private(set) var lastEvent: String = "Idle"
    public private(set) var isRunning: Bool = false

    public var routines: [Routine] { didSet { restart() } }

    private var monitoringTasks: [UUID: Task<Void, Never>] = [:]

    public init(routines: [Routine] = []) {
        self.routines = routines
    }

    public func start() {
        guard !isRunning else { return }
        isRunning = true
        routines.forEach { startMonitoring(routine: $0) }
    }

    public func stop() {
        isRunning = false
        monitoringTasks.values.forEach { $0.cancel() }
        monitoringTasks.removeAll()
        activeRoutineIDs.removeAll()
    }

    private func restart() {
        let was = isRunning; stop(); if was { start() }
    }

    private func startMonitoring(routine: Routine) {
        let task = Task { [weak self] in
            guard let self else { return }
            await self.runMonitorLoop(for: routine)
        }
        monitoringTasks[routine.id] = task
    }

    private func runMonitorLoop(for routine: Routine) async {
        guard !routine.conditions.isEmpty else { return }
        let tracker = ConditionStateTracker(conditionCount: routine.conditions.count)
        await withTaskGroup(of: Void.self) { group in
            for (index, condition) in routine.conditions.enumerated() {
                group.addTask {
                    for await matched in condition.monitor() {
                        let allMet = await tracker.update(index: index, matched: matched)
                        await self.applyState(allMet: allMet, routine: routine)
                        if Task.isCancelled { break }
                    }
                }
            }
            await group.waitForAll()
        }
    }

    private func applyState(allMet: Bool, routine: Routine) async {
        let wasActive = activeRoutineIDs.contains(routine.id)
        if allMet && !wasActive { await fire(routine: routine, executing: true) }
        else if !allMet && wasActive { await fire(routine: routine, executing: false) }
    }

    private func fire(routine: Routine, executing: Bool) async {
        if executing {
            activeRoutineIDs.insert(routine.id)
            lastEvent = "▶ \(routine.name)"
        } else {
            activeRoutineIDs.remove(routine.id)
            lastEvent = "↩ \(routine.name)"
        }
        for action in routine.actions {
            do {
                if executing { try await action.execute() }
                else if routine.revertsOnExit { try await action.revert() }
            } catch {
                lastEvent = "⚠ \(action.name): \(error.localizedDescription)"
            }
        }
    }
}
