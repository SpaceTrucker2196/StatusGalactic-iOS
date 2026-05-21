import Foundation

/// Summits On The Air recent-spots feed. SOTA's public API at
/// `https://api-db2.sota.org.uk/api/spots/-1/all` returns the latest spots
/// (most recent first). Anonymous; no key required.
///
/// `frequency` is published in MHz as a string ("14.062"). We normalize to
/// kHz to match POTASpot's units so the UI band-color logic can reuse the
/// same scale.
struct SOTAClient {
    let session: URLSession
    let userAgent: String

    init(session: URLSession = .shared, userAgent: String) {
        self.session = session
        self.userAgent = userAgent
    }

    static let url = URL(string: "https://api-db2.sota.org.uk/api/spots/-1/all")!

    func fetchRecent(limit: Int = 8) async throws -> [SOTASpot] {
        let data = try await session.getData(from: Self.url, userAgent: userAgent, timeout: 8)
        guard let rows = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }
        return rows
            .compactMap { Self.parse($0) }
            .sorted { $0.spotTime > $1.spotTime }
            .prefix(limit)
            .map { $0 }
    }

    /// Visible for tests.
    static func parse(_ raw: [String: Any]) -> SOTASpot? {
        guard let activator = raw["activatorCallsign"] as? String,
              let summitCode = raw["summitCode"] as? String,
              let timeStr = (raw["timeStamp"] as? String) ?? (raw["time"] as? String)
        else { return nil }

        let id = (raw["id"] as? Int) ?? activator.hashValue
        let mhz = Self.parseDouble(raw["frequency"]) ?? 0
        let mode = (raw["mode"] as? String) ?? "—"
        let details = (raw["summitDetails"] as? String)
            ?? (raw["summitName"] as? String)
            ?? summitCode
        let comments = raw["comments"] as? String

        guard let when = Self.parseTime(timeStr) else { return nil }

        return SOTASpot(
            spotId: id,
            activator: activator,
            summitCode: summitCode,
            summitDetails: details,
            frequencyKHz: mhz * 1000,
            mode: mode,
            spotTime: when,
            comments: comments
        )
    }

    private static func parseDouble(_ any: Any?) -> Double? {
        if let d = any as? Double { return d }
        if let i = any as? Int { return Double(i) }
        if let s = any as? String { return Double(s) }
        return nil
    }

    private static let isoFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private static let isoPlain: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
    private static let noTZFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        f.timeZone = TimeZone(identifier: "UTC")
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private static func parseTime(_ s: String) -> Date? {
        if let d = isoFractional.date(from: s) { return d }
        if let d = isoPlain.date(from: s) { return d }
        if let d = noTZFmt.date(from: s) { return d }
        return nil
    }
}
