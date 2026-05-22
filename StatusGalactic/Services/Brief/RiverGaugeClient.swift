import Foundation

/// NOAA NWPS river gauge client.
///
/// Strategy:
///   - The bbox listing endpoint at /v1/gauges?bbox=... silently returns
///     empty results (the bbox parameter shape isn't documented and the
///     candidates I tried all came back with `{ "gauges": [] }`).
///   - The single-gauge endpoint /v1/gauges/{lid} is solid and returns the
///     full status + flood-category structure.
///   - So we find the nearest gauge from a curated catalog of major US
///     river gauges (RiverGaugeCatalog) and pull its details directly.
struct RiverGaugeClient {
    let session: URLSession
    let userAgent: String

    init(session: URLSession = .shared, userAgent: String) {
        self.session = session
        self.userAgent = userAgent
    }

    static let base = "https://api.water.noaa.gov/nwps/v1"

    func fetchNearestGauge(lat: Double, lng: Double) async throws -> RiverGauge? {
        guard let (station, distanceKm) = RiverGaugeCatalog.nearest(toLat: lat, lng: lng)
        else { return nil }

        guard let url = URL(string: "\(Self.base)/gauges/\(station.lid)") else { return nil }
        let data = try await session.getData(from: url, userAgent: userAgent)
        guard let payload = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }

        // Flood-category thresholds. NWPS uses -9999 / -9998 as "no data".
        let flood = payload["flood"] as? [String: Any]
        let categories = flood?["categories"] as? [String: Any] ?? [:]
        func stage(_ key: String) -> Double? {
            guard let entry = categories[key] as? [String: Any] else { return nil }
            let raw = Self.parseDouble(entry["stage"])
            return raw.flatMap { $0 > -9000 ? $0 : nil }
        }

        // Current observed stage + time.
        let status = payload["status"] as? [String: Any]
        let observed = status?["observed"] as? [String: Any]
        let currentStage = Self.parseDouble(observed?["primary"])
            .flatMap { $0 > -9000 ? $0 : nil }
        let observedAt = Self.parseISO((observed?["validTime"] as? String) ?? "")

        // Forecast peak. Frequently a -9999 placeholder when there's no fcst.
        let forecast = status?["forecast"] as? [String: Any]
        let forecastPeak = Self.parseDouble(forecast?["primary"])
            .flatMap { $0 > -9000 ? $0 : nil }
        let forecastPeakAt = Self.parseISO((forecast?["validTime"] as? String) ?? "")

        let serverName = (payload["name"] as? String).flatMap { $0.isEmpty ? nil : $0 }

        let action = stage("action")
        let minor = stage("minor")
        let moderate = stage("moderate")
        let major = stage("major")

        // If we have neither a reading nor any flood thresholds, the
        // gauge card would just show "LID • km away" with no data. Skip
        // surfacing a hollow card.
        guard currentStage != nil || forecastPeak != nil
              || action != nil || minor != nil || moderate != nil || major != nil
        else { return nil }

        return RiverGauge(
            lid: station.lid,
            name: serverName ?? station.name,
            lat: station.lat,
            lng: station.lng,
            distanceKm: distanceKm,
            currentStageFt: currentStage,
            observedAt: observedAt,
            actionStageFt: action,
            minorFloodStageFt: minor,
            moderateFloodStageFt: moderate,
            majorFloodStageFt: major,
            forecastPeakFt: forecastPeak,
            forecastPeakAt: forecastPeakAt
        )
    }

    // MARK: - Helpers

    private static func parseDouble(_ any: Any?) -> Double? {
        if let d = any as? Double { return d }
        if let i = any as? Int { return Double(i) }
        if let n = any as? NSNumber { return n.doubleValue }
        if let s = any as? String { return Double(s) }
        return nil
    }

    private static func parseISO(_ s: String) -> Date? {
        guard !s.isEmpty, !s.hasPrefix("0001-") else { return nil }
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        if let d = f.date(from: s) { return d }
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.date(from: s)
    }
}
