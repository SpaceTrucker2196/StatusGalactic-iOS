import Foundation

struct APRSFix: Codable, Hashable {
    let call: String
    let lat: Double
    let lng: Double
    let comment: String?
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
        return APRSFix(call: name, lat: lat, lng: lng, comment: comment)
    }
}
