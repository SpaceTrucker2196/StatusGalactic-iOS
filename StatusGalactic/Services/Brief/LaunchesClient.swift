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

    /// Same upcoming endpoint as the generic list but requesting the
    /// detailed mode so we can read `mission.type` (needed to filter for
    /// crewed flights). Limit is bumped because crewed launches are sparse.
    static let crewedURL = URL(string:
        "https://ll.thespacedevs.com/2.2.0/launch/upcoming/?limit=20&mode=detailed"
    )!

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

    /// Pulls the broader upcoming list in detailed mode and keeps launches
    /// whose mission is a human-spaceflight type — Soyuz crew rotations,
    /// Crew Dragon, Shenzhou, future Starliner/Starship-HLS missions, etc.
    func fetchUpcomingCrewedLaunches(limit: Int = 6) async throws -> [CrewedLaunch] {
        let data = try await session.getData(from: Self.crewedURL, userAgent: userAgent)
        let resp = try decoder.decode(LLDetailedResponse.self, from: data)
        let crewed = resp.results.compactMap { item -> CrewedLaunch? in
            guard let net = item.net, let date = Self.parseISO(net) else { return nil }
            let missionType = item.mission?.type?.lowercased() ?? ""
            let missionName = item.mission?.name?.lowercased() ?? ""
            let isCrewed =
                missionType.contains("human") ||
                missionType.contains("crew") ||
                missionName.contains("crew") ||
                missionName.contains("soyuz") ||
                missionName.contains("shenzhou") ||
                missionName.contains("starliner") ||
                missionName.contains("dragon")
            guard isCrewed else { return nil }
            return CrewedLaunch(
                name: item.name,
                whenUtc: date,
                pad: item.pad?.name,
                provider: item.launch_service_provider?.name,
                status: item.status?.name,
                missionName: item.mission?.name,
                missionDescription: item.mission?.description,
                rocketName: item.rocket?.configuration?.name,
                destination: item.mission?.orbit?.name
            )
        }
        return Array(crewed.prefix(limit))
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

    // MARK: - Detailed response (used by fetchUpcomingCrewedLaunches)

    private struct LLDetailedResponse: Codable {
        let results: [LLDetailedItem]
    }
    private struct LLDetailedItem: Codable {
        let name: String
        let net: String?
        let pad: LLPad?
        let launch_service_provider: LLProvider?
        let status: LLStatus?
        let rocket: LLRocket?
        let mission: LLMission?
    }
    private struct LLRocket: Codable {
        let configuration: LLRocketConfiguration?
    }
    private struct LLRocketConfiguration: Codable {
        let name: String?
    }
    private struct LLMission: Codable {
        let name: String?
        let description: String?
        let type: String?
        let orbit: LLOrbit?
    }
    private struct LLOrbit: Codable {
        let name: String?
    }
}
