import Foundation

enum BriefAPIError: Error, LocalizedError {
    case invalidURL
    case badResponse(status: Int, body: String?)
    case decoding(Error)
    case transport(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid server URL."
        case .badResponse(let status, let body):
            return "Server returned HTTP \(status): \(body ?? "no body")"
        case .decoding(let err):
            return "Could not decode response: \(err.localizedDescription)"
        case .transport(let err):
            return "Network error: \(err.localizedDescription)"
        }
    }
}

struct BriefAPIClient {
    let baseURL: URL
    let session: URLSession

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            if let date = Self.fractionalFormatter.date(from: raw) { return date }
            if let date = Self.plainFormatter.date(from: raw) { return date }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unrecognized ISO8601 date: \(raw)"
            )
        }
        return decoder
    }

    private static let fractionalFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let plainFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    func fetchBrief(
        lat: Double? = nil,
        lng: Double? = nil,
        call: String? = nil,
        zone: String? = nil,
        tz: String? = nil
    ) async throws -> Brief {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent("brief"),
            resolvingAgainstBaseURL: true
        ) else {
            throw BriefAPIError.invalidURL
        }

        var items: [URLQueryItem] = []
        if let lat { items.append(.init(name: "lat", value: String(lat))) }
        if let lng { items.append(.init(name: "lng", value: String(lng))) }
        if let call, !call.isEmpty { items.append(.init(name: "call", value: call)) }
        if let zone, !zone.isEmpty { items.append(.init(name: "zone", value: zone)) }
        if let tz, !tz.isEmpty { items.append(.init(name: "tz", value: tz)) }
        components.queryItems = items.isEmpty ? nil : items

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
            return try Self.makeDecoder().decode(Brief.self, from: data)
        } catch {
            throw BriefAPIError.decoding(error)
        }
    }
}
