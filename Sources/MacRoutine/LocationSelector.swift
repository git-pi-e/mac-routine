import Foundation

struct LocationSelector {
    struct Place {
        let displayName: String
        let latitude: Double
        let longitude: Double
    }

    private struct NominatimResult: Codable {
        let display_name: String
        let lat: String
        let lon: String
    }

    static func run() -> LocationConfig? {
        T.section("Location Condition  (optional)")
        T.info("Require device to be within a radius of a place.")
        let skip = T.prompt("Add location condition? y/n", default: "n")
        guard skip.lowercased() == "y" else { return nil }

        var places: [Place] = []
        repeat {
            let query = T.prompt("Search location")
            guard !query.isEmpty else { T.warn("Query cannot be empty."); continue }
            places = search(query: query)
            if places.isEmpty { T.warn("No results found. Try a different query.") }
        } while places.isEmpty

        T.out("")
        let selectedIndices = T.multiSelect(
            title: "Select Location",
            items: places,
            display: { $0.displayName }
        )
        guard let idx = selectedIndices.first else {
            T.warn("No location selected — skipping.")
            return nil
        }
        let place = places[idx]

        let radiusStr = T.prompt("Radius in meters", default: "150")
        let radius = Double(radiusStr) ?? 150

        T.success("\(place.displayName) within \(Int(radius))m")
        return LocationConfig(
            displayName: place.displayName,
            latitude: place.latitude,
            longitude: place.longitude,
            radiusMeters: radius
        )
    }

    private static func search(query: String) -> [Place] {
        var results: [Place] = []
        T.spinner(label: "Searching…") {
            guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let url = URL(string: "https://nominatim.openstreetmap.org/search?q=\(encoded)&format=json&limit=6")
            else { return }

            var request = URLRequest(url: url)
            request.setValue("MacRoutine/1.0 (github.com/local/macroutine)", forHTTPHeaderField: "User-Agent")
            request.timeoutInterval = 10

            let sema = DispatchSemaphore(value: 0)
            URLSession.shared.dataTask(with: request) { data, _, _ in
                defer { sema.signal() }
                guard let data,
                      let raw = try? JSONDecoder().decode([NominatimResult].self, from: data)
                else { return }
                results = raw.compactMap { r in
                    guard let lat = Double(r.lat), let lon = Double(r.lon) else { return nil }
                    return Place(displayName: r.display_name, latitude: lat, longitude: lon)
                }
            }.resume()
            sema.wait()
        }
        return results
    }
}
