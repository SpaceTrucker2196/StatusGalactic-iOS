import Foundation

/// KC2G global ionosonde feed — community-aggregated digisonde stations
/// (DGS / GIRO network) reporting current foF2 and MUF(3000)F2.
///
/// Endpoint: `https://prop.kc2g.com/api/stations.json`. Anonymous, JSON
/// array of station objects. Each carries `name`, `latitude`, `longitude`,
/// `mufd` (megahertz), `fof2`, plus a timestamp.
struct IonosondeClient {
    let session: URLSession
    let userAgent: String

    init(session: URLSession = .shared, userAgent: String) {
        self.session = session
        self.userAgent = userAgent
    }

    static let url = URL(string: "https://prop.kc2g.com/api/stations.json")!

    /// Returns the `limit` nearest stations to (lat, lng) with usable data,
    /// each tagged with their great-circle distance.
    func fetchNearest(
        lat: Double, lng: Double, limit: Int = 5
    ) async throws -> [IonosondeStation] {
        let data = try await session.getData(from: Self.url, userAgent: userAgent, timeout: 12)
        guard let rows = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }
        let parser = ISO8601DateFormatter()
        parser.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]

        var out: [IonosondeStation] = []
        for row in rows {
            guard let name = row["name"] as? String,
                  let stLat = row["latitude"] as? Double,
                  let stLng = row["longitude"] as? Double
            else { continue }

            let fof2 = row["fof2"] as? Double
            let mufd = (row["mufd"] as? Double) ?? (row["muf"] as? Double)
            if fof2 == nil && mufd == nil { continue }

            let observed = (row["time"] as? String)
                .flatMap { parser.date(from: $0) ?? plain.date(from: $0) }

            let distance = haversineKm(lat1: lat, lng1: lng, lat2: stLat, lng2: stLng)
            out.append(IonosondeStation(
                name: name,
                latitude: stLat,
                longitude: stLng,
                fof2MHz: fof2,
                mufMHz: mufd,
                observedAt: observed,
                distanceKm: distance
            ))
        }
        return out
            .sorted { ($0.distanceKm ?? .infinity) < ($1.distanceKm ?? .infinity) }
            .prefix(limit)
            .map { $0 }
    }
}
