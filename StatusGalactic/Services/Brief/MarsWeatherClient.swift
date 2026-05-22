import Foundation

/// Current Mars weather from NASA's mars.nasa.gov RSS API.
///
/// There is no real-time Mars weather feed in the wild — every public source
/// publishes the data after downlink, calibration, and validation, which
/// typically takes 2–4 weeks. We pull *both* the Mars 2020 (Perseverance
/// MEDA) and MSL Curiosity (REMS) feeds and surface whichever is freshest.
/// Even the freshest reading is usually days to weeks old; the
/// `MarsWeather.ageDays` helper lets the UI surface that explicitly.
struct MarsWeatherClient {
    let session: URLSession
    let userAgent: String

    init(session: URLSession = .shared, userAgent: String) {
        self.session = session
        self.userAgent = userAgent
    }

    static let perseveranceURL = URL(string:
        "https://mars.nasa.gov/rss/api/?feed=weather&category=mars2020&feedtype=json"
    )!
    static let curiosityURL = URL(string:
        "https://mars.nasa.gov/rss/api/?feed=weather&category=msl&feedtype=json"
    )!

    /// Fetches both rover feeds in parallel and returns whichever has the
    /// most recent terrestrial date. Throws only when both fail.
    func fetchLatest() async throws -> MarsWeather {
        async let m2020: MarsWeather? = (try? await fetchSingle(
            url: Self.perseveranceURL, mission: "Perseverance"
        ))
        async let msl: MarsWeather? = (try? await fetchSingle(
            url: Self.curiosityURL, mission: "Curiosity"
        ))
        let candidates = await [m2020, msl].compactMap { $0 }
        guard let best = candidates.max(by: { Self.dateSortKey($0) < Self.dateSortKey($1) })
        else {
            throw HTTPError.decoding(
                NSError(
                    domain: "mars",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "No Mars sol data from either rover"]
                )
            )
        }
        return best
    }

    private func fetchSingle(url: URL, mission: String) async throws -> MarsWeather {
        let data = try await session.getData(from: url, userAgent: userAgent, timeout: 8)
        guard let payload = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let sols = payload["sols"] as? [[String: Any]],
              let latest = sols.last
        else {
            throw HTTPError.decoding(
                NSError(
                    domain: "mars",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "No sol data for \(mission)"]
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
            sunset: latest["sunset"] as? String,
            source: mission
        )
    }

    /// "2026-04-30" sorts lexicographically same as chronologically, so we
    /// pick freshness by string comparison and fall back to sol number.
    private static func dateSortKey(_ w: MarsWeather) -> String {
        w.terrestrialDate ?? String(format: "0000-00-%05d", w.sol)
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
