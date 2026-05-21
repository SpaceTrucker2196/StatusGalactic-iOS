import Foundation

/// USGS earthquake catalog. Free, no auth.
///
/// Two feeds merged into one ranked list:
/// - `significant_week.geojson` — globally newsworthy events past 7 days.
/// - Local query — last 7 days M2.5+ within `maxRadiusKm` of the viewer.
struct EarthquakeClient {
    let session: URLSession
    let userAgent: String

    init(session: URLSession = .shared, userAgent: String) {
        self.session = session
        self.userAgent = userAgent
    }

    static let significantURL = URL(string:
        "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/significant_week.geojson"
    )!
    static let queryBase = "https://earthquake.usgs.gov/fdsnws/event/1/query"

    /// Combined nearby + globally significant events in the past week, sorted
    /// by recency, capped to `limit`.
    func fetchRecent(
        viewerLat: Double?,
        viewerLng: Double?,
        maxRadiusKm: Double = 500,
        minLocalMagnitude: Double = 2.5,
        limit: Int = 8
    ) async -> [Earthquake] {
        async let significant: [Earthquake] = (try? await fetchSignificant()) ?? []
        async let local: [Earthquake] = {
            guard let lat = viewerLat, let lng = viewerLng else { return [] }
            return (try? await fetchNearby(
                lat: lat, lng: lng,
                radiusKm: maxRadiusKm, minMagnitude: minLocalMagnitude
            )) ?? []
        }()

        var merged: [String: Earthquake] = [:]
        for q in await significant { merged[q.id] = q }
        for q in await local {
            // Local hits trump global ones because they carry computed distance.
            merged[q.id] = q
        }

        if let lat = viewerLat, let lng = viewerLng {
            for (id, q) in merged where q.distanceKm == nil {
                merged[id]?.distanceKm = haversineKm(
                    lat1: lat, lng1: lng, lat2: q.latitude, lng2: q.longitude
                )
            }
        }

        return merged.values
            .sorted { $0.time > $1.time }
            .prefix(limit)
            .map { $0 }
    }

    func fetchSignificant() async throws -> [Earthquake] {
        let data = try await session.getData(from: Self.significantURL, userAgent: userAgent, timeout: 12)
        return Self.parseFeed(data: data, forceSignificant: true)
    }

    func fetchNearby(
        lat: Double,
        lng: Double,
        radiusKm: Double,
        minMagnitude: Double
    ) async throws -> [Earthquake] {
        let start = ISO8601DateFormatter().string(from:
            Calendar(identifier: .gregorian).date(byAdding: .day, value: -7, to: Date()) ?? Date()
        )
        var c = URLComponents(string: Self.queryBase)!
        c.queryItems = [
            URLQueryItem(name: "format", value: "geojson"),
            URLQueryItem(name: "starttime", value: start),
            URLQueryItem(name: "latitude", value: String(lat)),
            URLQueryItem(name: "longitude", value: String(lng)),
            URLQueryItem(name: "maxradiuskm", value: String(Int(radiusKm))),
            URLQueryItem(name: "minmagnitude", value: String(minMagnitude)),
            URLQueryItem(name: "orderby", value: "time"),
            URLQueryItem(name: "limit", value: "20"),
        ]
        guard let url = c.url else { throw HTTPError.invalidURL }
        let data = try await session.getData(from: url, userAgent: userAgent, timeout: 12)
        return Self.parseFeed(data: data, forceSignificant: false)
    }

    static func parseFeed(data: Data, forceSignificant: Bool) -> [Earthquake] {
        guard
            let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let features = payload["features"] as? [[String: Any]]
        else { return [] }

        var out: [Earthquake] = []
        for f in features {
            guard
                let id = f["id"] as? String,
                let props = f["properties"] as? [String: Any],
                let geom = f["geometry"] as? [String: Any],
                let coords = geom["coordinates"] as? [Double], coords.count >= 3
            else { continue }
            let mag = (props["mag"] as? Double) ?? 0
            let place = (props["place"] as? String) ?? "Unknown"
            let timeMs = (props["time"] as? Double) ?? 0
            let url = props["url"] as? String
            let sig = (props["sig"] as? Double) ?? 0
            out.append(Earthquake(
                id: id,
                magnitude: mag,
                place: place,
                time: Date(timeIntervalSince1970: timeMs / 1000),
                latitude: coords[1],
                longitude: coords[0],
                depthKm: coords[2],
                usgsURL: url,
                isSignificant: forceSignificant || sig >= 600,
                distanceKm: nil
            ))
        }
        return out
    }

}
