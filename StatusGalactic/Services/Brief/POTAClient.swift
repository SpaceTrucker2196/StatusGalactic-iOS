import Foundation

/// Parks On The Air spot feed. POTA publishes the full set of active spots
/// at `https://api.pota.app/spot/`. Anonymous JSON; rolls about every minute.
///
/// Per-spot field names follow the POTA API conventions; we tolerate variants
/// (`spotId` vs `id`, `frequency` as either Double or String, etc.).
struct POTAClient {
    let session: URLSession
    let userAgent: String

    init(session: URLSession = .shared, userAgent: String) {
        self.session = session
        self.userAgent = userAgent
    }

    static let url = URL(string: "https://api.pota.app/spot/")!

    /// Spots sorted by distance from the viewer ascending, capped to `limit`.
    /// Spots without coordinates fall to the bottom (still useful to know an
    /// activation is happening even if we can't draw the distance).
    func fetchRecent(
        viewerLat: Double?, viewerLng: Double?, limit: Int = 8
    ) async throws -> [POTASpot] {
        let data = try await session.getData(from: Self.url, userAgent: userAgent, timeout: 8)
        guard let rows = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }
        var spots = rows.compactMap { Self.parse($0) }
        if let lat = viewerLat, let lng = viewerLng {
            spots = spots.map { spot in
                var s = spot
                if let sl = s.latitude, let slo = s.longitude {
                    s.distanceKm = haversineKm(lat1: lat, lng1: lng, lat2: sl, lng2: slo)
                }
                return s
            }
        }
        return spots
            .sorted { ($0.distanceKm ?? .infinity) < ($1.distanceKm ?? .infinity) }
            .prefix(limit)
            .map { $0 }
    }

    /// Visible for tests.
    static func parse(_ raw: [String: Any]) -> POTASpot? {
        guard let activator = (raw["activator"] as? String)
                ?? (raw["Activator"] as? String),
              let park = (raw["reference"] as? String)
                ?? (raw["Reference"] as? String)
        else { return nil }

        let spotId = (raw["spotId"] as? Int)
            ?? (raw["spotID"] as? Int)
            ?? (raw["id"] as? Int)
            ?? (raw["spotId"] as? String).flatMap(Int.init)
            ?? 0

        let parkName = (raw["name"] as? String)
            ?? (raw["parkName"] as? String)
            ?? park

        let freq = Self.parseDouble(raw["frequency"])
            ?? Self.parseDouble(raw["frequencyKHz"])
            ?? 0

        let mode = (raw["mode"] as? String) ?? "—"
        let spotTime = Self.parseTime(raw["spotTime"] ?? raw["timestamp"] ?? "")
            ?? Date()

        let lat = Self.parseDouble(raw["latitude"])
            ?? Self.doubleFromArray(raw["latlng"], at: 0)
        let lng = Self.parseDouble(raw["longitude"])
            ?? Self.doubleFromArray(raw["latlng"], at: 1)

        let location = raw["locationDesc"] as? String
        let comments = raw["comments"] as? String

        return POTASpot(
            spotId: spotId,
            activator: activator,
            parkRef: park,
            parkName: parkName,
            frequencyKHz: freq,
            mode: mode,
            spotTime: spotTime,
            latitude: lat,
            longitude: lng,
            locationDesc: location,
            comments: comments,
            distanceKm: nil
        )
    }

    private static func parseDouble(_ any: Any?) -> Double? {
        if let d = any as? Double { return d }
        if let i = any as? Int { return Double(i) }
        if let s = any as? String { return Double(s) }
        return nil
    }

    private static func doubleFromArray(_ any: Any?, at index: Int) -> Double? {
        guard let any else { return nil }
        if let arr = any as? [Double], index < arr.count { return arr[index] }
        if let arr = any as? [Any], index < arr.count { return parseDouble(arr[index]) }
        return nil
    }

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
    private static let spaceFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        f.timeZone = TimeZone(identifier: "UTC")
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private static func parseTime(_ v: Any) -> Date? {
        guard let s = v as? String, !s.isEmpty else { return nil }
        if let d = isoFractional.date(from: s) { return d }
        if let d = isoPlain.date(from: s) { return d }
        if let d = spaceFmt.date(from: s) { return d }
        return nil
    }
}

