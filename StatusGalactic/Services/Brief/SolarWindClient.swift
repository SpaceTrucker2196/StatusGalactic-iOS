import Foundation

/// L1 solar wind snapshot from NOAA SWPC's DSCOVR/ACE plasma + magnetic
/// product feeds. Two endpoints, last sample from each, merged.
///
///   plasma-1-day.json: [["time_tag","density","speed","temperature"], rows...]
///   mag-1-day.json:    [["time_tag","bx_gsm","by_gsm","bz_gsm",
///                        "lon_gsm","lat_gsm","bt"], rows...]
struct SolarWindClient {
    let session: URLSession
    let userAgent: String

    init(session: URLSession = .shared, userAgent: String) {
        self.session = session
        self.userAgent = userAgent
    }

    static let plasmaURL = URL(string:
        "https://services.swpc.noaa.gov/products/solar-wind/plasma-1-day.json"
    )!
    static let magURL = URL(string:
        "https://services.swpc.noaa.gov/products/solar-wind/mag-1-day.json"
    )!

    /// Returns nil if both feeds fail; otherwise merges whatever we got. Either
    /// half of the result may be `nil` if its endpoint missed.
    func fetch() async -> SolarWind? {
        async let plasma = (try? await fetchLastPlasma())
        async let mag    = (try? await fetchLastMag())
        let p = await plasma
        let m = await mag
        if p == nil && m == nil { return nil }
        let when = m?.time ?? p?.time ?? Date()
        return SolarWind(
            observedAt: when,
            speedKmS: p?.speed,
            densityP: p?.density,
            temperatureK: p?.temperature,
            bzNT: m?.bzGsm,
            btNT: m?.bt
        )
    }

    private struct PlasmaSample {
        let time: Date
        let density: Double?
        let speed: Double?
        let temperature: Double?
    }
    private struct MagSample {
        let time: Date
        let bzGsm: Double?
        let bt: Double?
    }

    private func fetchLastPlasma() async throws -> PlasmaSample? {
        let data = try await session.getData(from: Self.plasmaURL, userAgent: userAgent, timeout: 12)
        guard let rows = try JSONSerialization.jsonObject(with: data) as? [[Any]],
              rows.count > 1 else { return nil }
        let header = rows[0].compactMap { $0 as? String }
        let body = rows.dropFirst()
        guard let last = Self.lastValidRow(body) else { return nil }
        let t = Self.parseTime(last[Self.indexIn(header, named: "time_tag") ?? 0])
        guard let t else { return nil }
        return PlasmaSample(
            time: t,
            density: Self.parseDouble(last, at: Self.indexIn(header, named: "density")),
            speed: Self.parseDouble(last, at: Self.indexIn(header, named: "speed")),
            temperature: Self.parseDouble(last, at: Self.indexIn(header, named: "temperature"))
        )
    }

    private func fetchLastMag() async throws -> MagSample? {
        let data = try await session.getData(from: Self.magURL, userAgent: userAgent, timeout: 12)
        guard let rows = try JSONSerialization.jsonObject(with: data) as? [[Any]],
              rows.count > 1 else { return nil }
        let header = rows[0].compactMap { $0 as? String }
        let body = rows.dropFirst()
        guard let last = Self.lastValidRow(body) else { return nil }
        let t = Self.parseTime(last[Self.indexIn(header, named: "time_tag") ?? 0])
        guard let t else { return nil }
        return MagSample(
            time: t,
            bzGsm: Self.parseDouble(last, at: Self.indexIn(header, named: "bz_gsm")),
            bt:    Self.parseDouble(last, at: Self.indexIn(header, named: "bt"))
        )
    }

    private static func lastValidRow(_ rows: ArraySlice<[Any]>) -> [Any]? {
        // Walk backward to find a row with a usable speed/Bz number.
        for row in rows.reversed() {
            let hasNumeric = row.dropFirst().contains { v in
                if let _ = v as? Double { return true }
                if let _ = v as? Int { return true }
                if let s = v as? String, Double(s) != nil { return true }
                return false
            }
            if hasNumeric { return row }
        }
        return rows.last
    }

    private static func indexIn(_ header: [String], named: String) -> Int? {
        header.firstIndex(of: named)
    }

    private static func parseDouble(_ row: [Any], at idx: Int?) -> Double? {
        guard let idx, idx < row.count else { return nil }
        let v = row[idx]
        if let d = v as? Double { return d }
        if let i = v as? Int { return Double(i) }
        if let s = v as? String { return Double(s) }
        return nil
    }

    private static func parseTime(_ value: Any) -> Date? {
        guard let s = value as? String else { return nil }
        let f1 = DateFormatter()
        f1.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        f1.timeZone = TimeZone(identifier: "UTC")
        f1.locale = Locale(identifier: "en_US_POSIX")
        let f2 = DateFormatter()
        f2.dateFormat = "yyyy-MM-dd HH:mm:ss"
        f2.timeZone = TimeZone(identifier: "UTC")
        f2.locale = Locale(identifier: "en_US_POSIX")
        return f1.date(from: s) ?? f2.date(from: s)
    }
}
