import Foundation

/// NOAA National Water Prediction Service (NWPS) river gauge client.
///
/// Returns the nearest river gauge to a location (within a configurable
/// bounding box, default ~55 km square) with its current stage, observation
/// time, and the four flood-stage thresholds (action / minor / moderate /
/// major). Free, no auth, just User-Agent.
struct RiverGaugeClient {
    let session: URLSession
    let userAgent: String

    init(session: URLSession = .shared, userAgent: String) {
        self.session = session
        self.userAgent = userAgent
    }

    static let base = "https://api.water.noaa.gov/nwps/v1"

    /// Find a nearby gauge that has flood-stage data, then pull its current
    /// stage. nil if no gauge is close enough or has usable thresholds.
    func fetchNearestGauge(
        lat: Double,
        lng: Double,
        searchHalfDegrees: Double = 0.35   // ~55 km square box
    ) async throws -> RiverGauge? {
        let bbox = "\(lng - searchHalfDegrees),\(lat - searchHalfDegrees),\(lng + searchHalfDegrees),\(lat + searchHalfDegrees)"
        guard let listURL = URL(string: "\(Self.base)/gauges?bbox=\(bbox)") else { return nil }
        let listData = try await session.getData(from: listURL, userAgent: userAgent)
        let listPayload = try JSONSerialization.jsonObject(with: listData)

        let candidates = Self.parseGaugeList(listPayload, observerLat: lat, observerLng: lng)
        guard let chosen = candidates.first else { return nil }

        // Pull stageflow only for the closest candidate that has thresholds.
        guard let stageURL = URL(string: "\(Self.base)/gauges/\(chosen.lid)/stageflow") else {
            return chosen.withStage(from: [String: Any]())
        }
        let stageData = (try? await session.getData(from: stageURL, userAgent: userAgent)) ?? Data()
        let stagePayload = (try? JSONSerialization.jsonObject(with: stageData)) ?? [String: Any]()
        return chosen.withStage(from: stagePayload)
    }

    // MARK: - Parsing

    private struct PendingGauge {
        let lid: String
        let name: String
        let lat: Double
        let lng: Double
        let distanceKm: Double
        let action: Double?
        let minor: Double?
        let moderate: Double?
        let major: Double?

        func withStage(from payload: Any) -> RiverGauge {
            var currentStage: Double?
            var observedAt: Date?
            var forecastPeak: Double?
            var forecastPeakAt: Date?

            if let dict = payload as? [String: Any] {
                if let observed = dict["observed"] as? [String: Any],
                   let data = observed["data"] as? [[String: Any]],
                   let last = data.last {
                    currentStage = Self.parseDouble(last["primary"])
                    observedAt = Self.parseDate(last["validTime"])
                }
                if let forecast = dict["forecast"] as? [String: Any],
                   let data = forecast["data"] as? [[String: Any]] {
                    var maxV: Double = -.infinity
                    var maxAt: Date?
                    for entry in data {
                        if let v = Self.parseDouble(entry["primary"]), v > maxV {
                            maxV = v
                            maxAt = Self.parseDate(entry["validTime"])
                        }
                    }
                    if maxV.isFinite {
                        forecastPeak = maxV
                        forecastPeakAt = maxAt
                    }
                }
            }

            return RiverGauge(
                lid: lid,
                name: name,
                lat: lat,
                lng: lng,
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

        fileprivate static func parseDouble(_ any: Any?) -> Double? {
            if let d = any as? Double { return d }
            if let i = any as? Int { return Double(i) }
            if let s = any as? String { return Double(s) }
            return nil
        }
        fileprivate static func parseDate(_ any: Any?) -> Date? {
            guard let s = any as? String else { return nil }
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime]
            if let d = f.date(from: s) { return d }
            f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return f.date(from: s)
        }
    }

    private static func parseGaugeList(
        _ payload: Any,
        observerLat: Double,
        observerLng: Double
    ) -> [PendingGauge] {
        let envelope = payload as? [String: Any] ?? [:]
        let gauges = (envelope["gauges"] as? [[String: Any]]) ?? []

        var results: [PendingGauge] = []
        for g in gauges {
            guard
                let lid = (g["lid"] as? String)?.uppercased(),
                let lat = (g["latitude"] as? Double) ?? (g["latitude"] as? NSNumber)?.doubleValue,
                let lng = (g["longitude"] as? Double) ?? (g["longitude"] as? NSNumber)?.doubleValue
            else { continue }
            let name = (g["name"] as? String) ?? lid
            let thresholds = extractThresholds(from: g)
            // Require at least an action stage; gauges without thresholds
            // aren't useful for the "is the river flooding?" question.
            guard thresholds.action != nil
                || thresholds.minor != nil
                || thresholds.moderate != nil
                || thresholds.major != nil
            else { continue }
            let d = haversineKm(lat1: observerLat, lng1: observerLng, lat2: lat, lng2: lng)
            results.append(PendingGauge(
                lid: lid,
                name: name,
                lat: lat,
                lng: lng,
                distanceKm: d,
                action: thresholds.action,
                minor: thresholds.minor,
                moderate: thresholds.moderate,
                major: thresholds.major
            ))
        }
        return results.sorted { $0.distanceKm < $1.distanceKm }
    }

    private static func extractThresholds(from gauge: [String: Any]) -> (action: Double?, minor: Double?, moderate: Double?, major: Double?) {
        guard let flood = gauge["flood"] as? [String: Any],
              let cats = flood["categories"] as? [String: Any]
        else { return (nil, nil, nil, nil) }

        func stage(_ key: String) -> Double? {
            guard let entry = cats[key] as? [String: Any] else { return nil }
            if let s = entry["stage"] as? Double { return s }
            if let s = entry["stage"] as? Int    { return Double(s) }
            if let s = entry["stage"] as? String { return Double(s) }
            return nil
        }
        return (stage("action"), stage("minor"), stage("moderate"), stage("major"))
    }
}
