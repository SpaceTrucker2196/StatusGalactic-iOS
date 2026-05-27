import XCTest
@testable import StatusGalactic

/// Unit tests for the `MockNetworkFixtures` data + the production
/// clients' parse paths. Uses the test target's pre-existing
/// `MockURLProtocol` (`StatusGalacticTests/Mocks/MockURLProtocol.swift`)
/// — register routes pointing at our fixtures, then exercise the real
/// `NWSClient` / `APRSClient` against the route table.
///
/// The app target ships its own `GalacticMockURLProtocol` for **UI**
/// tests (registered in `MockNetworkMode.applyIfActive`). The two
/// classes are intentionally distinct so this `@testable import` of
/// the test-side class isn't shadowed by the app-side one.
final class MockNetworkTests: XCTestCase {

    private var session: URLSession!

    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
        session = URLSession.mock(timeoutInterval: 4)

        // Wire each fixture's URLs through to `respond(to:)` in the
        // app-target `GalacticMockURLProtocol`, so unit tests + UI
        // tests share one source of truth for canned responses.
        MockURLProtocol.register(when: { _ in true }) { req in
            let url = req.url ?? URL(string: "https://invalid.test")!
            let (status, body, mime) = GalacticMockURLProtocol.respond(to: url)
            let resp = HTTPURLResponse(
                url: url,
                statusCode: status,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": mime]
            )!
            return (resp, body)
        }
    }

    override func tearDown() {
        MockURLProtocol.reset()
        session.invalidateAndCancel()
        session = nil
        super.tearDown()
    }

    func testDirectSessionHitsMockProtocol() async throws {
        let url = URL(string: "https://api.weather.gov/points/45.6800,-111.0400")!
        let (data, response) = try await session.data(from: url)
        let http = response as! HTTPURLResponse
        XCTAssertEqual(http.statusCode, 200)
        XCTAssertGreaterThan(data.count, 0)
    }

    func testAPRSFiLookupHitsFixtureForW1AW() async throws {
        let client = APRSClient(
            session: session,
            userAgent: "Test/1.0",
            apiKey: "test-key"
        )
        let fix = try await client.locate("W1AW")
        XCTAssertEqual(fix.lat, MockNetworkFixtures.w1aw.lat, accuracy: 0.001)
        XCTAssertEqual(fix.lng, MockNetworkFixtures.w1aw.lng, accuracy: 0.001)
    }

    func testNWSReturnsNewingtonForW1AWCoords() async throws {
        let client = NWSClient(session: session, userAgent: "Test/1.0")
        let weather = try await client.fetchEarthWeather(
            lat: MockNetworkFixtures.w1aw.lat,
            lng: MockNetworkFixtures.w1aw.lng
        )
        XCTAssertEqual(weather.periods.first?.temperature, 64,
                       "Mock NWS should report 64°F for Newington (W1AW).")
        XCTAssertEqual(weather.periods.first?.shortForecast, "Cloudy")
        XCTAssertEqual(weather.locationName, "Newington, CT")
    }

    func testNWSReturnsTorontoForVE3XYZCoords() async throws {
        let client = NWSClient(session: session, userAgent: "Test/1.0")
        let weather = try await client.fetchEarthWeather(
            lat: MockNetworkFixtures.ve3xyz.lat,
            lng: MockNetworkFixtures.ve3xyz.lng
        )
        XCTAssertEqual(weather.periods.first?.temperature, 58)
        XCTAssertEqual(weather.periods.first?.shortForecast, "Light Rain")
    }

    func testNWSReturnsPhoenixForKC1HBICoords() async throws {
        let client = NWSClient(session: session, userAgent: "Test/1.0")
        let weather = try await client.fetchEarthWeather(
            lat: MockNetworkFixtures.kc1hbi.lat,
            lng: MockNetworkFixtures.kc1hbi.lng
        )
        XCTAssertEqual(weather.periods.first?.temperature, 92)
        XCTAssertEqual(weather.periods.first?.shortForecast, "Sunny")
    }

    func testNWSFallsBackToBozemanForUnknownCoords() async throws {
        let client = NWSClient(session: session, userAgent: "Test/1.0")
        let weather = try await client.fetchEarthWeather(lat: 45.68, lng: -111.04)
        XCTAssertEqual(weather.periods.first?.temperature, 72)
        XCTAssertEqual(weather.periods.first?.shortForecast, "Mostly Sunny")
    }
}
