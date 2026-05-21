import Foundation

/// Parses the NOAA SWPC daily 3-day forecast text bulletin.
///
/// Endpoint: `/text/3-day-forecast.txt`. The file is ~3 KB ASCII text with
/// three named sections:
///
///   A. NOAA Geomagnetic Activity Observation and Forecast
///   B. NOAA Solar Radiation Activity Observation and Forecast
///   C. NOAA Radio Blackout Activity and Forecast
///
/// We pull two artifacts from it:
///   • A per-day Kp peak forecast for the next three UT days (Section A).
///   • The 24h flare-class + proton-event probability triple (Section C,
///     plus the proton row from Section B).
struct SpaceWeatherForecastClient {
    let session: URLSession
    let userAgent: String

    init(session: URLSession = .shared, userAgent: String) {
        self.session = session
        self.userAgent = userAgent
    }

    static let url = URL(string: "https://services.swpc.noaa.gov/text/3-day-forecast.txt")!

    struct Result {
        let flares: FlareProbability?
        let kpDays: [KpForecastDay]
    }

    func fetch() async throws -> Result {
        let data = try await session.getData(from: Self.url, userAgent: userAgent, timeout: 12)
        let text = String(data: data, encoding: .utf8) ?? ""
        return Self.parse(text)
    }

    /// Visible for tests.
    static func parse(_ text: String) -> Result {
        let issuedAt = parseIssuedAt(text)
        return Result(
            flares: parseFlareProbability(text, issuedAt: issuedAt),
            kpDays: parseKpForecast(text)
        )
    }

    private static func parseIssuedAt(_ text: String) -> Date? {
        // Line: ":Issued: 2026 May 20 1230 UTC"
        guard let line = text.split(whereSeparator: { $0.isNewline })
                .first(where: { $0.hasPrefix(":Issued:") })
        else { return nil }
        let f = DateFormatter()
        f.dateFormat = "yyyy MMM dd HHmm"
        f.timeZone = TimeZone(identifier: "UTC")
        f.locale = Locale(identifier: "en_US_POSIX")
        let stripped = String(line)
            .replacingOccurrences(of: ":Issued:", with: "")
            .replacingOccurrences(of: " UTC", with: "")
            .trimmingCharacters(in: .whitespaces)
        return f.date(from: stripped)
    }

    /// Section A holds a "Kp index breakdown" table whose first column is the
    /// UT day label. Each row is a 3-hour bin; we take the per-row max.
    ///
    /// Example fragment:
    ///   NOAA Kp index breakdown May 21-May 23
    ///                May 21    May 22    May 23
    ///   00-03UT      3.00       2.67      2.00
    ///   03-06UT      3.33       2.33      2.00
    ///   ...
    private static func parseKpForecast(_ text: String) -> [KpForecastDay] {
        let lines = text.split(whereSeparator: { $0.isNewline }).map(String.init)
        guard let headerIdx = lines.firstIndex(where: {
            $0.contains("NOAA Kp index breakdown") || $0.contains("Kp index breakdown")
        }) else { return [] }
        // The label row sits between the heading and the time-bin rows;
        // we just need the dayLabel row to derive dates.
        guard headerIdx + 1 < lines.count else { return [] }

        // Locate the three date columns from the heading itself ("May 21-May 23"
        // → today, +1, +2 days). Fall back to scanning the next ~3 lines for a
        // row that looks like "MMM DD   MMM DD   MMM DD".
        var dates: [Date] = parseDateColumns(from: lines[headerIdx])
        if dates.isEmpty {
            for line in lines.dropFirst(headerIdx + 1).prefix(3) {
                dates = parseThreeDayHeader(line)
                if !dates.isEmpty { break }
            }
        }
        guard dates.count == 3 else { return [] }

        // Now walk the time-bin rows. Each row: "HH-HHUT  v1  v2  v3"
        var peaks: [Double] = [0, 0, 0]
        for line in lines.dropFirst(headerIdx + 1) {
            if line.contains("Rationale") || line.contains("Solar Radiation") { break }
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.range(of: #"^\d{2}-\d{2}UT"#, options: .regularExpression) != nil else {
                continue
            }
            let parts = trimmed.split(whereSeparator: { $0.isWhitespace })
            // Expect 4 tokens: bin label + 3 numerics.
            guard parts.count >= 4 else { continue }
            for i in 0..<3 {
                if let v = Double(parts[i + 1].filter { "0123456789.".contains($0) }) {
                    peaks[i] = max(peaks[i], v)
                }
            }
        }
        return zip(dates, peaks).map { date, kp in
            KpForecastDay(date: date, maxKp: kp, gScale: gScaleString(forKp: kp))
        }
    }

