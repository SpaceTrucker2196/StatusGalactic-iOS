import Foundation

/// dxsummit.fi recent-spots aggregator — proxies the DX cluster network as
/// HTTP/JSON. Anonymous; rate-friendly. Each entry is one sighting of a
/// distant station broadcast by a spotter.
///
/// Frequency values in this feed are reported in kHz already.
struct DXClusterClient {
    let session: URLSession
    let userAgent: String

    init(session: URLSession = .shared, userAgent: String) {
        self.session = session
        self.userAgent = userAgent
    }

    static let url = URL(string: "https://www.dxsummit.fi/api/v1/spots")!

    func fetchRecent(limit: Int = 10) async throws -> [DXSpot] {
        // dxsummit.fi is known to be flaky — short timeout lets the brief
        // refresh fall through to "no DX cluster" quickly rather than
        // dragging the whole fan-out out to 8 seconds every time.
        let data = try await session.getData(from: Self.url, userAgent: userAgent, timeout: 4)
        // dxsummit returns either a bare array or {"spots":[...]} depending
        // on path. Tolerate both.
        let payload = try JSONSerialization.jsonObject(with: data)
        let rows: [[String: Any]]
        if let arr = payload as? [[String: Any]] {
            rows = arr
        } else if let wrapped = payload as? [String: Any],
                  let inner = wrapped["spots"] as? [[String: Any]] {
            rows = inner
        } else {
            return []
        }
        return rows
            .compactMap { Self.parse($0) }
            .sorted { $0.spotTime > $1.spotTime }
            .prefix(limit)
            .map { $0 }
    }

    /// Visible for tests.
    static func parse(_ raw: [String: Any]) -> DXSpot? {
        guard let spotter = (raw["spotter"] as? String) ?? (raw["de_call"] as? String),
              let dx = (raw["dx_call"] as? String) ?? (raw["dxCall"] as? String)
        else { return nil }
        let freq = Self.parseDouble(raw["frequency"]) ?? 0
        let info = (raw["info"] as? String) ?? (raw["comment"] as? String)
        let timeStr = (raw["time"] as? String)
            ?? (raw["timestamp"] as? String)
            ?? (raw["spot_time"] as? String)
            ?? ""
        let when = Self.parseTime(timeStr) ?? Date()
        return DXSpot(
            dxCallsign: dx,
            spotter: spotter,
            frequencyKHz: freq,
            info: info,
            spotTime: when
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

    private static func parseTime(_ s: String) -> Date? {
        if let d = isoFractional.date(from: s) { return d }
        if let d = isoPlain.date(from: s) { return d }
        return nil
    }
}
