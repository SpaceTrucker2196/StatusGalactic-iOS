import Foundation

/// The Space Devs Launch Library 2 client.
struct LaunchesClient {
    let session: URLSession
    let userAgent: String

    init(session: URLSession = .shared, userAgent: String) {
        self.session = session
        self.userAgent = userAgent
    }

    static let url = URL(string: "https://ll.thespacedevs.com/2.2.0/launch/upcoming/?limit=5&mode=list")!

    func fetchUpcomingLaunches() async throws -> [Launch] {
        let data = try await session.getData(from: Self.url, userAgent: userAgent)
        let resp = try decoder.decode(LLResponse.self, from: data)

        return resp.results.compactMap { item -> Launch? in
            guard let net = item.net, let date = Self.parseISO(net) else { return nil }
            return Launch(
                name: item.name,
                whenUtc: date,
                pad: item.pad?.name,
                provider: item.launch_service_provider?.name,
                status: item.status?.name
            )
        }
    }

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()

    private static let isoFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private static let isoPlain: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    static func parseISO(_ s: String) -> Date? {
        if let d = isoFractional.date(from: s) { return d }
        if let d = isoPlain.date(from: s) { return d }
        return nil
    }

    private struct LLResponse: Codable {
        let results: [LLItem]
    }
    private struct LLItem: Codable {
        let name: String
        let net: String?
        let pad: LLPad?
        let launch_service_provider: LLProvider?
        let status: LLStatus?
    }
    private struct LLPad: Codable { let name: String? }
    private struct LLProvider: Codable { let name: String? }
    private struct LLStatus: Codable { let name: String? }
}
