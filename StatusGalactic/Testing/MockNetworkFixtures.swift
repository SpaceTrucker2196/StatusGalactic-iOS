import Foundation

/// Canned data for three pinned locations + a default "Me" location.
/// Each fixture carries everything the relevant network mock needs to
/// produce JSON that the production clients parse correctly:
///   - APRS.fi lookup → lat / lng + symbol + path
///   - NWS `/points/{lat,lng}` → gridpoint office + grid x/y forecast URL
///   - NWS `/gridpoints/{wfo}/{x,y}/forecast` → 6-period temperature +
///     shortForecast + windSpeed
///
/// The forecast bodies are short on purpose — we only need enough to
/// drive the visible UI strings the tests assert on.
struct MockNetworkFixture {
    let callsign: String          // "W1AW", "VE3XYZ", "KC1HBI"
    let locationLabel: String     // "Newington, CT"
    let lat: Double
    let lng: Double
    let wfo: String               // gridpoint office, e.g. "BOX"
    let gridX: Int
    let gridY: Int
    let temperatureF: Int         // first-period temp the UI should show
    let conditions: String        // first-period shortForecast
    let windSpeed: String         // e.g. "10 to 15 mph"

    /// URL-encoded `/points/{lat},{lng}` path that the NWS client hits
    /// before fetching the forecast. Used by the router to match a
    /// fixture by coordinate.
    var pointsPath: String {
        String(format: "%.4f,%.4f", lat, lng)
    }

    /// The forecast-path tail the points response advertises and the
    /// next NWS call requests. Used by the router to match the same
    /// fixture for the second hop.
    var forecastPath: String {
        "/gridpoints/\(wfo)/\(gridX),\(gridY)/forecast"
    }

    var aprsFiResponseJSON: String {
        """
        {
          "command": "get",
          "result": "ok",
          "what": "loc",
          "found": 1,
          "entries": [
            {
              "name": "\(callsign)",
              "type": "l",
              "time": "\(Int(Date().timeIntervalSince1970))",
              "lasttime": "\(Int(Date().timeIntervalSince1970))",
              "lat": "\(lat)",
              "lng": "\(lng)",
              "symbol": "/k",
              "srccall": "\(callsign)",
              "dstcall": "APRS",
              "comment": "mock-fixture: \(locationLabel)"
            }
          ]
        }
        """
    }

    var nwsPointsResponseJSON: String {
        """
        {
          "properties": {
            "gridId": "\(wfo)",
            "gridX": \(gridX),
            "gridY": \(gridY),
            "forecast": "https://api.weather.gov\(forecastPath)",
            "relativeLocation": {
              "properties": {
                "city": "\(locationLabel.components(separatedBy: ",").first ?? locationLabel)",
                "state": "\(locationLabel.components(separatedBy: ",").last?.trimmingCharacters(in: .whitespaces) ?? "")"
              }
            },
            "timeZone": "America/New_York"
          }
        }
        """
    }

    var nwsForecastResponseJSON: String {
        let now = ISO8601DateFormatter()
        now.formatOptions = [.withInternetDateTime]
        let start = now.string(from: Date())
        let end = now.string(from: Date().addingTimeInterval(6 * 3600))
        return """
        {
          "properties": {
            "periods": [
              {
                "number": 1,
                "name": "This Afternoon",
                "startTime": "\(start)",
                "endTime": "\(end)",
                "isDaytime": true,
                "temperature": \(temperatureF),
                "temperatureUnit": "F",
                "windSpeed": "\(windSpeed)",
                "windDirection": "SW",
                "shortForecast": "\(conditions)",
                "detailedForecast": "Mock fixture for \(locationLabel). \(conditions). Winds \(windSpeed) from the SW."
              },
              {
                "number": 2,
                "name": "Tonight",
                "startTime": "\(end)",
                "endTime": "\(end)",
                "isDaytime": false,
                "temperature": \(max(temperatureF - 18, 20)),
                "temperatureUnit": "F",
                "windSpeed": "5 to 10 mph",
                "windDirection": "W",
                "shortForecast": "Mostly Clear",
                "detailedForecast": "Mostly clear."
              }
            ]
          }
        }
        """
    }
}

enum MockNetworkFixtures {

    // MARK: - Pinned callsigns

