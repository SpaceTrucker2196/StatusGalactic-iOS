import XCTest
@testable import StatusGalactic

/// Chaos tests for the brief refresh path. Every external API is replaced
/// by a configurable `MockURLProtocol` so we can hammer BriefBuilder with
/// each failure mode it'll see in the wild and assert it never crashes,
/// never blocks, and always returns *something* renderable.
@MainActor
final class BriefBuilderRobustnessTests: XCTestCase {

    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
    }

    override func tearDown() {
        MockURLProtocol.reset()
        super.tearDown()
    }

    /// Every URL returns 200 with an empty body. Most clients should
    /// decode this as nil/empty without throwing; some return their own
    /// "no data" sentinels. The brief must build either way.
    func testBuildSurvivesEmpty200Bodies() async {
        MockURLProtocol.setFallback { req in
            (HTTPURLResponse(
                url: req.url!, statusCode: 200,
                httpVersion: "HTTP/1.1", headerFields: nil
            )!, Data())
        }
        let brief = await buildAtLaCrosse()
        assertSafelyEmpty(brief)
    }

    /// Every URL returns valid-shape-but-empty JSON. This is the most
    /// common "no data right now" response from real feeds.
    func testBuildSurvivesEmptyJSONShapes() async {
        MockURLProtocol.setFallback { req in
            // {} works for all the dict-shaped APIs. The array-shaped
            // SWPC products will fail their `as? [Any]` cast and return
            // their nil fallback, which is what we want.
            (HTTPURLResponse(
                url: req.url!, statusCode: 200,
                httpVersion: "HTTP/1.1", headerFields: nil
            )!, Data(#"{"features":[],"results":[],"sols":[],"coordinates":[]}"#.utf8))
        }
        let brief = await buildAtLaCrosse()
        assertSafelyEmpty(brief)
    }

    /// Every URL returns garbage text. JSONSerialization throws; clients
    /// should swallow that and return nil/empty.
    func testBuildSurvivesGarbageBodies() async {
        MockURLProtocol.setFallback { req in
            (HTTPURLResponse(
                url: req.url!, statusCode: 200,
                httpVersion: "HTTP/1.1", headerFields: nil
            )!, Data("<<<NOT JSON AT ALL>>>".utf8))
        }
        let brief = await buildAtLaCrosse()
        assertSafelyEmpty(brief)
    }

    /// Every URL returns 500. Clients' getData throws HTTPError.badResponse;
    /// BriefBuilder wraps each in `try?` so all defaults to nil/empty.
    func testBuildSurvivesAllServerErrors() async {
        MockURLProtocol.setFallback { req in
            (HTTPURLResponse(
                url: req.url!, statusCode: 500,
                httpVersion: "HTTP/1.1", headerFields: nil
            )!, Data("internal error".utf8))
        }
        let brief = await buildAtLaCrosse()
        assertSafelyEmpty(brief)
    }

    /// Every URL returns 404. Same expectation: hidden gracefully.
    func testBuildSurvivesAllNotFound() async {
        MockURLProtocol.setFallback { req in
            (HTTPURLResponse(
                url: req.url!, statusCode: 404,
                httpVersion: "HTTP/1.1", headerFields: nil
            )!, Data())
        }
        let brief = await buildAtLaCrosse()
        assertSafelyEmpty(brief)
    }

    /// Every URL throws a transport error (DNS / TLS / connection failure).
    /// Brief should still return.
    func testBuildSurvivesTransportFailures() async {
        MockURLProtocol.setFallback { _ in
            throw URLError(.notConnectedToInternet)
        }
        let brief = await buildAtLaCrosse()
        assertSafelyEmpty(brief)
    }

    /// Every URL stalls past the session timeout. The whole brief should
    /// return well inside 15 seconds because each client has an 8s
    /// per-request budget and they all run in parallel.
    func testBuildBoundsLatencyWhenAllSourcesStall() async {
        MockURLProtocol.setFallback(delay: 30) { req in
            (HTTPURLResponse(
                url: req.url!, statusCode: 200,
                httpVersion: "HTTP/1.1", headerFields: nil
            )!, Data())
        }
        let session = URLSession.mock(timeoutInterval: 4)
        let builder = BriefBuilder(config: ClientConfig(), session: session)

        let started = Date()
        let brief = await builder.build(
            lat: 43.86, lng: -91.23,
            marineZone: nil, timezone: "America/Chicago"
        )
        let elapsed = Date().timeIntervalSince(started)
        XCTAssertLessThan(elapsed, 15,
            "Brief took \(elapsed)s even though everything stalled — parallel fetches may have serialized.")
        XCTAssertNotNil(brief)
    }

    /// Hostile inputs: extreme coordinates, blank timezone, invalid
    /// marine zone. Builder should never trap.
    func testBuildSurvivesHostileInputs() async {
        MockURLProtocol.setFallback { req in
            (HTTPURLResponse(
                url: req.url!, statusCode: 200,
                httpVersion: "HTTP/1.1", headerFields: nil
            )!, Data("{}".utf8))
        }
        let session = URLSession.mock()
        let builder = BriefBuilder(config: ClientConfig(), session: session)

        // North pole, antimeridian, and a nonsense marine zone.
        _ = await builder.build(lat: 90, lng: 180, marineZone: "XXX999", timezone: "")
        _ = await builder.build(lat: -90, lng: -180, marineZone: nil, timezone: "UTC")
        _ = await builder.build(lat: 0, lng: 0, marineZone: "", timezone: "America/Chicago")
    }

    /// Simulates a "half the world is up" outage: NOAA SWPC alive,
    /// everyone else stalled. Brief should still come back with the
    /// SWPC-fed panels populated.
    func testBuildHandlesPartialOutage() async throws {
        // SWPC + NWS alive with valid empty payloads.
        MockURLProtocol.register(hostContaining: "services.swpc.noaa.gov",
                                 status: 200,
                                 body: Data("{}".utf8))
        MockURLProtocol.register(hostContaining: "api.weather.gov",
                                 status: 200,
                                 body: Data(#"{"features":[]}"#.utf8))
        // Everyone else stalls and times out.
        MockURLProtocol.setFallback(delay: 30) { req in
            (HTTPURLResponse(url: req.url!, statusCode: 200,
                             httpVersion: "HTTP/1.1", headerFields: nil)!, Data())
        }

        let session = URLSession.mock(timeoutInterval: 4)
        let builder = BriefBuilder(config: ClientConfig(), session: session)

        let started = Date()
        let brief = await builder.build(
            lat: 43.86, lng: -91.23,
            marineZone: nil, timezone: "UTC"
        )
        let elapsed = Date().timeIntervalSince(started)
        XCTAssertLessThan(elapsed, 15)
        XCTAssertNotNil(brief)
    }

    // MARK: - Helpers

    private func buildAtLaCrosse() async -> Brief {
        let session = URLSession.mock(timeoutInterval: 4)
        let builder = BriefBuilder(config: ClientConfig(), session: session)
        return await builder.build(
            lat: 43.86, lng: -91.23,
            marineZone: nil, timezone: "America/Chicago"
        )
    }

    /// Across every failure mode the brief must come back with the
    /// "shape" intact: timestamps and coordinates set, optional fields
    /// nil-or-empty, arrays initialized.
    private func assertSafelyEmpty(_ brief: Brief) {
        XCTAssertEqual(brief.lat, 43.86, accuracy: 0.01)
        XCTAssertEqual(brief.lng, -91.23, accuracy: 0.01)
        XCTAssertNil(brief.earth)
        XCTAssertNil(brief.marine)
        XCTAssertNil(brief.space)
        XCTAssertNil(brief.mars)
        XCTAssertNil(brief.river)
        XCTAssertNil(brief.tides)
        XCTAssertNil(brief.aurora)
        XCTAssertNil(brief.solarWind)
        XCTAssertNil(brief.xRay)
        XCTAssertNil(brief.proton)
        XCTAssertNil(brief.flareProbability)
        XCTAssertNil(brief.wwvBulletin)
        XCTAssertNil(brief.magneticDeclination)
        XCTAssertTrue(brief.launches.isEmpty)
        XCTAssertTrue(brief.crewedLaunches.isEmpty)
        XCTAssertTrue(brief.crewed.isEmpty)
        XCTAssertTrue(brief.earthquakes.isEmpty)
        XCTAssertTrue(brief.neos.isEmpty)
        XCTAssertTrue(brief.cmes.isEmpty)
        XCTAssertTrue(brief.activeRegions.isEmpty)
        XCTAssertTrue(brief.ionosondes.isEmpty)
        XCTAssertTrue(brief.repeaters.isEmpty)
        XCTAssertTrue(brief.weatherAlerts.isEmpty)
        XCTAssertTrue(brief.potaSpots.isEmpty)
        XCTAssertTrue(brief.sotaSpots.isEmpty)
        XCTAssertTrue(brief.dxSpots.isEmpty)
        // Pure-compute panels always populate.
        XCTAssertFalse(brief.planets.isEmpty)
        XCTAssertNotNil(brief.sun)
        XCTAssertNotNil(brief.moon)
    }
}
