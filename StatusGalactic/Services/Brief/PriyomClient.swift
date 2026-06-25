import Foundation

/// One upcoming priyom.org shortwave broadcast — typically a numbers
/// station, military net, or other unusual transmission tracked by the
/// Priyom team. Sourced from `calendar2.priyom.org`.
struct PriyomBroadcast: Codable, Hashable, Identifiable {
    /// Composite of start time + summary; unique across the feed in
    /// practice and stable across re-fetches of the same window.
    var id: String { "\(Int(startTime.timeIntervalSince1970))-\(summary)" }

    /// Station designator, e.g. "F01", "V13", "E11", "S06s".
    let station: String
    /// Operating frequency in kilohertz.
    let frequencyKHz: Int
    /// Mode string as published, e.g. "AM", "USB", "RTTY", "USB/AM".
    let mode: String
    /// Target region when published, e.g. "Pacific", "East Asia". nil when omitted.
    let target: String?
    /// Scheduled start time (UTC).
    let startTime: Date
    /// Original summary line for fall-back rendering and parsing audit.
    let summary: String

    enum CodingKeys: String, CodingKey {
        case station
        case frequencyKHz = "frequency_khz"
        case mode
        case target
        case startTime = "start_time"
        case summary
    }
}

/// Fetches upcoming Priyom broadcasts from the public `calendar2`
/// endpoint that powers the "Next station" widget on
/// priyom.org/number-stations/station-schedule.
///
/// Endpoint:
/// `GET https://calendar2.priyom.org/events?timeMin=ISO8601&maxResults=N`
///
/// Returns:
/// `{ "items": [{ "summary": "F01 13370kHz RTTY [Target: Pacific]",
///                "start": { "dateTime": "2026-06-25T02:30:00.000Z" } }, ... ] }`
struct PriyomClient {
    let session: URLSession
    let userAgent: String

    init(session: URLSession = .shared, userAgent: String) {
        self.session = session
        self.userAgent = userAgent
    }

    static let base = "https://calendar2.priyom.org/events"

    /// Next upcoming broadcasts starting from `now`, capped to `limit`.
    func fetchUpcoming(now: Date = Date(), limit: Int = 30)
    async throws -> [PriyomBroadcast] {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        var c = URLComponents(string: Self.base)!
        c.queryItems = [
            URLQueryItem(name: "timeMin", value: iso.string(from: now)),
            URLQueryItem(name: "maxResults", value: String(limit)),
        ]
        guard let url = c.url else { throw HTTPError.invalidURL }
        let data = try await session.getData(
            from: url, userAgent: userAgent, timeout: 10
        )
        guard let payload = try? JSONSerialization.jsonObject(with: data)
                as? [String: Any],
              let items = payload["items"] as? [[String: Any]]
        else { return [] }

        let parsed: [PriyomBroadcast] = items.compactMap { Self.parse(item: $0) }
        let upcoming = parsed.filter { $0.startTime >= now }
        let sorted = upcoming.sorted { $0.startTime < $1.startTime }
        return Array(sorted.prefix(limit))
    }

    // MARK: - Parsing

    private static let isoParser: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let isoParserNoFraction: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    static func parse(item: [String: Any]) -> PriyomBroadcast? {
        guard let summary = item["summary"] as? String,
              let start = item["start"] as? [String: Any],
              let raw = start["dateTime"] as? String,
              let when = parseTime(raw)
        else { return nil }
        return parse(summary: summary, startTime: when)
    }

    /// Splits a summary line like
    /// `"F01 13370kHz RTTY [Target: Pacific]"` into structured fields.
    /// Returns nil when the line lacks the required station + frequency
    /// + mode prefix so we don't show malformed rows.
    static func parse(summary: String, startTime: Date) -> PriyomBroadcast? {
        // Pull off "[Target: ...]" if present.
        var head = summary.trimmingCharacters(in: .whitespaces)
        var target: String?
        if let openBracket = head.lastIndex(of: "["),
           let closeBracket = head.lastIndex(of: "]"),
           closeBracket > openBracket {
            let inside = head[head.index(after: openBracket)..<closeBracket]
                .trimmingCharacters(in: .whitespaces)
            if inside.lowercased().hasPrefix("target:") {
                target = inside
                    .dropFirst("target:".count)
                    .trimmingCharacters(in: .whitespaces)
                head = head[..<openBracket]
                    .trimmingCharacters(in: .whitespaces)
            }
        }

        // Remaining `head`: "STATION FREQkHz MODE..." — split on whitespace.
        let parts = head.split(separator: " ", maxSplits: 2,
                               omittingEmptySubsequences: true)
        guard parts.count >= 3 else { return nil }
        let station = String(parts[0])
        let freqToken = String(parts[1])
        let mode = String(parts[2])
        guard let khz = parseFrequencyKHz(freqToken) else { return nil }
        return PriyomBroadcast(
            station: station,
            frequencyKHz: khz,
            mode: mode,
            target: target,
            startTime: startTime,
            summary: summary
        )
    }

    /// Accepts "13370kHz", "13370 kHz", "13370KHz", "13370" — Priyom
    /// is consistent today but we stay lenient since the feed is
    /// community-edited upstream.
    static func parseFrequencyKHz(_ raw: String) -> Int? {
        let lowered = raw.lowercased()
        let digits = lowered
            .replacingOccurrences(of: "khz", with: "")
            .trimmingCharacters(in: .whitespaces)
        return Int(digits)
    }

    static func parseTime(_ s: String) -> Date? {
        if let d = isoParser.date(from: s) { return d }
        if let d = isoParserNoFraction.date(from: s) { return d }
        return nil
    }
}