    static let w1aw = MockNetworkFixture(
        callsign: "W1AW",
        locationLabel: "Newington, CT",
        lat: 41.7142,
        lng: -72.7270,
        wfo: "BOX",
        gridX: 71,
        gridY: 75,
        temperatureF: 64,
        conditions: "Cloudy",
        windSpeed: "8 to 12 mph"
    )

    static let ve3xyz = MockNetworkFixture(
        callsign: "VE3XYZ",
        locationLabel: "Toronto, ON",
        lat: 43.6532,
        lng: -79.3832,
        wfo: "BUF",
        gridX: 60,
        gridY: 100,
        temperatureF: 58,
        conditions: "Light Rain",
        windSpeed: "12 to 18 mph"
    )

    static let kc1hbi = MockNetworkFixture(
        callsign: "KC1HBI",
        locationLabel: "Phoenix, AZ",
        lat: 33.4484,
        lng: -112.0740,
        wfo: "PSR",
        gridX: 158,
        gridY: 60,
        temperatureF: 92,
        conditions: "Sunny",
        windSpeed: "5 to 10 mph"
    )

    /// Used when the brief loads with "Me" selected and no callsign —
    /// shares the same shape as the pinned fixtures so the router can
    /// fall through to it. Callsign is unused in this branch.
    static let bozeman = MockNetworkFixture(
        callsign: "",
        locationLabel: "Bozeman, MT",
        lat: 45.68,
        lng: -111.04,
        wfo: "TFX",
        gridX: 81,
        gridY: 161,
        temperatureF: 72,
        conditions: "Mostly Sunny",
        windSpeed: "10 to 15 mph"
    )

    static let allByCall: [MockNetworkFixture] = [w1aw, ve3xyz, kc1hbi]

    static let byCall: [String: MockNetworkFixture] = Dictionary(
        uniqueKeysWithValues: allByCall.map { ($0.callsign, $0) }
    )

    /// Match an incoming `/points/{lat},{lng}` request against the
    /// closest fixture. NWS rounds coordinates to 4 decimals on the
    /// request side, so we compare to fixture values with a 0.01°
    /// tolerance (~1.1 km — far below the natural distance between
    /// any pair of fixture locations).
    static func fixture(forNWSPointsPath path: String) -> MockNetworkFixture? {
        let comps = path.split(separator: ",")
        guard comps.count == 2,
              let lat = Double(comps[0]),
              let lng = Double(comps[1])
        else { return nil }

        for fx in [w1aw, ve3xyz, kc1hbi, bozeman]
        where abs(fx.lat - lat) < 0.01 && abs(fx.lng - lng) < 0.01 {
            return fx
        }
        return nil
    }

    /// Match an incoming `/gridpoints/{wfo}/{x,y}/forecast` against the
    /// fixture that advertised it on the previous hop.
    static func fixture(forGridpointPath path: String) -> MockNetworkFixture? {
        for fx in [w1aw, ve3xyz, kc1hbi, bozeman] where path.contains(fx.forecastPath) {
            return fx
        }
        return nil
    }

    // MARK: - APRS error envelope

    static let aprsNotFoundJSON = """
    {"command":"get","result":"ok","what":"loc","found":0,"entries":[]}
    """

    // MARK: - NWS alerts (always empty in mocks)

    static let emptyAlertsJSON = """
    {"type":"FeatureCollection","features":[],"title":"current watches, warnings, and advisories"}
    """

    // MARK: - SWPC stubs (one rough body per product type)

    static func swpcStubResponse(forPath path: String) -> Data {
        // The brief tolerates empty SWPC arrays. Returning a minimal
        // valid JSON array keeps parsing happy without dictating values.
        if path.contains("planetary_k_index") {
            return "[[\"time_tag\",\"kp\"],[\"2026-05-27 00:00:00\",\"2\"]]"
                .data(using: .utf8)!
        }
        if path.contains("solar-flux") || path.contains("radio") {
            return "[]".data(using: .utf8)!
        }
        return "[]".data(using: .utf8)!
    }

    // MARK: - Marine bulletin stub

    static let marineBulletinTextStub = """
    Coastal Waters Forecast — MOCK FIXTURE
    .TONIGHT...E winds 5 to 10 kt. Seas 2 ft. A slight chance of showers.
    .TOMORROW...SE winds 10 to 15 kt. Seas 2 to 4 ft.
    """
}
