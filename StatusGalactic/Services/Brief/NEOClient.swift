import Foundation

/// NASA NEO (Near-Earth Object) close-approach client.
///
/// `DEMO_KEY` works for a handful of requests per hour; register a free key
/// at api.nasa.gov for sustained use. Same key the APOD client uses.
struct NEOClient {
    let session: URLSession
    let userAgent: String
    let apiKey: String

    init(session: URLSession = .shared, userAgent: String, apiKey: String) {
        self.session = session
        self.userAgent = userAgent
        self.apiKey = apiKey.isEmpty ? "DEMO_KEY" : apiKey
    }

    static let base = URL(string: "https://api.nasa.gov/neo/rest/v1/feed")!

    /// Asteroids with close approaches in the next `days` days. Returns the
    /// top `limit` sorted by miss distance (closest first).
    func fetchUpcoming(days: Int = 2, limit: Int = 6) async throws -> [NearEarthObject] {
        let cal = Calendar(identifier: .gregorian)
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        let now = Date()
        let start = f.string(from: now)
        let end = f.string(from: cal.date(byAdding: .day, value: days, to: now) ?? now)

        var components = URLComponents(url: Self.base, resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "start_date", value: start),
            URLQueryItem(name: "end_date", value: end),
            URLQueryItem(name: "api_key", value: apiKey),
        ]
        guard let url = components.url else { throw HTTPError.invalidURL }

        let data = try await session.getData(from: url, userAgent: userAgent, timeout: 8)
        guard let payload = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let neoMap = payload["near_earth_objects"] as? [String: [[String: Any]]]
        else { return [] }

        var collected: [NearEarthObject] = []
        for (_, entries) in neoMap {
            for raw in entries {
                if let neo = Self.parse(raw) { collected.append(neo) }
            }
        }
        collected.sort { $0.missDistanceKm < $1.missDistanceKm }
        return Array(collected.prefix(limit))
    }

    private static func parse(_ raw: [String: Any]) -> NearEarthObject? {
        guard
            let name = raw["name"] as? String,
            let approach = (raw["close_approach_data"] as? [[String: Any]])?.first
        else { return nil }

        let mag = parseDouble(raw["absolute_magnitude_h"]) ?? 0
        let dia = (raw["estimated_diameter"] as? [String: Any])?["meters"] as? [String: Any]
        let dMin = parseDouble(dia?["estimated_diameter_min"]) ?? 0
        let dMax = parseDouble(dia?["estimated_diameter_max"]) ?? 0
        let hazardous = raw["is_potentially_hazardous_asteroid"] as? Bool ?? false
        let url = raw["nasa_jpl_url"] as? String

        let missKm = parseDouble((approach["miss_distance"] as? [String: Any])?["kilometers"]) ?? 0
        let velKps = parseDouble((approach["relative_velocity"] as? [String: Any])?["kilometers_per_second"]) ?? 0
        let when = parseEpochMillis(approach["epoch_date_close_approach"]) ?? Date()

        return NearEarthObject(
            name: name,
            magnitudeH: mag,
            diameterMinM: dMin,
            diameterMaxM: dMax,
            isHazardous: hazardous,
            approachAt: when,
            missDistanceKm: missKm,
            velocityKps: velKps,
            nasaJplURL: url
        )
    }

    private static func parseDouble(_ any: Any?) -> Double? {
        if let d = any as? Double { return d }
        if let i = any as? Int { return Double(i) }
        if let s = any as? String { return Double(s) }
        return nil
    }
    private static func parseEpochMillis(_ any: Any?) -> Date? {
        if let i = any as? Int { return Date(timeIntervalSince1970: TimeInterval(i) / 1000) }
        if let d = any as? Double { return Date(timeIntervalSince1970: d / 1000) }
        if let s = any as? String, let i = Int(s) { return Date(timeIntervalSince1970: TimeInterval(i) / 1000) }
        return nil
    }
}

/// Hardcoded catalog of known interstellar objects. New entries are extremely
/// rare (one every few years); easier to ship a static list than scrape
/// JPL SBDB. Update when a new interstellar visitor is confirmed.
enum InterstellarObjectCatalog {
    static let all: [InterstellarObject] = [
        .init(
            designation: "1I/'Oumuamua",
            discoveryDate: "2017-10-19",
            perihelionAU: 0.255,
            eccentricity: 1.20,
            inclinationDeg: 122.7,
            status: "Departed solar system (last observed Jan 2018)",
            notes: "First confirmed interstellar object. Hyperbolic orbit, e = 1.20. Origin direction near Vega; outbound toward Pegasus."
        ),
        .init(
            designation: "2I/Borisov",
            discoveryDate: "2019-08-30",
            perihelionAU: 2.007,
            eccentricity: 3.36,
            inclinationDeg: 44.05,
            status: "Departed solar system (last detailed observations 2020)",
            notes: "Second confirmed interstellar object and the first interstellar comet. Active outgassing typical of long-period comets."
        ),
        .init(
            designation: "3I/ATLAS",
            discoveryDate: "2025-07-01",
            perihelionAU: 1.36,
            eccentricity: 6.14,
            inclinationDeg: 175.1,
            status: "Inbound — perihelion late 2025, recedes through 2026",
            notes: "Third confirmed interstellar object. Detected by ATLAS Chile. Extreme eccentricity, near-retrograde orbit."
        ),
    ]
}
