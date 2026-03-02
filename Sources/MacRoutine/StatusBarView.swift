import AppKit
import SwiftUI

struct StatusBarView: View {
    let monitor: RoutineMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HeaderView(isRunning: monitor.isRunning, lastEvent: monitor.lastEvent)
            Divider()
            RoutineListView(routines: monitor.routines, activeIDs: monitor.activeRoutineIDs)
            Divider()
            ControlsView(monitor: monitor)
        }
        .padding(16)
        .frame(width: 280)
    }
}

private struct HeaderView: View {
    let isRunning: Bool
    let lastEvent: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isRunning ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash")
                .foregroundStyle(isRunning ? .green : .secondary)
                .symbolEffect(.pulse, isActive: isRunning)
            VStack(alignment: .leading, spacing: 2) {
                Text("MacRoutine").font(.headline)
                Text(lastEvent).font(.caption).foregroundStyle(.secondary).lineLimit(2)
            }
        }
    }
}

private struct RoutineListView: View {
    let routines: [Routine]
    let activeIDs: Set<UUID>

    var body: some View {
        if routines.isEmpty {
            Text("No routines configured. Run  setup  to add one.")
                .font(.caption).foregroundStyle(.secondary)
        } else {
            ForEach(routines) { routine in
                RoutineRow(routine: routine, isActive: activeIDs.contains(routine.id))
            }
        }
    }
}

private struct RoutineRow: View {
    let routine: Routine
    let isActive: Bool

    var body: some View {
        HStack {
            Circle()
                .fill(isActive ? Color.green : Color.secondary.opacity(0.4))
                .frame(width: 8, height: 8)
            Text(routine.name).font(.subheadline)
            Spacer()
            Text(isActive ? "Active" : "Watching")
                .font(.caption2)
                .foregroundStyle(isActive ? .green : .secondary)
        }
    }
}

private struct ControlsView: View {
    let monitor: RoutineMonitor

    var body: some View {
        HStack {
            Button(monitor.isRunning ? "Pause" : "Resume") {
                monitor.isRunning ? monitor.stop() : monitor.start()
            }
            .buttonStyle(.bordered)
            Spacer()
            Button("Quit") { NSApplication.shared.terminate(nil) }
                .buttonStyle(.bordered)
                .foregroundStyle(.red)
        }
    }
}
