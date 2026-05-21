import Foundation

/// NOAA NCEI magnetic declination at a point.
///
/// Endpoint: `https://www.ngdc.noaa.gov/geomag-web/calculators/calculateDeclination?lat1=X&lon1=Y&resultFormat=json`
///
/// We cache the result in UserDefaults keyed by a 0.1°-rounded coord bucket
/// so brief refreshes from the same spot don't re-pound NOAA every time.
/// The WMM model only changes meaningfully on the year-or-longer scale, so
/// our 30-day TTL is generous enough to hide network blips.
struct MagneticDeclinationClient {
    let session: URLSession
    let userAgent: String

    init(session: URLSession = .shared, userAgent: String) {
        self.session = session
        self.userAgent = userAgent
    }

    static let defaultsKey = "io.river.statusgalactic.magCache"
    static let ttl: TimeInterval = 30 * 24 * 60 * 60   // 30 days

    /// Cache-aware fetch. Returns a cached value if it's within `ttl` and
    /// the coord-bucket matches; otherwise hits NCEI and writes back.
    func fetch(lat: Double, lng: Double) async -> MagneticDeclination? {
        if let cached = Self.loadCached(lat: lat, lng: lng),
           Date().timeIntervalSince(cached.observedAt) < Self.ttl {
            return cached
        }
        guard let fresh = try? await fetchFresh(lat: lat, lng: lng) else {
            return Self.loadCached(lat: lat, lng: lng)     // honor stale cache on failure
        }
        Self.persist(fresh)
        return fresh
    }

    func fetchFresh(lat: Double, lng: Double) async throws -> MagneticDeclination? {
        var c = URLComponents(string: "https://www.ngdc.noaa.gov/geomag-web/calculators/calculateDeclination")!
        c.queryItems = [
            URLQueryItem(name: "lat1", value: String(lat)),
            URLQueryItem(name: "lon1", value: String(lng)),
            URLQueryItem(name: "resultFormat", value: "json"),
            URLQueryItem(name: "model", value: "WMM"),
        ]
        guard let url = c.url else { throw HTTPError.invalidURL }
        let data = try await session.getData(from: url, userAgent: userAgent, timeout: 8)
        return Self.parse(data, lat: lat, lng: lng)
    }

    /// Visible for tests.
    static func parse(_ data: Data, lat: Double, lng: Double) -> MagneticDeclination? {
        guard let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let results = payload["result"] as? [[String: Any]],
              let first = results.first
        else { return nil }

        let model = payload["model"] as? String
        let decl = (first["declination"] as? Double)
            ?? Double((first["declination"] as? String) ?? "")
        guard let decl else { return nil }

        let incl = (first["inclination"] as? Double)
            ?? Double((first["inclination"] as? String) ?? "")
        let total = (first["totalintensity"] as? Double)
            ?? (first["total_intensity"] as? Double)
            ?? Double((first["totalintensity"] as? String) ?? "")
        let modelDate = (first["date"] as? Double)
            ?? Double((first["date"] as? String) ?? "")

        return MagneticDeclination(
            latitude: lat,
            longitude: lng,
            declinationDeg: decl,
            inclinationDeg: incl,
            totalFieldNT: total,
            modelDate: modelDate,
            model: model,
            observedAt: Date()
        )
    }

    // MARK: - Cache

    private static func bucketKey(lat: Double, lng: Double) -> String {
        let rLat = (lat * 10).rounded() / 10
        let rLng = (lng * 10).rounded() / 10
        return String(format: "%.1f,%.1f", rLat, rLng)
    }

    private static func loadCached(lat: Double, lng: Double) -> MagneticDeclination? {
        let key = bucketKey(lat: lat, lng: lng)
        guard let dict = UserDefaults.standard.dictionary(forKey: defaultsKey),
              let raw = dict[key] as? Data
        else { return nil }
        return try? JSONDecoder().decode(MagneticDeclination.self, from: raw)
    }

    private static func persist(_ value: MagneticDeclination) {
        let key = bucketKey(lat: value.latitude, lng: value.longitude)
        guard let raw = try? JSONEncoder().encode(value) else { return }
        var dict = UserDefaults.standard.dictionary(forKey: defaultsKey) ?? [:]
        dict[key] = raw
        UserDefaults.standard.set(dict, forKey: defaultsKey)
    }
}
