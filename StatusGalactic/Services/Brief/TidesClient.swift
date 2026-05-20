import Foundation

/// NOAA Tides and Currents (CO-OPS) client. Free, no auth.
///
/// Given a location, we pick the nearest tide station from
/// `TideStationCatalog` and fetch today + tomorrow's high/low predictions in
/// UTC. Heights are in feet (English units), `MLLW` datum.
struct TidesClient {
    let session: URLSession
    let userAgent: String

    init(session: URLSession = .shared, userAgent: String) {
        self.session = session
        self.userAgent = userAgent
    }

    static let url = URL(string: "https://api.tidesandcurrents.noaa.gov/api/prod/datagetter")!

    func fetchNearestTides(lat: Double, lng: Double, days: Int = 2) async throws -> Tides? {
        guard let (station, distanceKm) = TideStationCatalog.nearest(toLat: lat, lng: lng)
        else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        let today = formatter.string(from: Date())
        let end = formatter.string(from: Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date())

        var components = URLComponents(url: Self.url, resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "station", value: station.id),
            URLQueryItem(name: "product", value: "predictions"),
            URLQueryItem(name: "datum", value: "MLLW"),
            URLQueryItem(name: "interval", value: "hilo"),
            URLQueryItem(name: "begin_date", value: today),
            URLQueryItem(name: "end_date", value: end),
            URLQueryItem(name: "time_zone", value: "gmt"),
            URLQueryItem(name: "units", value: "english"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "application", value: "StatusGalactic"),
        ]
        guard let url = components.url else { throw HTTPError.invalidURL }

        let data = try await session.getData(from: url, userAgent: userAgent)
        guard let payload = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let preds = payload["predictions"] as? [[String: Any]]
        else { return nil }

        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM-dd HH:mm"
        parser.timeZone = TimeZone(identifier: "UTC")

        let events: [TideEvent] = preds.compactMap { row -> TideEvent? in
            guard
                let t = row["t"] as? String, let date = parser.date(from: t),
                let v = row["v"] as? String, let height = Double(v),
                let type = row["type"] as? String,
                let kind = TideEvent.Kind(rawValue: type)
            else { return nil }
            return TideEvent(time: date, heightFt: height, kind: kind)
        }

        return Tides(
            stationId: station.id,
            stationName: station.name,
            distanceKm: distanceKm,
            events: events.sorted { $0.time < $1.time }
        )
    }
}
