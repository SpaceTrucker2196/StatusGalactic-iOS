import Foundation

/// NWS active-alerts feed at a point. Endpoint:
/// `https://api.weather.gov/alerts/active?point=lat,lng`
///
/// Returns CAP-style alerts (warnings, watches, advisories). Sorted by
/// CAP severity descending so tornado warnings float to the top.
struct WeatherAlertsClient {
    let session: URLSession
    let userAgent: String

    init(session: URLSession = .shared, userAgent: String) {
        self.session = session
        self.userAgent = userAgent
    }

    func fetchActive(lat: Double, lng: Double) async throws -> [WeatherAlert] {
        var c = URLComponents(string: "https://api.weather.gov/alerts/active")!
        c.queryItems = [URLQueryItem(name: "point", value: "\(lat),\(lng)")]
        guard let url = c.url else { throw HTTPError.invalidURL }
        let data = try await session.getData(from: url, userAgent: userAgent, timeout: 12)
        return Self.parse(data)
    }

    /// Visible for tests.
    static func parse(_ data: Data) -> [WeatherAlert] {
        guard let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let features = payload["features"] as? [[String: Any]]
        else { return [] }

        let parser = ISO8601DateFormatter()
        parser.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]

        func date(_ any: Any?) -> Date? {
            guard let s = any as? String else { return nil }
            return parser.date(from: s) ?? plain.date(from: s)
        }

        var out: [WeatherAlert] = []
        for f in features {
            guard let props = f["properties"] as? [String: Any] else { continue }
            let id = (props["id"] as? String)
                ?? (f["id"] as? String)
                ?? UUID().uuidString
            let event = (props["event"] as? String) ?? "Alert"
            let severity = (props["severity"] as? String) ?? "Unknown"
            out.append(WeatherAlert(
                alertId: id,
                event: event,
                severity: severity,
                certainty: props["certainty"] as? String,
                urgency: props["urgency"] as? String,
                headline: props["headline"] as? String,
                description: props["description"] as? String,
                instruction: props["instruction"] as? String,
                areaDesc: props["areaDesc"] as? String,
                onsetAt: date(props["onset"]),
                expiresAt: date(props["expires"]) ?? date(props["ends"]),
                senderName: props["senderName"] as? String
            ))
        }
        return out.sorted { $0.severityLevel > $1.severityLevel }
    }
}
