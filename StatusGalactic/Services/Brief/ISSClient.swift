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
