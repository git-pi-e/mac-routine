import Foundation

struct RoutineConfig: Codable {
    var name: String
    var wifiSSIDs: [String]
    var location: LocationConfig?
    var shortcutName: String
    var revertShortcutName: String?
    var revertsOnExit: Bool
}

struct LocationConfig: Codable {
    var displayName: String
    var latitude: Double
    var longitude: Double
    var radiusMeters: Double
}

struct AppConfig: Codable {
    var routines: [RoutineConfig]

    static var configURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/macroutine/config.json")
    }

    static func load() -> AppConfig {
        guard let data = try? Data(contentsOf: configURL),
              let config = try? JSONDecoder().decode(AppConfig.self, from: data)
        else { return AppConfig(routines: []) }
        return config
    }

    func save() throws {
        let dir = AppConfig.configURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(self).write(to: AppConfig.configURL)
    }
}
