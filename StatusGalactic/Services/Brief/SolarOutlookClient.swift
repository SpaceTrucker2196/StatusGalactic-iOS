import Foundation

/// NOAA SWPC 27-day Space Weather Outlook. Text table at
/// `/text/27-day-outlook.txt`. Each row carries an F10.7 flux + Ap + max-Kp
/// projection for one UT day spanning a solar rotation.
///
/// Sample row formats vary slightly between issues; we tolerate any
/// whitespace separation as long as the leading tokens look like a date.
struct SolarOutlookClient {
    let session: URLSession
    let userAgent: String

    init(session: URLSession = .shared, userAgent: String) {
        self.session = session
        self.userAgent = userAgent
    }

    static let url = URL(string: "https://services.swpc.noaa.gov/text/27-day-outlook.txt")!

    func fetch() async throws -> [SolarOutlookDay] {
        let data = try await session.getData(from: Self.url, userAgent: userAgent, timeout: 8)
        let text = String(data: data, encoding: .utf8) ?? ""
        return Self.parse(text)
    }

    /// Visible for tests.
    static func parse(_ text: String) -> [SolarOutlookDay] {
        let monthMap = ["Jan": 1, "Feb": 2, "Mar": 3, "Apr": 4, "May": 5, "Jun": 6,
                        "Jul": 7, "Aug": 8, "Sep": 9, "Oct": 10, "Nov": 11, "Dec": 12]
        let cal = Calendar(identifier: .gregorian)
        var out: [SolarOutlookDay] = []
        for raw in text.split(whereSeparator: { $0.isNewline }) {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("#") || line.hasPrefix(":") { continue }

            // Tokens look like "2026 May 21 115 8 3" — split on whitespace.
            let tokens = line.split(whereSeparator: { $0.isWhitespace }).map(String.init)
            guard tokens.count >= 6,
                  let year = Int(tokens[0]),
                  let month = monthMap[tokens[1]],
                  let day = Int(tokens[2]),
                  let flux = Int(tokens[3]),
                  let ap = Int(tokens[4]),
                  let kp = Int(tokens[5])
            else { continue }

            var dc = DateComponents()
            dc.year = year
            dc.month = month
            dc.day = day
            dc.timeZone = TimeZone(identifier: "UTC")
            guard let date = cal.date(from: dc) else { continue }
            out.append(SolarOutlookDay(
                date: date,
                radioFlux: flux,
                aIndex: ap,
                largestKp: kp
            ))
        }
        return out
    }
}
