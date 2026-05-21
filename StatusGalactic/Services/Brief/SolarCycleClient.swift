import Foundation

/// NOAA long-running observed solar-cycle indices. Monthly granularity,
/// reaching back to ~1750. We only keep the trailing ~60 months for the
/// "are we past solar max?" cycle-progression sparkline.
///
/// Endpoint payload: `[{"time-tag":"2026-04","ssn":121.3,"smoothed_ssn":118.0,"f10.7":117.2,"smoothed_f10.7":115.8}, ...]`
struct SolarCycleClient {
    let session: URLSession
    let userAgent: String

    init(session: URLSession = .shared, userAgent: String) {
        self.session = session
        self.userAgent = userAgent
    }

    static let url = URL(string:
        "https://services.swpc.noaa.gov/json/solar-cycle/observed-solar-cycle-indices.json"
    )!

    /// Returns the last `monthsBack` months of observations, sorted oldest
    /// → newest. Smoothed values may be nil for the tail.
    func fetchObserved(monthsBack: Int = 60) async throws -> [SolarCyclePoint] {
        let data = try await session.getData(from: Self.url, userAgent: userAgent, timeout: 8)
        guard let rows = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM"
        fmt.timeZone = TimeZone(identifier: "UTC")
        fmt.locale = Locale(identifier: "en_US_POSIX")

        var points: [SolarCyclePoint] = []
        for row in rows {
            guard let tag = row["time-tag"] as? String,
                  let month = fmt.date(from: tag)
            else { continue }
            let ssn = (row["ssn"] as? Double) ?? Double((row["ssn"] as? Int) ?? 0)
            let smoothedSSN = row["smoothed_ssn"] as? Double
            let f107 = (row["f10.7"] as? Double) ?? Double((row["f10.7"] as? Int) ?? 0)
            let smoothedF107 = row["smoothed_f10.7"] as? Double
            points.append(SolarCyclePoint(
                month: month,
                sunspotNumber: ssn,
                smoothedSunspotNumber: smoothedSSN,
                radioFlux: f107,
                smoothedRadioFlux: smoothedF107
            ))
        }
        return points
            .sorted { $0.month < $1.month }
            .suffix(monthsBack)
            .map { $0 }
    }
}
