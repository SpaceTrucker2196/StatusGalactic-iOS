import Foundation

/// NOAA SWPC OVATION aurora forecast as a 1°×1° probability grid.
///
/// Endpoint: `/json/ovation_aurora_latest.json`
/// Payload:
/// ```
/// {
///   "Observation Time": "ISO8601",
///   "Forecast Time":    "ISO8601",
///   "coordinates": [ [lon0..360, lat-90..90, probability_pct], ... ]
/// }
/// ```
///
/// `sampleAt(lat:lng:)` returns the value at the nearest grid cell plus
/// the global maximum so the brief can show "Aurora at your spot: 4% /
/// peak elsewhere: 38%".
struct OVATIONClient {
    let session: URLSession
    let userAgent: String

    init(session: URLSession = .shared, userAgent: String) {
        self.session = session
        self.userAgent = userAgent
    }

    static let url = URL(string:
        "https://services.swpc.noaa.gov/json/ovation_aurora_latest.json"
    )!

    func fetch(lat: Double, lng: Double) async throws -> AuroraForecast? {
        let data = try await session.getData(from: Self.url, userAgent: userAgent, timeout: 8)
        guard let payload = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return Self.parse(payload: payload, lat: lat, lng: lng)
    }

    /// Visible for tests.
    static func parse(payload: [String: Any], lat: Double, lng: Double) -> AuroraForecast? {
        guard let coords = payload["coordinates"] as? [[Any]] else { return nil }
        // OVATION longitudes are 0..360°E; viewer is -180..180. Normalize.
        let viewerLon = lng < 0 ? lng + 360 : lng

        var bestDist = Double.infinity
        var bestPct = 0
        var globalMax = 0
        for entry in coords {
            guard entry.count >= 3 else { continue }
            let lon = (entry[0] as? Double) ?? Double((entry[0] as? Int) ?? 0)
            let cellLat = (entry[1] as? Double) ?? Double((entry[1] as? Int) ?? 0)
            let prob = Int((entry[2] as? Double) ?? Double((entry[2] as? Int) ?? 0))
            if prob > globalMax { globalMax = prob }
            // Cheap squared planar distance is fine for 1° grid resolution.
            let dLat = cellLat - lat
            var dLon = lon - viewerLon
            if dLon > 180 { dLon -= 360 } else if dLon < -180 { dLon += 360 }
            let d = dLat * dLat + dLon * dLon
            if d < bestDist {
                bestDist = d
                bestPct = prob
            }
        }
        let parser = ISO8601DateFormatter()
        parser.formatOptions = [.withInternetDateTime]
        let observed = (payload["Observation Time"] as? String).flatMap { parser.date(from: $0) }
        let forecast = (payload["Forecast Time"] as? String).flatMap { parser.date(from: $0) }
        return AuroraForecast(
            observedAt: observed,
            forecastFor: forecast,
            localProbabilityPct: bestPct,
            globalMaxPct: globalMax
        )
    }
}
