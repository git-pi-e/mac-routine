import Foundation

func buildDaemonRoutines() -> [Routine] {
    AppConfig.load().routines.map { cfg in
        var conditions: [any Condition] = [
            WiFiCondition(ssids: Set(cfg.wifiSSIDs))
        ]
        if let loc = cfg.location {
            conditions.append(LocationCondition(
                name: loc.displayName,
                latitude: loc.latitude,
                longitude: loc.longitude,
                radiusMeters: loc.radiusMeters
            ))
        }
        return Routine(
            name: cfg.name,
            conditions: conditions,
            actions: [ShortcutAction(
                shortcutName: cfg.shortcutName,
                revertShortcutName: cfg.revertShortcutName
            )],
            revertsOnExit: cfg.revertsOnExit
        )
    }
}
