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
        async let plasma = (try? await fetchPlasmaSeries())
        async let mag    = (try? await fetchMagSeries())
        let pSamples = await plasma ?? []
        let mSamples = await mag ?? []
        guard let lastPlasma = pSamples.last,
              let lastMag = mSamples.last
        else {
            if pSamples.isEmpty && mSamples.isEmpty { return nil }
            // One side missed entirely; use whatever we have.
            let p = pSamples.last
            let m = mSamples.last
            let when = m?.time ?? p?.time ?? Date()
            return SolarWind(
                observedAt: when,
                speedKmS: p?.speed,
                densityP: p?.density,
                temperatureK: p?.temperature,
                bzNT: m?.bzGsm,
                btNT: m?.bt,
                history: Self.mergeHistory(plasma: pSamples, mag: mSamples)
            )
        }
        return SolarWind(
            observedAt: lastMag.time,
            speedKmS: lastPlasma.speed,
            densityP: lastPlasma.density,
            temperatureK: lastPlasma.temperature,
            bzNT: lastMag.bzGsm,
            btNT: lastMag.bt,
            history: Self.mergeHistory(plasma: pSamples, mag: mSamples)
        )
    }

    /// Bucket plasma + mag samples to ~5-minute intervals so the resulting
    /// sparkline isn't 1,440 points wide. Each bucket carries the bucket
    /// start time, the bucket-mean speed, and the bucket-mean Bz.
    private static func mergeHistory(
        plasma: [PlasmaSample], mag: [MagSample]
    ) -> [SolarWindSample] {
        let bucket: TimeInterval = 5 * 60     // 5 minutes
        var byKey: [Int: (count: Int, speedSum: Double, speedN: Int,
                          bzSum: Double, bzN: Int)] = [:]
        func key(_ d: Date) -> Int { Int(d.timeIntervalSince1970 / bucket) }
        for s in plasma {
            let k = key(s.time)
            var v = byKey[k] ?? (0, 0, 0, 0, 0)
            v.count += 1
            if let v0 = s.speed { v.speedSum += v0; v.speedN += 1 }
            byKey[k] = v
        }
        for m in mag {
            let k = key(m.time)
            var v = byKey[k] ?? (0, 0, 0, 0, 0)
            v.count += 1
            if let v0 = m.bzGsm { v.bzSum += v0; v.bzN += 1 }
            byKey[k] = v
        }
        return byKey.keys.sorted().map { k -> SolarWindSample in
            let v = byKey[k]!
            return SolarWindSample(
                time: Date(timeIntervalSince1970: TimeInterval(k) * bucket),
                speedKmS: v.speedN > 0 ? v.speedSum / Double(v.speedN) : nil,
                bzNT:     v.bzN > 0    ? v.bzSum    / Double(v.bzN)    : nil
            )
        }
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

    private func fetchPlasmaSeries() async throws -> [PlasmaSample] {
        let data = try await session.getData(from: Self.plasmaURL, userAgent: userAgent, timeout: 8)
        guard let rows = try JSONSerialization.jsonObject(with: data) as? [[Any]],
              rows.count > 1 else { return [] }
        let header = rows[0].compactMap { $0 as? String }
        let timeIdx = Self.indexIn(header, named: "time_tag") ?? 0
        let densityIdx = Self.indexIn(header, named: "density")
        let speedIdx = Self.indexIn(header, named: "speed")
        let tempIdx = Self.indexIn(header, named: "temperature")
        var out: [PlasmaSample] = []
        for row in rows.dropFirst() {
            guard timeIdx < row.count,
                  let t = Self.parseTime(row[timeIdx])
            else { continue }
            out.append(PlasmaSample(
                time: t,
                density: Self.parseDouble(row, at: densityIdx),
                speed: Self.parseDouble(row, at: speedIdx),
                temperature: Self.parseDouble(row, at: tempIdx)
            ))
        }
        return out
    }

    private func fetchMagSeries() async throws -> [MagSample] {
        let data = try await session.getData(from: Self.magURL, userAgent: userAgent, timeout: 8)
        guard let rows = try JSONSerialization.jsonObject(with: data) as? [[Any]],
              rows.count > 1 else { return [] }
        let header = rows[0].compactMap { $0 as? String }
        let timeIdx = Self.indexIn(header, named: "time_tag") ?? 0
        let bzIdx = Self.indexIn(header, named: "bz_gsm")
        let btIdx = Self.indexIn(header, named: "bt")
        var out: [MagSample] = []
        for row in rows.dropFirst() {
            guard timeIdx < row.count,
                  let t = Self.parseTime(row[timeIdx])
            else { continue }
            out.append(MagSample(
                time: t,
                bzGsm: Self.parseDouble(row, at: bzIdx),
                bt:    Self.parseDouble(row, at: btIdx)
            ))
        }
        return out
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
