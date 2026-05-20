import Foundation

/// Current ISS position via `wheretheiss.at`. Free, no auth.
///
/// Returns approximately real-time lat/lng/altitude/velocity for the ISS
/// (NORAD ID 25544) plus a daylight/eclipsed visibility flag.
struct ISSClient {
    let session: URLSession
    let userAgent: String

    init(session: URLSession = .shared, userAgent: String) {
        self.session = session
        self.userAgent = userAgent
    }

    static let url = URL(string: "https://api.wheretheiss.at/v1/satellites/25544")!

    func fetchPosition() async throws -> ISSPosition {
        let data = try await session.getData(from: Self.url, userAgent: userAgent)
        do {
            return try JSONDecoder().decode(Wire.self, from: data).toPosition()
        } catch {
            throw HTTPError.decoding(error)
        }
    }

    /// Upcoming visible ISS passes for an observer at (lat, lng) over the
    /// next `days` days. Requires an N2YO API key (free at n2yo.com).
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
        let visibility: String?   // "daylight" | "eclipsed"
        let footprint: Double?    // km
        let timestamp: TimeInterval

        func toPosition() -> ISSPosition {
            ISSPosition(
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
