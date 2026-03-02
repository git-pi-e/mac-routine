import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var monitor: RoutineMonitor!

    @MainActor
    func applicationDidFinishLaunching(_ notification: Notification) {
        monitor = RoutineMonitor(routines: buildDaemonRoutines())
        setupStatusBar()
        monitor.start()
    }

    @MainActor
    func applicationWillTerminate(_ notification: Notification) {
        monitor.stop()
    }

    @MainActor
    private func setupStatusBar() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "bolt.fill", accessibilityDescription: "MacRoutine")
            button.action = #selector(togglePopover)
            button.target = self
        }
        statusItem = item

        let pop = NSPopover()
        pop.behavior = .transient
        pop.animates = true
        pop.contentViewController = NSHostingController(
            rootView: StatusBarView(monitor: monitor)
        )
        popover = pop
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button else { return }
        if let pop = popover, pop.isShown {
            pop.performClose(nil)
        } else {
            popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}
