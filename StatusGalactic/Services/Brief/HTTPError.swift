import Foundation

enum HTTPError: Error, LocalizedError {
    case invalidURL
    case badResponse(status: Int, body: String?)
    case decoding(Error)
    case transport(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL."
        case .badResponse(let status, let body):
            return "HTTP \(status): \(body ?? "")"
        case .decoding(let err):
            return "Decode failed: \(err.localizedDescription)"
        case .transport(let err):
            return "Network: \(err.localizedDescription)"
        }
    }
}

extension URLSession {
    /// Convenience: GET a URL, validate 2xx, return raw data with typed errors.
    func getData(from url: URL, userAgent: String) async throws -> Data {
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await self.data(for: request)
        } catch {
            throw HTTPError.transport(error)
        }
        guard let http = response as? HTTPURLResponse else {
            throw HTTPError.badResponse(status: -1, body: nil)
        }
        guard (200..<300).contains(http.statusCode) else {
            throw HTTPError.badResponse(
                status: http.statusCode,
                body: String(data: data, encoding: .utf8)
            )
        }
        return data
    }
}
