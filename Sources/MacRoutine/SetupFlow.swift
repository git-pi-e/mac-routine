import Foundation
import Darwin

func shell(_ cmd: String) -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/zsh")
    process.arguments = ["-c", cmd]
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = Pipe()
    try? process.run()
    process.waitUntilExit()
    return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
}

struct ShortcutSelector {
    static func run(prompt: String, required: Bool = true) -> String? {
        var shortcuts: [String] = []
        T.spinner(label: "Loading Shortcuts…") {
            let output = shell("shortcuts list 2>/dev/null")
            shortcuts = output.components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        }

        if shortcuts.isEmpty {
            T.warn("Could not list Shortcuts. Type the name manually.")
            let manual = T.prompt(prompt)
            return manual.isEmpty ? nil : manual
        }

        let note = required ? "" : "  ·  \(T.dim)Enter with none selected to skip\(T.reset)"
        T.label("\(prompt)\(note)")

        let selected = T.multiSelect(
            title: prompt,
            items: shortcuts,
            display: { $0 }
        )

        if let idx = selected.first {
            return shortcuts[idx]
        }
        if !required { return nil }
        let manual = T.prompt("Or type Shortcut name manually")
        return manual.isEmpty ? nil : manual
    }
}

struct SetupFlow {
    func run() {
        T.out("")
        T.box(title: "MacRoutine Setup", width: 54)
        T.out("")
        T.out("  Configure trigger conditions and automated actions.")
        T.out("  Settings saved to \(T.dim)~/.config/macroutine/config.json\(T.reset)")
        T.out("")

        let name = promptRoutineName()
        let ssids = WifiSelector.run()
        let location = LocationSelector.run()
        let (shortcut, revert) = shortcutStep()
        let reverts = revertToggle(has: revert != nil)

        let config = RoutineConfig(
            name: name,
            wifiSSIDs: ssids,
            location: location,
            shortcutName: shortcut,
            revertShortcutName: revert,
            revertsOnExit: reverts
        )

        saveConfig(config)
        printSummary(config)
    }

    private func promptRoutineName() -> String {
        T.section("Routine")
        var name = T.prompt("Routine name", default: "Workplace Routine")
        if name.isEmpty { name = "Workplace Routine" }
        return name
    }

    private func shortcutStep() -> (String, String?) {
        T.section("Action — macOS Shortcut")
        T.info("Runs when conditions are met.")
        let main = ShortcutSelector.run(prompt: "Trigger Shortcut", required: true) ?? "Workplace Routine"

        T.out("")
        T.info("Runs when you leave (optional revert Shortcut).")
        let revert = ShortcutSelector.run(prompt: "Revert Shortcut", required: false)
        return (main, revert)
    }

    private func revertToggle(has: Bool) -> Bool {
        guard has else { return false }
        let answer = T.prompt("Auto-revert when conditions stop? y/n", default: "y")
        return answer.lowercased() != "n"
    }

    private func saveConfig(_ config: RoutineConfig) {
        var app = AppConfig.load()
        if let idx = app.routines.firstIndex(where: { $0.name == config.name }) {
            app.routines[idx] = config
        } else {
            app.routines.append(config)
        }
        do {
            try app.save()
        } catch {
            T.warn("Could not save config: \(error.localizedDescription)")
        }
    }

    private func printSummary(_ config: RoutineConfig) {
        T.out("")
        T.box(title: "Routine Saved", width: 54)
        T.out("")
        T.success("\(T.bold)\(config.name)\(T.reset)")
        T.info("Wi-Fi:     \(config.wifiSSIDs.joined(separator: "  or  "))")
        if let loc = config.location {
            T.info("Location:  \(loc.displayName) (\(Int(loc.radiusMeters))m)")
        }
        T.info("Shortcut:  \(config.shortcutName)")
        if let r = config.revertShortcutName { T.info("Revert:    \(r)") }
        T.info("Auto-revert: \(config.revertsOnExit ? "yes" : "no")")
        T.out("")
        T.out("  \(T.dim)Run \(T.reset)\(T.bold)MacRoutine\(T.reset)\(T.dim) (no args) to start the menu bar daemon.\(T.reset)")
        T.out("")
    }
}
