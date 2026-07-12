import Foundation

/// RepeaterBook export API client.
///
/// As of 2026-03 the export API requires token auth: each user mints their own
/// app-bound token (`rbuapp_...`) for the approved app, sent in the
/// `X-RB-App-Token` header (RepeaterBook forbids shared tokens embedded in
/// distributed apps). With no token we skip the fetch rather than hit a
/// guaranteed 401. Returns ham repeaters near a city + US state; the API
/// accepts state name OR FIPS code, and we always send the FIPS code so we
/// don't trip over name capitalization.
struct RepeaterBookClient {
    let session: URLSession
    let userAgent: String
    let token: String

    init(session: URLSession = .shared, userAgent: String, token: String = "") {
        self.session = session
        self.userAgent = userAgent
        self.token = token
    }

    static let url = URL(string: "https://www.repeaterbook.com/api/export.php")!

    /// US state two-letter abbreviation → FIPS code.
    private static let fips: [String: String] = [
        "AL": "01", "AK": "02", "AZ": "04", "AR": "05",
        "CA": "06", "CO": "08", "CT": "09", "DE": "10",
        "DC": "11", "FL": "12", "GA": "13", "HI": "15",
        "ID": "16", "IL": "17", "IN": "18", "IA": "19",
        "KS": "20", "KY": "21", "LA": "22", "ME": "23",
        "MD": "24", "MA": "25", "MI": "26", "MN": "27",
        "MS": "28", "MO": "29", "MT": "30", "NE": "31",
        "NV": "32", "NH": "33", "NJ": "34", "NM": "35",
        "NY": "36", "NC": "37", "ND": "38", "OH": "39",
        "OK": "40", "OR": "41", "PA": "42", "RI": "44",
        "SC": "45", "SD": "46", "TN": "47", "TX": "48",
        "UT": "49", "VT": "50", "VA": "51", "WA": "53",
        "WV": "54", "WI": "55", "WY": "56",
    ]

    static func fipsCode(for abbreviation: String) -> String? {
        fips[abbreviation.uppercased()]
    }

    func fetchRepeaters(
        city: String,
        stateAbbreviation: String,
        limit: Int = 15
    ) async throws -> [Repeater] {
        let appToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !appToken.isEmpty else { return [] }
        guard let fipsCode = Self.fipsCode(for: stateAbbreviation) else {
            return []
        }
        var components = URLComponents(url: Self.url, resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "city", value: city),
            URLQueryItem(name: "state_id", value: fipsCode),
        ]
        guard let url = components.url else { throw HTTPError.invalidURL }

        let data = try await session.getData(
            from: url,
            userAgent: userAgent,
            headers: ["X-RB-App-Token": appToken]
        )
        guard let payload = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let results = payload["results"] as? [[String: Any]]
        else {
            return []
        }
        let mapped = results.compactMap { Self.parseRow($0) }
        return Array(mapped.prefix(limit))
    }

    private static func parseRow(_ row: [String: Any]) -> Repeater? {
        guard
            let callsign = row["Callsign"] as? String,
            let freqStr = row["Frequency"] as? String,
            let freq = Double(freqStr)
        else { return nil }

        let inputFreq = (row["Input Freq"] as? String).flatMap(Double.init)
        let offset = (row["Offset"] as? String).flatMap(Double.init)
        let pl = (row["PL"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        let city = (row["Nearest City"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        let landmark = (row["Landmark"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        let use = (row["Use"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        let status = (row["Operational Status"] as? String).flatMap { $0.isEmpty ? nil : $0 }

        var modes: [String] = []
        if isYes(row["FM Analog"]) { modes.append("FM") }
        if isYes(row["DMR"])       { modes.append("DMR") }
        if isYes(row["D-Star"])    { modes.append("D-Star") }
        if isYes(row["YSF"]) || isYes(row["System Fusion"]) { modes.append("Fusion") }
        if isYes(row["P25"])       { modes.append("P25") }
        if isYes(row["NXDN"])      { modes.append("NXDN") }
        if isYes(row["M17"])       { modes.append("M17") }
        if isYes(row["Tetra"])     { modes.append("Tetra") }
        if modes.isEmpty           { modes.append("Analog") }

        return Repeater(
            callsign: callsign,
            frequencyMHz: freq,
            inputFreqMHz: inputFreq,
            offsetMHz: offset,
            plTone: pl,
            modes: modes,
            nearestCity: city,
            landmark: landmark,
            useType: use,
            operationalStatus: status
        )
    }

    private static func isYes(_ value: Any?) -> Bool {
        guard let s = value as? String else { return false }
        let lower = s.lowercased()
        return lower == "yes" || lower == "y" || lower == "true" || lower == "1"
    }
}
