import Foundation

/// NASA DONKI (Space Weather Database Of Notifications, Knowledge,
/// Information) — CME catalogue. Same API key as APOD/NEO.
///
/// Endpoint: `GET https://api.nasa.gov/DONKI/CME?startDate=...&endDate=...&api_key=...`
///
/// Each entry may include a `cmeAnalyses` array; we pick the one flagged
/// `isMostAccurate` (or the last entry as a fallback) for speed/direction.
struct DONKIClient {
    let session: URLSession
    let userAgent: String
    let apiKey: String

    init(session: URLSession = .shared, userAgent: String, apiKey: String) {
        self.session = session
        self.userAgent = userAgent
        self.apiKey = apiKey.isEmpty ? "DEMO_KEY" : apiKey
    }

    static let base = "https://api.nasa.gov/DONKI/CME"

    /// CMEs detected in the past `days` days, newest first, capped to `limit`.
    func fetchRecent(days: Int = 5, limit: Int = 8) async throws -> [CMEEvent] {
        let cal = Calendar(identifier: .gregorian)
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.timeZone = TimeZone(identifier: "UTC")
        df.locale = Locale(identifier: "en_US_POSIX")
        let now = Date()
        let start = df.string(from: cal.date(byAdding: .day, value: -days, to: now) ?? now)
        let end = df.string(from: now)

        var c = URLComponents(string: Self.base)!
        c.queryItems = [
            URLQueryItem(name: "startDate", value: start),
            URLQueryItem(name: "endDate", value: end),
            URLQueryItem(name: "api_key", value: apiKey),
        ]
        guard let url = c.url else { throw HTTPError.invalidURL }
        let data = try await session.getData(from: url, userAgent: userAgent, timeout: 8)
        guard let rows = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }
        return rows
            .compactMap { Self.parse($0) }
            .sorted { $0.startTime > $1.startTime }
            .prefix(limit)
            .map { $0 }
    }

    private static let isoParser: ISO8601DateFormatter = {
        let p = ISO8601DateFormatter()
        p.formatOptions = [.withInternetDateTime]
        return p
    }()
    private static let isoParserNoZ: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mmX"
        f.timeZone = TimeZone(identifier: "UTC")
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private static func parse(_ raw: [String: Any]) -> CMEEvent? {
        guard let id = raw["activityID"] as? String,
              let startRaw = raw["startTime"] as? String,
              let start = parseTime(startRaw)
        else { return nil }

        let source = raw["sourceLocation"] as? String
        let note = raw["note"] as? String
        let link = raw["link"] as? String

        var speed: Double?
        var halfAngle: Double?
        var arrival: Date?
        var isHalo = false

        if let analyses = raw["cmeAnalyses"] as? [[String: Any]] {
            let chosen = analyses.first(where: { ($0["isMostAccurate"] as? Bool) == true })
                ?? analyses.last
            if let a = chosen {
                speed = a["speed"] as? Double
                halfAngle = a["halfAngle"] as? Double
                // Halo CMEs are half-angle ~> 60° on the limb projection.
                if let h = halfAngle, h >= 60 { isHalo = true }
                if let t = a["type"] as? String, t.uppercased() == "C" { isHalo = true }
                if let enlilList = a["enlilList"] as? [[String: Any]],
                   let firstEnlil = enlilList.first,
                   let arrivalStr = firstEnlil["estimatedShockArrivalTime"] as? String {
                    arrival = parseTime(arrivalStr)
                }
            }
        }

        return CMEEvent(
            activityID: id,
            startTime: start,
            sourceLocation: source,
            speedKmS: speed,
            halfAngleDeg: halfAngle,
            isHalo: isHalo,
            arrivalEstimateUtc: arrival,
            note: note,
            linkURL: link
        )
    }

    private static func parseTime(_ s: String) -> Date? {
        if let d = isoParser.date(from: s) { return d }
        if let d = isoParserNoZ.date(from: s) { return d }
        // DONKI sometimes emits "2026-05-19T12:48Z" without seconds.
        let alt = DateFormatter()
        alt.dateFormat = "yyyy-MM-dd'T'HH:mm'Z'"
        alt.timeZone = TimeZone(identifier: "UTC")
        alt.locale = Locale(identifier: "en_US_POSIX")
        return alt.date(from: s)
    }
}
