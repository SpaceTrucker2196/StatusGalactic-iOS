import Foundation

/// Celestrak constellation listings. Each query returns one JSON array per
/// element-set object in the named group; the array length is the live count.
///
/// Free, no auth. User-Agent recommended.
struct ConstellationsClient {
    let session: URLSession
    let userAgent: String

    init(session: URLSession = .shared, userAgent: String) {
        self.session = session
        self.userAgent = userAgent
    }

    static let base = "https://celestrak.org/NORAD/elements/gp.php"

    /// Constellations we always summarize on the brief.
    static let tracked: [(name: String, group: String)] = [
        ("Starlink", "starlink"),
        ("GPS Operational", "gps-ops"),
    ]

    /// Hit every tracked constellation in parallel; per-source failures are
    /// silently dropped.
    func fetchAll() async -> [ConstellationSummary] {
        let session = self.session
        let userAgent = self.userAgent
        return await withTaskGroup(of: ConstellationSummary?.self) { group in
            for (name, slug) in Self.tracked {
                group.addTask {
                    let one = ConstellationsClient(session: session, userAgent: userAgent)
                    return try? await one.fetch(name: name, group: slug)
                }
            }
            var out: [ConstellationSummary] = []
            for await result in group {
                if let result { out.append(result) }
            }
            // Stable display order.
            return Self.tracked.compactMap { entry in
                out.first { $0.group == entry.group }
            }
        }
    }

    /// Count + most-recent epoch for one Celestrak group.
    func fetch(name: String, group: String) async throws -> ConstellationSummary {
        var components = URLComponents(string: Self.base)!
        components.queryItems = [
            URLQueryItem(name: "GROUP", value: group),
            URLQueryItem(name: "FORMAT", value: "json"),
        ]
        guard let url = components.url else { throw HTTPError.invalidURL }

        let data = try await session.getData(from: url, userAgent: userAgent, timeout: 8)
        guard let rows = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return ConstellationSummary(name: name, group: group, count: 0, latestEpochAt: nil)
        }

        let parser = ISO8601DateFormatter()
        parser.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]

        var latest: Date?
        for row in rows {
            let epoch = (row["EPOCH"] as? String) ?? ""
            if let d = parser.date(from: epoch) ?? plain.date(from: epoch) {
                if (latest ?? .distantPast) < d { latest = d }
            }
        }

        return ConstellationSummary(
            name: name,
            group: group,
            count: rows.count,
            latestEpochAt: latest
        )
    }
}
