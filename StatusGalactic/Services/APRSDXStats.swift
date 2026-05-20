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
