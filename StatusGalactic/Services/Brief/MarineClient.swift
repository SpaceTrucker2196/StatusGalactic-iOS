import Foundation

/// NWS marine forecasts via the legacy tgftp.nws.noaa.gov text bulletins.
/// api.weather.gov does not (yet) serve marine forecasts.
struct MarineClient {
    let session: URLSession
    let userAgent: String

    init(session: URLSession = .shared, userAgent: String) {
        self.session = session
        self.userAgent = userAgent
    }

    static let base = "https://tgftp.nws.noaa.gov/data/forecasts/marine"

    /// Two-letter region path segment keyed by the zone-ID prefix.
    static let regionPrefix: [String: String] = [
        "GM": "gm", "AM": "am", "AN": "an", "PZ": "pz", "PK": "pk", "PH": "ph",
        "SL": "sl", "LO": "lo", "LE": "le", "LH": "lh", "LM": "lm", "LS": "ls"
    ]

    func fetchMarineForecast(zoneId rawZone: String, periods: Int = 5) async throws -> MarineWeather {
        let zone = rawZone.uppercased().trimmingCharacters(in: .whitespaces)
        let prefix = String(zone.prefix(2))
        guard let region = Self.regionPrefix[prefix] else {
            throw HTTPError.invalidURL
        }

        let coastalURL = URL(string: "\(Self.base)/coastal/\(region)/\(zone.lowercased()).txt")!
        let offshoreURL = URL(string: "\(Self.base)/offshore/\(region)/\(zone.lowercased()).txt")!

        let text: String
        if let coastal = try? await fetchText(url: coastalURL) {
            text = coastal
        } else {
            text = try await fetchText(url: offshoreURL)
        }

        let parsed = Self.parseBulletin(text, maxPeriods: periods)
        return MarineWeather(zoneId: zone, periods: parsed)
    }

    private func fetchText(url: URL) async throws -> String {
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw HTTPError.badResponse(
                status: (response as? HTTPURLResponse)?.statusCode ?? -1,
                body: nil
            )
        }
        return String(data: data, encoding: .utf8) ?? ""
    }

    /// Parse an NWS marine text bulletin (`.PERIOD...body $$`) into periods.
    static func parseBulletin(_ text: String, maxPeriods: Int) -> [WeatherPeriod] {
        var periods: [WeatherPeriod] = []
        var currentName: String?
        var currentBody: [String] = []

        func flush() {
            guard let name = currentName, !currentBody.isEmpty else {
                currentName = nil
                currentBody = []
                return
            }
            let body = currentBody.map { $0.trimmingCharacters(in: .whitespaces) }
                .joined(separator: " ")
                .trimmingCharacters(in: .whitespaces)
            periods.append(WeatherPeriod(
                name: name.capitalized,
                shortForecast: body,
                temperature: nil,
                temperatureUnit: "F",
                isDaytime: !name.uppercased().contains("NIGHT"),
                wind: nil,
                detailedForecast: body
            ))
            currentName = nil
            currentBody = []
        }

        for rawLine in text.split(whereSeparator: { $0.isNewline }) {
            let line = String(rawLine)
            if line.hasPrefix("$$") {
                flush()
                if periods.count >= maxPeriods { break }
                continue
            }
            if let match = line.range(
                of: #"^\.([A-Z0-9 /-]+?)\.\.\.(.*)$"#,
                options: .regularExpression
            ) {
                flush()
                let body = String(line[match])
                let parts = body.components(separatedBy: "...")
                if parts.count >= 2 {
                    currentName = String(parts[0].dropFirst()) // drop leading "."
                    let rest = parts.dropFirst().joined(separator: "...").trimmingCharacters(in: .whitespaces)
                    if !rest.isEmpty { currentBody.append(rest) }
                }
                continue
            }
            if currentName != nil {
                currentBody.append(line)
            }
        }
        flush()
        return Array(periods.prefix(maxPeriods))
    }
}
