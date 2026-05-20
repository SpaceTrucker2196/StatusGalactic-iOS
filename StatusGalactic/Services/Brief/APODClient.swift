import Foundation

/// NASA Astronomy Picture of the Day client.
///
/// `DEMO_KEY` works for a small number of calls per hour/day. For sustained
/// use, register a free key at https://api.nasa.gov and set it in Settings.
struct APODClient {
    let session: URLSession
    let userAgent: String
    let apiKey: String

    init(session: URLSession = .shared, userAgent: String, apiKey: String) {
        self.session = session
        self.userAgent = userAgent
        self.apiKey = apiKey.isEmpty ? "DEMO_KEY" : apiKey
    }

    static let base = URL(string: "https://api.nasa.gov/planetary/apod")!

    func fetchToday() async throws -> APOD {
        var components = URLComponents(url: Self.base, resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "thumbs", value: "true"),
        ]
        guard let url = components.url else { throw HTTPError.invalidURL }

        let data = try await session.getData(from: url, userAgent: userAgent)
        do {
            return try JSONDecoder().decode(APOD.self, from: data)
        } catch {
            throw HTTPError.decoding(error)
        }
    }
}
