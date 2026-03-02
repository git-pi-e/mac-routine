import CoreLocation
import Foundation

public struct LocationCondition: Condition {
    public let name: String
    private let latitude: Double
    private let longitude: Double
    private let radiusMeters: Double

    public init(name: String, latitude: Double, longitude: Double, radiusMeters: Double = 100) {
        self.name = "Location: \(name) (\(Int(radiusMeters))m)"
        self.latitude = latitude
        self.longitude = longitude
        self.radiusMeters = radiusMeters
    }

    public func monitor() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            let delegate = LocationDelegate(
                target: CLLocation(latitude: latitude, longitude: longitude),
                radius: radiusMeters,
                continuation: continuation
            )
            continuation.onTermination = { _ in delegate.stop() }
            delegate.start()
        }
    }
}

private final class LocationDelegate: NSObject, CLLocationManagerDelegate, @unchecked Sendable {
    private let manager = CLLocationManager()
    private let target: CLLocation
    private let radius: Double
    private let continuation: AsyncStream<Bool>.Continuation
    private var lastState: Bool?

    init(target: CLLocation, radius: Double, continuation: AsyncStream<Bool>.Continuation) {
        self.target = target
        self.radius = radius
        self.continuation = continuation
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }

    func start() {
        manager.requestAlwaysAuthorization()
        manager.startUpdatingLocation()
    }

    func stop() {
        manager.stopUpdatingLocation()
        continuation.finish()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let current = locations.last else { return }
        let matched = current.distance(from: target) <= radius
        if matched != lastState { continuation.yield(matched); lastState = matched }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if lastState != false { continuation.yield(false); lastState = false }
    }
}
