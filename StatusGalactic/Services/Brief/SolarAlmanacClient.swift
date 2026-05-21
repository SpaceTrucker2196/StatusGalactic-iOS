import Foundation

/// Historical samples for the solar almanac sparklines.
struct SolarFluxPoint: Hashable {
    let time: Date
    let flux: Double          // F10.7 cm radio flux (sfu)
}

struct KpPoint: Hashable {
    let time: Date
    let kp: Double            // estimated planetary K-index, 0..9
}

struct SolarAlmanac {
    let flux: [SolarFluxPoint]    // daily, ~last 30 days
    let kp: [KpPoint]             // 3-hourly, ~last 7 days
}

/// Pulls historical F10.7 cm radio flux + planetary Kp from NOAA SWPC.
///
/// Both endpoints are public, no auth. They return slightly different
/// shapes; parsing is defensive — partial failures degrade gracefully
/// to empty arrays rather than throwing the whole almanac away.
struct SolarAlmanacClient {
    let session: URLSession
    let userAgent: String

    init(session: URLSession = .shared, userAgent: String) {
        self.session = session
        self.userAgent = userAgent
    }

    static let fluxURL = URL(string: "https://services.swpc.noaa.gov/json/f107_cm_flux.json")!
    static let kpURL   = URL(string: "https://services.swpc.noaa.gov/products/noaa-planetary-k-index.json")!

    func fetch() async -> SolarAlmanac {
        async let flux: [SolarFluxPoint] = (try? await fetchFlux()) ?? []
        async let kp:   [KpPoint]        = (try? await fetchKp()) ?? []
        return SolarAlmanac(flux: await flux, kp: await kp)
    }

    func fetchFlux() async throws -> [SolarFluxPoint] {
        let data = try await session.getData(from: Self.fluxURL, userAgent: userAgent, timeout: 12)
        guard let rows = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }
        let parser = ISO8601DateFormatter()
        parser.formatOptions = [.withInternetDateTime]
        let dayParser = DateFormatter()
        dayParser.dateFormat = "yyyy-MM-dd"
        dayParser.timeZone = TimeZone(identifier: "UTC")
        dayParser.locale = Locale(identifier: "en_US_POSIX")

        let cutoff = Calendar(identifier: .gregorian)
            .date(byAdding: .day, value: -30, to: Date()) ?? Date.distantPast

        var out: [SolarFluxPoint] = []
        for row in rows {
            guard let tag = row["time_tag"] as? String else { continue }
            let date = parser.date(from: tag) ?? dayParser.date(from: tag)
            guard let date, date >= cutoff else { continue }
            let f = (row["flux"] as? Double)
                ?? Double((row["flux"] as? String) ?? "")
                ?? (row["observed_flux"] as? Double)
                ?? 0
            if f > 0 {
                out.append(SolarFluxPoint(time: date, flux: f))
            }
        }
        return out.sorted { $0.time < $1.time }
    }

    func fetchKp() async throws -> [KpPoint] {
        let data = try await session.getData(from: Self.kpURL, userAgent: userAgent, timeout: 12)
        guard let rows = try JSONSerialization.jsonObject(with: data) as? [[Any]],
              rows.count > 1
        else { return [] }

        let header = rows[0].compactMap { $0 as? String }
        guard let timeIdx = header.firstIndex(of: "time_tag"),
              let kpIdx = header.firstIndex(of: "Kp")
        else { return [] }

        // Sample format: "2026-05-19 21:00:00.000" (UTC).
        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        parser.timeZone = TimeZone(identifier: "UTC")
        parser.locale = Locale(identifier: "en_US_POSIX")
        let parserFallback = DateFormatter()
        parserFallback.dateFormat = "yyyy-MM-dd HH:mm:ss"
        parserFallback.timeZone = TimeZone(identifier: "UTC")
        parserFallback.locale = Locale(identifier: "en_US_POSIX")

        let cutoff = Calendar(identifier: .gregorian)
            .date(byAdding: .day, value: -7, to: Date()) ?? Date.distantPast

        var out: [KpPoint] = []
        for row in rows.dropFirst() {
            guard timeIdx < row.count, kpIdx < row.count,
                  let t = row[timeIdx] as? String
            else { continue }
            let date = parser.date(from: t) ?? parserFallback.date(from: t)
            guard let date, date >= cutoff else { continue }
            let kp: Double = {
                if let n = row[kpIdx] as? Double { return n }
                if let n = row[kpIdx] as? Int { return Double(n) }
                if let s = row[kpIdx] as? String { return Double(s) ?? 0 }
                return 0
            }()
            out.append(KpPoint(time: date, kp: kp))
        }
        return out.sorted { $0.time < $1.time }
    }
}
