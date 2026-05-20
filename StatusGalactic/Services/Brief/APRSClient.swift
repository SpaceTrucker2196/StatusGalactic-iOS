import Foundation

struct APRSFix: Codable, Hashable {
    let call: String
    let lat: Double
    let lng: Double
    let comment: String?

    // Optional rich fields populated from the aprs.fi `loc` response.
    var stationClass: String?     // "a" APRS, "i" AIS, "w" web
    var stationType: String?      // "l" station, "i" item, "o" object, "w" wx, "a" AIS
    var showname: String?
    var symbol: String?           // e.g. "/-" house, "/y" yagi, "/Y" yacht
    var srccall: String?
    var dstcall: String?
    var path: String?
    var phg: String?
    var courseDeg: Double?
    var speedKmh: Double?
    var altitudeM: Double?
    var lastTime: Date?
    var firstTime: Date?
    var statusMessage: String?
    var statusLastTime: Date?
}

/// Direct aprs.fi read-API client.
///
/// Requires an API key (`ClientConfig.aprsAPIKey`). Free, register at aprs.fi.
struct APRSClient {
    let session: URLSession
    let userAgent: String
    let apiKey: String

    init(session: URLSession = .shared, userAgent: String, apiKey: String) {
        self.session = session
        self.userAgent = userAgent
        self.apiKey = apiKey
    }

    static let base = URL(string: "https://api.aprs.fi/api/get")!

    func locate(_ call: String) async throws -> APRSFix {
        guard !apiKey.isEmpty else {
            throw HTTPError.badResponse(status: 401, body: "Set the aprs.fi API key in Settings.")
        }

        var components = URLComponents(url: Self.base, resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "name", value: call),
            URLQueryItem(name: "what", value: "loc"),
            URLQueryItem(name: "apikey", value: apiKey),
            URLQueryItem(name: "format", value: "json"),
        ]
        guard let url = components.url else { throw HTTPError.invalidURL }

        let data = try await session.getData(from: url, userAgent: userAgent)
        guard let payload = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw HTTPError.decoding(NSError(domain: "aprs", code: -1))
        }
        guard (payload["result"] as? String) == "ok" else {
            let desc = (payload["description"] as? String) ?? "aprs.fi error"
            throw HTTPError.badResponse(status: 502, body: desc)
        }
        guard let entries = payload["entries"] as? [[String: Any]], let first = entries.first else {
            throw HTTPError.badResponse(status: 404, body: "no entries for \(call)")
        }
        guard
            let latStr = (first["lat"] as? String) ?? (first["lat"] as? NSNumber)?.stringValue,
            let lngStr = (first["lng"] as? String) ?? (first["lng"] as? NSNumber)?.stringValue,
            let lat = Double(latStr),
            let lng = Double(lngStr)
        else {
            throw HTTPError.badResponse(status: 500, body: "missing lat/lng")
        }
        let name = (first["name"] as? String) ?? call.uppercased()
        let comment = first["comment"] as? String
        var fix = APRSFix(call: name, lat: lat, lng: lng, comment: comment)
        Self.attachRichFields(&fix, from: first)
        return fix
    }

    /// Batch locate up to 20 callsigns per request. aprs.fi accepts comma-
    /// separated names in `name=`. Returns whatever entries it has; missing
    /// callsigns are silently dropped.
    func locate(callsigns: [String]) async throws -> [APRSFix] {
        guard !apiKey.isEmpty else {
            throw HTTPError.badResponse(status: 401, body: "Set the aprs.fi API key in Settings.")
        }
        guard !callsigns.isEmpty else { return [] }

        let chunks = stride(from: 0, to: callsigns.count, by: 20).map {
            Array(callsigns[$0..<min($0 + 20, callsigns.count)])
        }
        var all: [APRSFix] = []
        for chunk in chunks {
            let joined = chunk.joined(separator: ",")
            var components = URLComponents(url: Self.base, resolvingAgainstBaseURL: true)!
            components.queryItems = [
                URLQueryItem(name: "name", value: joined),
                URLQueryItem(name: "what", value: "loc"),
                URLQueryItem(name: "apikey", value: apiKey),
                URLQueryItem(name: "format", value: "json"),
            ]
            guard let url = components.url else { throw HTTPError.invalidURL }
            let data = try await session.getData(from: url, userAgent: userAgent)
            guard let payload = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw HTTPError.decoding(NSError(domain: "aprs", code: -1))
            }
            guard (payload["result"] as? String) == "ok" else {
                let desc = (payload["description"] as? String) ?? "aprs.fi error"
                throw HTTPError.badResponse(status: 502, body: desc)
            }
            let entries = (payload["entries"] as? [[String: Any]]) ?? []
            for entry in entries {
                guard
                    let latStr = (entry["lat"] as? String) ?? (entry["lat"] as? NSNumber)?.stringValue,
                    let lngStr = (entry["lng"] as? String) ?? (entry["lng"] as? NSNumber)?.stringValue,
                    let lat = Double(latStr),
                    let lng = Double(lngStr),
                    let name = entry["name"] as? String
                else { continue }
                let comment = entry["comment"] as? String
                var fix = APRSFix(call: name.uppercased(), lat: lat, lng: lng, comment: comment)
                Self.attachRichFields(&fix, from: entry)
                all.append(fix)
            }
        }
        return all
    }

    /// Pull every supported optional field off an aprs.fi loc entry into the
    /// fix. Missing fields stay nil.
    private static func attachRichFields(_ fix: inout APRSFix, from entry: [String: Any]) {
        fix.stationClass = entry["class"] as? String
        fix.stationType  = entry["type"] as? String
        fix.showname     = entry["showname"] as? String
        fix.symbol       = entry["symbol"] as? String
        fix.srccall      = entry["srccall"] as? String
        fix.dstcall      = entry["dstcall"] as? String
        fix.path         = entry["path"] as? String
        fix.phg          = entry["phg"] as? String

        fix.courseDeg    = doubleField(entry["course"])
        fix.speedKmh     = doubleField(entry["speed"])
        fix.altitudeM    = doubleField(entry["altitude"])

        fix.lastTime       = unixField(entry["lasttime"])
        fix.firstTime      = unixField(entry["time"])
        fix.statusLastTime = unixField(entry["status_lasttime"])
        fix.statusMessage  = (entry["status"] as? String).flatMap { $0.isEmpty ? nil : $0 }
    }

    private static func doubleField(_ any: Any?) -> Double? {
        if let d = any as? Double { return d }
        if let i = any as? Int { return Double(i) }
        if let s = any as? String, !s.isEmpty { return Double(s) }
        return nil
    }

    /// aprs.fi sends Unix epoch seconds as either an Int or a stringified Int.
    private static func unixField(_ any: Any?) -> Date? {
        let secs: TimeInterval?
        if let i = any as? Int { secs = TimeInterval(i) }
        else if let d = any as? Double { secs = d }
        else if let s = any as? String, let i = Int(s) { secs = TimeInterval(i) }
        else { secs = nil }
        return secs.map { Date(timeIntervalSince1970: $0) }
    }
}
