import Foundation

/// NOAA SWPC Solar Region Summary (SRS). Each entry is one numbered active
/// region currently on the visible disk.
///
/// Endpoint returns a JSON array; field names match the SRS bulletin
/// (`region`, `location`, `area`, `mag_class`, `spot_class`, `number_spots`,
/// `observed_date`).
struct ActiveRegionsClient {
    let session: URLSession
    let userAgent: String

    init(session: URLSession = .shared, userAgent: String) {
        self.session = session
        self.userAgent = userAgent
    }

    static let url = URL(string: "https://services.swpc.noaa.gov/json/solar_regions.json")!

    /// Fetches the most recent SRS issue and returns one row per active region.
    /// Only the latest observed date in the file is kept — older snapshots are
    /// discarded so the table reflects "what's on the Sun right now".
    func fetchActive() async throws -> [ActiveRegion] {
        let data = try await session.getData(from: Self.url, userAgent: userAgent, timeout: 12)
        guard let rows = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }

        let dayFmt = DateFormatter()
        dayFmt.dateFormat = "yyyy-MM-dd"
        dayFmt.timeZone = TimeZone(identifier: "UTC")
        dayFmt.locale = Locale(identifier: "en_US_POSIX")

        // Pick the most recent observed_date present in the payload.
        var latestKey: String?
        for row in rows {
            if let d = row["observed_date"] as? String {
                if latestKey == nil || d > latestKey! { latestKey = d }
            }
        }
        guard let latestKey else { return [] }

        var out: [ActiveRegion] = []
        for row in rows where (row["observed_date"] as? String) == latestKey {
            guard let region = row["region"] as? Int else { continue }
            let lat = row["latitude"] as? Int
            let lng = row["longitude"] as? Int
            let area = row["area"] as? Int
            let nSpots = row["number_spots"] as? Int
            let mag = row["mag_class"] as? String
            let spot = row["spot_class"] as? String
            let loc = (row["location"] as? String) ?? Self.formatLocation(lat: lat, lng: lng)
            out.append(ActiveRegion(
                region: region,
                location: loc,
                latitude: lat,
                longitude: lng,
                area: area,
                numberOfSpots: nSpots,
                magClass: mag,
                spotClass: spot,
                observedAt: dayFmt.date(from: latestKey)
            ))
        }
        // Stable order: by region number descending (newest highest).
        return out.sorted { $0.region > $1.region }
    }

    /// "S16E23" from signed latitude/longitude.
    private static func formatLocation(lat: Int?, lng: Int?) -> String {
        guard let lat, let lng else { return "—" }
        let ns = lat >= 0 ? "N" : "S"
        let ew = lng >= 0 ? "W" : "E"   // SRS convention: + = west of central meridian
        return String(format: "%@%02d%@%02d", ns, abs(lat), ew, abs(lng))
    }
}
