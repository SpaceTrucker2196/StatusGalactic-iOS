import Foundation

/// Tiny shared-defaults shim. The main app writes to this whenever a brief
/// refresh succeeds; the widget and watch complication read from it at
/// timeline time.
///
/// Requires the `group.com.spacetrucker.statusgalactic` App Group entitlement on
/// every target. If the entitlement is missing at runtime (e.g. you haven't
/// set DEVELOPMENT_TEAM yet), `UserDefaults(suiteName:)` returns nil and
/// we fall back to `.standard`. The widget falls back further to the
/// hardcoded `WidgetConfig` values in that case.
enum SharedDefaults {
    static let suiteName = "group.com.spacetrucker.statusgalactic"

    static let store: UserDefaults = {
        UserDefaults(suiteName: suiteName) ?? .standard
    }()

    enum Keys {
        static let lastLat   = "shared.lastLat"
        static let lastLng   = "shared.lastLng"
        static let userAgent = "shared.userAgent"
        static let marineZone = "shared.marineZone"
        static let timezone  = "shared.timezone"
    }

    /// True iff the App Group store is actually shared (i.e. distinct from
    /// `.standard`). Lets widget code decide whether to trust the cached
    /// location or fall back to its hardcoded default.
    static var isShared: Bool {
        UserDefaults(suiteName: suiteName) != nil
    }

    static func writeLocation(lat: Double, lng: Double) {
        store.set(lat, forKey: Keys.lastLat)
        store.set(lng, forKey: Keys.lastLng)
    }

    static func readLocation() -> (lat: Double, lng: Double)? {
        let lat = store.double(forKey: Keys.lastLat)
        let lng = store.double(forKey: Keys.lastLng)
        if lat == 0 && lng == 0 { return nil }
        return (lat, lng)
    }
}