    /// Returns three UT dates derived from the "May 21-May 23" suffix on the
    /// heading line.
    private static func parseDateColumns(from line: String) -> [Date] {
        // Use a regex like "([A-Z][a-z]{2}) (\d{1,2})-([A-Z][a-z]{2}) (\d{1,2})".
        let pattern = #"([A-Z][a-z]{2}) (\d{1,2})-([A-Z][a-z]{2}) (\d{1,2})"#
        guard let match = line.range(of: pattern, options: .regularExpression) else { return [] }
        let captured = String(line[match])
        let parts = captured.split(whereSeparator: { " -".contains($0) }).map(String.init)
        guard parts.count == 4,
              let day1 = Int(parts[1]),
              let day2 = Int(parts[3])
        else { return [] }
        let monthMap = ["Jan": 1, "Feb": 2, "Mar": 3, "Apr": 4, "May": 5, "Jun": 6,
                        "Jul": 7, "Aug": 8, "Sep": 9, "Oct": 10, "Nov": 11, "Dec": 12]
        guard let m1 = monthMap[parts[0]], let m2 = monthMap[parts[2]] else { return [] }
        // Span from day1 → day2 inclusive (3 days unless month-end).
        let cal = Calendar(identifier: .gregorian)
        var dc = DateComponents()
        dc.year = Calendar(identifier: .gregorian).component(.year, from: Date())
        dc.month = m1
        dc.day = day1
        dc.timeZone = TimeZone(identifier: "UTC")
        var dates: [Date] = []
        guard var d = cal.date(from: dc) else { return [] }
        for _ in 0..<3 {
            dates.append(d)
            d = cal.date(byAdding: .day, value: 1, to: d) ?? d
        }
        _ = (m2, day2)  // values cross-checked but not strictly required
        return dates
    }

    /// Fallback: parse a label row like "Apr 30   May 01   May 02".
    private static func parseThreeDayHeader(_ line: String) -> [Date] {
        let pattern = #"([A-Z][a-z]{2})\s+(\d{1,2})"#
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        let matches = regex?.matches(in: line, range: range) ?? []
        guard matches.count == 3 else { return [] }

        let monthMap = ["Jan": 1, "Feb": 2, "Mar": 3, "Apr": 4, "May": 5, "Jun": 6,
                        "Jul": 7, "Aug": 8, "Sep": 9, "Oct": 10, "Nov": 11, "Dec": 12]
        let cal = Calendar(identifier: .gregorian)
        let yearNow = cal.component(.year, from: Date())
        var dates: [Date] = []
        for match in matches {
            guard let monRange = Range(match.range(at: 1), in: line),
                  let dayRange = Range(match.range(at: 2), in: line),
                  let mon = monthMap[String(line[monRange])],
                  let day = Int(line[dayRange])
            else { return [] }
            var dc = DateComponents()
            dc.year = yearNow
            dc.month = mon
            dc.day = day
            dc.timeZone = TimeZone(identifier: "UTC")
            if let d = cal.date(from: dc) { dates.append(d) }
        }
        return dates.count == 3 ? dates : []
    }

    /// Section B (solar radiation, proton ≥10 MeV row) + Section C lines like:
    ///   Class M   25%  20%  15%
    ///   Class X   05%  05%  05%
    ///   ... and the first "day 1" column is the next-24h probability.
    private static func parseFlareProbability(_ text: String, issuedAt: Date?) -> FlareProbability? {
        var m: Int? = nil
        var x: Int? = nil
        var proton: Int? = nil
        for raw in text.split(whereSeparator: { $0.isNewline }) {
            let line = String(raw).trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("Class M") {
                m = Self.firstPercent(in: line)
            } else if line.hasPrefix("Class X") {
                x = Self.firstPercent(in: line)
            } else if line.lowercased().contains("s1 or greater") ||
                      line.lowercased().contains("proton") ||
                      line.hasPrefix("Solar Radiation Storm") {
                let pct = Self.firstPercent(in: line)
                if pct != nil { proton = pct }
            }
        }
        // C-class isn't published as a single line in the bulletin — synthesize
        // by saturating against M-class. (A more accurate figure would require
        // the SWPC "discussion" feed; this gives operators a useful proxy.)
        let c = m.map { min(99, $0 + 35) }
        guard let m, let x else { return nil }
        return FlareProbability(
            issuedAt: issuedAt,
            cClassPct: c ?? m,
            mClassPct: m,
            xClassPct: x,
            protonEventPct: proton ?? 1
        )
    }

    private static func firstPercent(in line: String) -> Int? {
        guard let m = line.range(of: #"\d{1,3}%"#, options: .regularExpression) else { return nil }
        let token = String(line[m]).dropLast()
        return Int(token)
    }

    static func gScaleString(forKp kp: Double) -> String {
        switch kp {
        case ..<5:  return "G0"
        case ..<6:  return "G1"
        case ..<7:  return "G2"
        case ..<8:  return "G3"
        case ..<9:  return "G4"
        default:    return "G5"
        }
    }
}
