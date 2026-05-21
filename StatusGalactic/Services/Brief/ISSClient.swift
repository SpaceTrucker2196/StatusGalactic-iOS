import Foundation

/// Currently-tracked persistent crewed orbital platforms. Add more by
/// looking up the NORAD ID and confirming wheretheiss.at returns a row.
struct CrewedSpacecraft: Hashable {
    let noradId: Int
    let name: String
}

enum CrewedSpacecraftCatalog {
    static let iss = CrewedSpacecraft(noradId: 25544, name: "ISS")
    static let tiangong = CrewedSpacecraft(noradId: 48274, name: "Tiangong (Tianhe)")

    /// All persistent crewed orbital objects worth tracking. Short-duration
    /// crew vehicles (Soyuz, Dragon, Starliner) come and go; they belong in
    /// a separate launch-tracker, not this list.
    static let all: [CrewedSpacecraft] = [iss, tiangong]
}

/// wheretheiss.at + N2YO client. Free, no auth for position; N2YO key
/// required for pass predictions.
struct ISSClient {
    let session: URLSession
    let userAgent: String

    init(session: URLSession = .shared, userAgent: String) {
        self.session = session
        self.userAgent = userAgent
    }

    static let baseURL = "https://api.wheretheiss.at/v1/satellites"

    /// Current position for an arbitrary NORAD satellite ID. The API supports
    /// any object in its catalog; we use it for ISS (25544) and Tianhe (48274).
    func fetchPosition(noradId: Int, name: String) async throws -> CrewedObject {
        guard let url = URL(string: "\(Self.baseURL)/\(noradId)") else {
            throw HTTPError.invalidURL
        }
        let data = try await session.getData(from: url, userAgent: userAgent)
        do {
            return try JSONDecoder().decode(Wire.self, from: data).toCrewedObject(
                noradId: noradId,
                name: name
            )
        } catch {
            throw HTTPError.decoding(error)
        }
    }

    /// Convenience wrapper that hits the full catalog in parallel and returns
    /// whatever came back. Failures per object are silently dropped.
    func fetchAllCrewedObjects() async -> [CrewedObject] {
        let session = self.session
        let userAgent = self.userAgent
        return await withTaskGroup(of: CrewedObject?.self) { group in
            for ship in CrewedSpacecraftCatalog.all {
                group.addTask {
                    let one = ISSClient(session: session, userAgent: userAgent)
                    return try? await one.fetchPosition(noradId: ship.noradId, name: ship.name)
                }
            }
            var out: [CrewedObject] = []
            for await result in group {
                if let result { out.append(result) }
            }
            // Stable order matching the catalog list.
            return CrewedSpacecraftCatalog.all.compactMap { ship in
                out.first { $0.noradId == ship.noradId }
            }
        }
    }

    /// Upcoming visible ISS passes (only ISS today). Requires N2YO key.
    func fetchVisualPasses(
        lat: Double,
        lng: Double,
        days: Int = 5,
        minVisibilitySeconds: Int = 60,
        apiKey: String
    ) async throws -> [ISSPass] {
        guard !apiKey.isEmpty else {
            throw HTTPError.badResponse(status: 401, body: "Set your N2YO API key in Settings.")
        }
        let path = "https://api.n2yo.com/rest/v1/satellite/visualpasses/25544/" +
                   "\(lat)/\(lng)/0/\(days)/\(minVisibilitySeconds)"
        var components = URLComponents(string: path)!
        components.queryItems = [URLQueryItem(name: "apiKey", value: apiKey)]
        guard let url = components.url else { throw HTTPError.invalidURL }

        let data = try await session.getData(from: url, userAgent: userAgent)
        do {
            return try JSONDecoder().decode(N2YOPasses.self, from: data).toISSPasses()
        } catch {
            throw HTTPError.decoding(error)
        }
    }

    private struct N2YOPasses: Decodable {
        let passes: [N2YOPass]?
        func toISSPasses() -> [ISSPass] {
            (passes ?? []).map { p in
                ISSPass(
                    startUTC: Date(timeIntervalSince1970: TimeInterval(p.startUTC)),
                    endUTC: Date(timeIntervalSince1970: TimeInterval(p.endUTC)),
                    maxUTC: Date(timeIntervalSince1970: TimeInterval(p.maxUTC)),
                    startAzCompass: p.startAzCompass,
                    endAzCompass: p.endAzCompass,
                    maxElevation: p.maxEl,
                    durationSeconds: p.duration,
                    magnitude: p.mag
                )
            }
        }
    }
    private struct N2YOPass: Decodable {
        let startUTC: Int
        let endUTC: Int
        let maxUTC: Int
        let startAzCompass: String?
        let endAzCompass: String?
        let maxEl: Double
        let duration: Int
        let mag: Double?
    }

    private struct Wire: Decodable {
        let latitude: Double
        let longitude: Double
        let altitude: Double      // km
        let velocity: Double      // km/h
        let visibility: String?
        let footprint: Double?    // km
        let timestamp: TimeInterval

        func toCrewedObject(noradId: Int, name: String) -> CrewedObject {
            CrewedObject(
                noradId: noradId,
                name: name,
                latitude: latitude,
                longitude: longitude,
                altitudeKm: altitude,
                velocityKmh: velocity,
                visibility: visibility,
                footprintKm: footprint,
                observedAt: Date(timeIntervalSince1970: timestamp)
            )
        }
    }
}
