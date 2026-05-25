import Foundation

/// One DX record (longest single received distance over a time period).
struct APRSDXEntry: Hashable {
    let callsign: String
    let distanceKm: Double
    let receivedAt: Date

    var distanceMi: Double { distanceKm * 0.6213711922 }
}

struct APRSDXStats: Hashable {
    let today: APRSDXEntry?
    let month: APRSDXEntry?
    let year: APRSDXEntry?
}

/// Haversine distance between two coordinates on Earth, in kilometers.
/// Accurate to better than 0.5% for points within a few thousand km.
func haversineKm(
    lat1: Double, lng1: Double,
    lat2: Double, lng2: Double
) -> Double {
    let r = 6371.0088 // mean Earth radius in km
    let dLat = (lat2 - lat1) * .pi / 180
    let dLng = (lng2 - lng1) * .pi / 180
    let phi1 = lat1 * .pi / 180
    let phi2 = lat2 * .pi / 180
    let a = sin(dLat / 2) * sin(dLat / 2)
        + sin(dLng / 2) * sin(dLng / 2) * cos(phi1) * cos(phi2)
    let c = 2 * atan2(sqrt(a), sqrt(1 - a))
    return r * c
}

/// Initial great-circle bearing from (lat1, lng1) toward (lat2, lng2),
/// in degrees, 0 = true north, 90 = east. Result is normalized to [0, 360).
func bearingDeg(
    lat1: Double, lng1: Double,
    lat2: Double, lng2: Double
) -> Double {
    let phi1 = lat1 * .pi / 180
    let phi2 = lat2 * .pi / 180
    let dLng = (lng2 - lng1) * .pi / 180
    let y = sin(dLng) * cos(phi2)
    let x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(dLng)
    let theta = atan2(y, x) * 180 / .pi
    return theta.truncatingRemainder(dividingBy: 360) < 0
        ? theta.truncatingRemainder(dividingBy: 360) + 360
        : theta.truncatingRemainder(dividingBy: 360)
}

/// 16-point compass label ("NNE", "ESE", …) for a bearing in degrees.
func compassPoint(forBearing deg: Double) -> String {
    let normalized = deg.truncatingRemainder(dividingBy: 360)
    let b = normalized < 0 ? normalized + 360 : normalized
    let dirs = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
    return dirs[Int((b / 22.5).rounded()) % 16]
}
