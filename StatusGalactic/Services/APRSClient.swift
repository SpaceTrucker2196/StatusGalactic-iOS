import Foundation

struct APRSFix: Codable, Hashable {
    let call: String
    let lat: Double
    let lng: Double
    let comment: String?
}

struct APRSClient {
    let baseURL: URL
    let session: URLSession

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func locate(_ call: String) async throws -> APRSFix {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent("aprs/locate"),
            resolvingAgainstBaseURL: true
        ) else {
            throw BriefAPIError.invalidURL
        }
        components.queryItems = [URLQueryItem(name: "call", value: call)]
        guard let url = components.url else {
            throw BriefAPIError.invalidURL
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw BriefAPIError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw BriefAPIError.badResponse(status: -1, body: nil)
        }
        guard (200..<300).contains(http.statusCode) else {
            throw BriefAPIError.badResponse(
                status: http.statusCode,
                body: String(data: data, encoding: .utf8)
            )
        }

        do {
            return try JSONDecoder().decode(APRSFix.self, from: data)
        } catch {
            throw BriefAPIError.decoding(error)
        }
    }
}
