import Foundation

/// NOAA WWV / WWVH "Geophysical Alert Message" — the same bulletin broadcast
/// hourly on the WWV time-signal stations at 18 minutes past the hour.
///
/// Endpoint: `/text/wwv.txt`. The body is short and very structured:
///
///   :Product: Geophysical Alert Message wwv.txt
///   :Issued: 2026 May 20 1205 UTC
///   ...
///   Solar-terrestrial indices for 20 May follow.
///   Solar flux 114 and estimated planetary A-index 5.
///   The estimated planetary K-index at 1200 UTC on 20 May was 2.
///   Space weather for the past 24 hours has been minor.
///   ...
///   No space weather storms are predicted for the next 24 hours.
struct WWVClient {
    let session: URLSession
    let userAgent: String

    init(session: URLSession = .shared, userAgent: String) {
        self.session = session
        self.userAgent = userAgent
    }

    static let url = URL(string: "https://services.swpc.noaa.gov/text/wwv.txt")!

    func fetch() async throws -> WWVBulletin {
        let data = try await session.getData(from: Self.url, userAgent: userAgent, timeout: 8)
        let text = String(data: data, encoding: .utf8) ?? ""
        return Self.parse(text)
    }

    /// Visible for tests.
    static func parse(_ text: String) -> WWVBulletin {
        let lines = text.split(whereSeparator: { $0.isNewline }).map(String.init)

        var issued: Date?
        var flux: Int?
        var aIdx: Int?
        var kIdx: Int?
        var geomag: String?
        var prop: String?

        let issuedFmt = DateFormatter()
        issuedFmt.dateFormat = "yyyy MMM dd HHmm"
        issuedFmt.timeZone = TimeZone(identifier: "UTC")
        issuedFmt.locale = Locale(identifier: "en_US_POSIX")

        for line in lines {
            if line.hasPrefix(":Issued:") {
                let stripped = line
                    .replacingOccurrences(of: ":Issued:", with: "")
                    .replacingOccurrences(of: " UTC", with: "")
                    .trimmingCharacters(in: .whitespaces)
                issued = issuedFmt.date(from: stripped)
            } else if line.contains("Solar flux") {
                if let m = line.range(of: #"Solar flux (\d{1,4})"#, options: .regularExpression) {
                    let token = String(line[m])
                        .replacingOccurrences(of: "Solar flux ", with: "")
                    flux = Int(token)
                }
                if let m = line.range(of: #"A-index (\d{1,3})"#, options: .regularExpression) {
                    let token = String(line[m]).replacingOccurrences(of: "A-index ", with: "")
                    aIdx = Int(token)
                }
            } else if line.contains("K-index") {
                if let m = line.range(of: #"K-index .*? was (\d+)"#, options: .regularExpression) {
                    let token = String(line[m])
                        .replacingOccurrences(of: #".*was "#, with: "", options: .regularExpression)
                    kIdx = Int(token)
                }
            } else if line.lowercased().contains("space weather for the past") ||
                      line.lowercased().contains("space weather for") {
                geomag = line.trimmingCharacters(in: .whitespaces)
            } else if line.lowercased().contains("space weather storms") ||
                      line.lowercased().contains("space weather for the next") {
                prop = line.trimmingCharacters(in: .whitespaces)
            }
        }

        return WWVBulletin(
            issuedAt: issued,
            solarFlux: flux,
            aIndex: aIdx,
            kIndex: kIdx,
            geomagSummary: geomag,
            propagationSummary: prop,
            rawText: text
        )
    }
}
