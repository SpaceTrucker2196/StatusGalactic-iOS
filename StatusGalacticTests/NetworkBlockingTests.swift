import XCTest
@testable import StatusGalactic

/// Mock URLProtocol that returns a configurable body after a delay. Used to
/// hold each request open long enough for a parallel "is the main thread
/// still ticking?" probe to register evidence either way.
final class SlowMockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var delaySeconds: TimeInterval = 0.6
    nonisolated(unsafe) static var responseBody: Data = Data("{}".utf8)

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let url = request.url ?? URL(string: "https://invalid.test")!
        let body = Self.responseBody
        let delay = Self.delaySeconds
        DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self else { return }
            let response = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            self.client?.urlProtocol(self, didLoad: body)
            self.client?.urlProtocolDidFinishLoading(self)
        }
    }

    override func stopLoading() {}
}

extension URLSession {
    /// Ephemeral session that delays every request by `delaySeconds` and
    /// returns `body` from `SlowMockURLProtocol`. Useful for proving that
    /// the calling code yields the main thread during the wait.
    static func slowMock(delaySeconds: TimeInterval = 0.6,
                        body: Data = Data("{}".utf8)) -> URLSession {
        SlowMockURLProtocol.delaySeconds = delaySeconds
        SlowMockURLProtocol.responseBody = body
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [SlowMockURLProtocol.self]
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 30
        return URLSession(configuration: config)
    }
}

/// Thread-safe-ish counter incremented from MainActor. We only read+write
/// from MainActor so `nonisolated(unsafe)` is safe.
@MainActor
final class MainTickCounter {
    private(set) var value: Int = 0
    func increment() { value += 1 }
}

/// These tests prove the brief-refresh path and the individual data
/// clients yield the main thread during network I/O. We:
///
/// 1. Install a `SlowMockURLProtocol` that delays each response by
///    ~600 ms (longer than network handshake, short enough to keep tests
///    snappy).
/// 2. Schedule a 20 ms-cadence main-thread tick counter alongside the
///    fetch.
/// 3. After the fetch completes, assert the main thread accumulated
///    many ticks. A blocked main thread would accumulate zero (or one).
///
/// Threshold of 10 ticks ≈ 200 ms of liveness against a 600 ms wait
/// gives plenty of margin for CI jitter while still catching a real
/// regression where the main thread is pinned by network or decoding.
@MainActor
final class NetworkBlockingTests: XCTestCase {

    private func makeTicker(maxTicks: Int = 200) -> (counter: MainTickCounter, task: Task<Void, Never>) {
        let counter = MainTickCounter()
        let task = Task { @MainActor in
            for _ in 0..<maxTicks {
                if Task.isCancelled { return }
                counter.increment()
                try? await Task.sleep(nanoseconds: 20_000_000)
            }
        }
        return (counter, task)
    }

    func testBriefBuilderDoesNotBlockMainThread() async throws {
        // Empty-but-valid responses for every endpoint. Each client falls
        // back gracefully to nil/[] when the payload doesn't match, so the
        // brief builds and returns regardless.
        let session = URLSession.slowMock(delaySeconds: 0.6, body: Data("{}".utf8))
        let config = ClientConfig()
        let builder = BriefBuilder(config: config, session: session)

        let (counter, ticker) = makeTicker()
        defer { ticker.cancel() }

        _ = await builder.build(
            lat: 43.8, lng: -91.2,
            marineZone: nil,
            timezone: "UTC"
        )

        XCTAssertGreaterThan(
            counter.value, 10,
            "Main thread accumulated only \(counter.value) ticks during brief refresh — likely blocked on a sync network or decode."
        )
    }

    func testWeatherAlertsClientFetchDoesNotBlockMainThread() async throws {
        let session = URLSession.slowMock(
            delaySeconds: 0.6,
            body: #"{"features":[]}"#.data(using: .utf8)!
        )
        let client = WeatherAlertsClient(session: session, userAgent: "tests")

        let (counter, ticker) = makeTicker()
        defer { ticker.cancel() }

        _ = try await client.fetchActive(lat: 43.8, lng: -91.2)

        XCTAssertGreaterThan(counter.value, 10,
            "WeatherAlertsClient.fetchActive blocked the main thread.")
    }

    func testGOESClientFetchDoesNotBlockMainThread() async throws {
        let session = URLSession.slowMock(
            delaySeconds: 0.6,
            body: "[]".data(using: .utf8)!
        )
        let client = GOESParticleClient(session: session, userAgent: "tests")

        let (counter, ticker) = makeTicker()
        defer { ticker.cancel() }

        _ = try await client.fetchXRay()

        XCTAssertGreaterThan(counter.value, 10,
            "GOESParticleClient.fetchXRay blocked the main thread.")
    }

    func testIonosondeClientFetchDoesNotBlockMainThread() async throws {
        let session = URLSession.slowMock(
            delaySeconds: 0.6,
            body: "[]".data(using: .utf8)!
        )
        let client = IonosondeClient(session: session, userAgent: "tests")

        let (counter, ticker) = makeTicker()
        defer { ticker.cancel() }

        _ = try await client.fetchNearest(lat: 43.8, lng: -91.2)

        XCTAssertGreaterThan(counter.value, 10,
            "IonosondeClient.fetchNearest blocked the main thread.")
    }

    /// OVATION payloads are several hundred KB with thousands of grid
    /// cells. The parser walks the entire array — if it ever lands on the
    /// main thread it'd hitch the UI. This proves the iteration happens
    /// off-main even when the response body is non-trivial.
    func testOVATIONClientHandlesLargeBodyOffMainThread() async throws {
        let bigPayload = Self.fakeOVATIONPayload(rows: 5_000)
        let session = URLSession.slowMock(delaySeconds: 0.3, body: bigPayload)
        let client = OVATIONClient(session: session, userAgent: "tests")

        let (counter, ticker) = makeTicker()
        defer { ticker.cancel() }

        _ = try await client.fetch(lat: 43.8, lng: -91.2)

        XCTAssertGreaterThan(counter.value, 5,
            "OVATIONClient.fetch blocked the main thread while decoding a large grid.")
    }

    /// Generates a chunky OVATION-shaped JSON payload with `rows` grid
    /// cells so we can exercise the parser end-to-end. Real OVATION JSON
    /// is ~64K cells; 5K is enough to expose any main-thread pinning.
    private static func fakeOVATIONPayload(rows: Int) -> Data {
        var coords: [String] = []
        coords.reserveCapacity(rows)
        for i in 0..<rows {
            let lon = Double(i % 360)
            let lat = Double((i / 360) % 180 - 90)
            let prob = Int.random(in: 0...60)
            coords.append("[\(lon), \(lat), \(prob)]")
        }
        let json = """
        {
          "Observation Time": "2026-05-21T18:30:00Z",
          "Forecast Time": "2026-05-21T19:00:00Z",
          "coordinates": [\(coords.joined(separator: ","))]
        }
        """
        return json.data(using: .utf8)!
    }
}
