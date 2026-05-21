import Foundation

/// Current Mars weather from NASA Mars 2020 (Perseverance) MEDA data, served
/// at mars.nasa.gov/rss/api.
///
/// Replaces the long-dead MAAS2 community proxy. The Mars 2020 feed isn't
/// updated as frequently as MEDA's source — the most recent sol may be a
/// few weeks old at any given moment. That's OK for a "what's the weather
/// on Mars" reading; if the feed disappears entirely, the brief just hides
/// the section.
struct MarsWeatherClient {
    let session: URLSession
    let userAgent: String

    init(session: URLSession = .shared, userAgent: String) {
        self.session = session
        self.userAgent = userAgent
    }

    static let url = URL(string:
        "https://mars.nasa.gov/rss/api/?feed=weather&category=mars2020&feedtype=json"
    )!

    func fetchLatest() async throws -> MarsWeather {
        let data = try await session.getData(from: Self.url, userAgent: userAgent, timeout: 8)
        guard let payload = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let sols = payload["sols"] as? [[String: Any]],
              let latest = sols.last
        else {
            throw HTTPError.decoding(
                NSError(
                    domain: "mars2020",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "No sol data"]
                )
            )
        }

        let solInt = Self.parseInt(latest["sol"]) ?? 0
        return MarsWeather(
            sol: solInt,
            season: (latest["season"] as? String).map { $0.capitalized },
            terrestrialDate: latest["terrestrial_date"] as? String,
            minTempC: Self.parseDouble(latest["min_temp"]),
            maxTempC: Self.parseDouble(latest["max_temp"]),
            pressurePa: Self.parseDouble(latest["pressure"]),
            atmoOpacity: latest["atmo_opacity"] as? String,
            sunrise: latest["sunrise"] as? String,
            sunset: latest["sunset"] as? String
        )
    }

    // The feed mixes string sentinels ("--") with numerics, so be liberal.
    private static func parseDouble(_ any: Any?) -> Double? {
        if let d = any as? Double { return d }
        if let i = any as? Int { return Double(i) }
        if let s = any as? String, s != "--", !s.isEmpty { return Double(s) }
        return nil
    }
    private static func parseInt(_ any: Any?) -> Int? {
        if let i = any as? Int { return i }
        if let s = any as? String { return Int(s) }
        return nil
    }
}
