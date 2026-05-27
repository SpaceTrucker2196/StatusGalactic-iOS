import Foundation

/// URLProtocol subclass that intercepts every request through
/// `URLSession.shared` and answers from `MockNetworkFixtures` when the
/// URL matches a known pattern. Anything we don't have a fixture for
/// returns an empty 200 — the brief renders any section it has data
/// for and tolerates empty / missing data on the rest.
///
/// Registered globally by `MockNetworkMode.applyIfActive(…)` so all
/// clients that use the default shared session (every Brief data
/// client + APRSClient) automatically route through here.
final class GalacticMockURLProtocol: URLProtocol {

    override class func canInit(with request: URLRequest) -> Bool {
        // Intercept everything; non-mocked URLs fall through to the
        // catch-all in `startLoading`.
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let url = request.url ?? URL(string: "about:blank")!
        let (status, body, mime) = GalacticMockURLProtocol.respond(to: url)
        // Debug breadcrumb (only visible in test logs).
        print("[GalacticMockURLProtocol] \(url.absoluteString) → \(status) (\(body?.count ?? 0) bytes)")

        let response = HTTPURLResponse(
            url: url,
            statusCode: status,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": mime]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        if let data = body {
            client?.urlProtocol(self, didLoad: data)
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() { /* no-op */ }

    // MARK: - Router

    /// Exposed to the test target so `MockNetworkTests` can register a
    /// single route that delegates to the same fixture lookup the UI
    /// tests use — one source of truth for mock responses.
    static func respond(to url: URL) -> (Int, Data?, String) {
        let host = url.host ?? ""
        let path = url.path
        let query = url.query ?? ""

        // ----- aprs.fi callsign lookup -----
        // `https://api.aprs.fi/api/get?name=W1AW&what=loc&apikey=…&format=json`
        if host.contains("aprs.fi") {
            if let name = parameter("name", from: query),
               let fixture = MockNetworkFixtures.byCall[name.uppercased()] {
                return (200, fixture.aprsFiResponseJSON.data(using: .utf8), "application/json")
            }
            return (200, MockNetworkFixtures.aprsNotFoundJSON.data(using: .utf8), "application/json")
        }

        // ----- NWS gridpoint lookup -----
        // `https://api.weather.gov/points/{lat},{lng}`
        if host.contains("api.weather.gov") && path.hasPrefix("/points/") {
            let coords = String(path.dropFirst("/points/".count))
            if let fixture = MockNetworkFixtures.fixture(forNWSPointsPath: coords) {
                return (200, fixture.nwsPointsResponseJSON.data(using: .utf8), "application/geo+json")
            }
            // Default "Me" location.
            return (200, MockNetworkFixtures.bozeman.nwsPointsResponseJSON.data(using: .utf8),
                    "application/geo+json")
        }

        // ----- NWS gridpoint forecast -----
        // `https://api.weather.gov/gridpoints/{wfo}/{x},{y}/forecast`
        if host.contains("api.weather.gov") && path.contains("/gridpoints/") && path.hasSuffix("/forecast") {
            if let fixture = MockNetworkFixtures.fixture(forGridpointPath: path) {
                return (200, fixture.nwsForecastResponseJSON.data(using: .utf8),
                        "application/geo+json")
            }
            return (200, MockNetworkFixtures.bozeman.nwsForecastResponseJSON.data(using: .utf8),
                    "application/geo+json")
        }

        // ----- NWS alerts (active) -----
        if host.contains("api.weather.gov") && path.hasPrefix("/alerts") {
            return (200, MockNetworkFixtures.emptyAlertsJSON.data(using: .utf8),
                    "application/geo+json")
        }

        // ----- SWPC space weather (any product) -----
        if host.contains("swpc.noaa.gov") {
            return (200, MockNetworkFixtures.swpcStubResponse(forPath: path),
                    "application/json")
        }

        // ----- Marine bulletin -----
        if host.contains("tgftp.nws.noaa.gov") {
            return (200, MockNetworkFixtures.marineBulletinTextStub.data(using: .utf8),
                    "text/plain")
        }

        // ----- Everything else: empty 200 -----
        // The brief tolerates missing optional sections; this keeps the
        // tests from caring about every long-tail endpoint.
        return (200, Data(), "application/octet-stream")
    }

    private static func parameter(_ name: String, from query: String) -> String? {
        for pair in query.split(separator: "&") {
            let kv = pair.split(separator: "=", maxSplits: 1)
            if kv.count == 2, kv[0] == name {
                return kv[1]
                    .replacingOccurrences(of: "+", with: " ")
                    .removingPercentEncoding
            }
        }
        return nil
    }
}
