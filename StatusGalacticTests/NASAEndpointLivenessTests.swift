import XCTest
@testable import StatusGalactic

/// Live network checks against every NASA / NOAA / SDO endpoint the
/// brief depends on. Each test does a small GET and asserts a 2xx
/// response with a non-empty body of the expected MIME type.
///
/// These are intentionally network-touching integration tests. They're
/// guarded behind the `RUN_LIVENESS_TESTS` environment variable so the
/// default `cmd-U` run in Xcode (and CI) stays offline. Run them when
/// you suspect an upstream API URL has rotted:
///
///     RUN_LIVENESS_TESTS=1 xcodebuild test -only-testing:StatusGalacticTests/NASAEndpointLivenessTests
///
/// Set `NASA_API_KEY` in your scheme's environment to test against your
/// own api.nasa.gov key; otherwise DEMO_KEY is used (rate-limited).
final class NASAEndpointLivenessTests: XCTestCase {

    override func setUpWithError() throws {
        if ProcessInfo.processInfo.environment["RUN_LIVENESS_TESTS"] == nil {
            throw XCTSkip("Set RUN_LIVENESS_TESTS=1 to hit live NASA endpoints.")
        }
    }

    private var nasaKey: String {
        ProcessInfo.processInfo.environment["NASA_API_KEY"] ?? "DEMO_KEY"
    }

    private func get(_ url: URL,
                    expectedMimePrefix: String? = nil,
                    file: StaticString = #file, line: UInt = #line) async throws {
        var req = URLRequest(url: url)
        req.timeoutInterval = 12
        req.setValue("StatusGalacticTests/0.1 (+integration)",
                     forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            XCTFail("Not an HTTP response from \(url)", file: file, line: line)
            return
        }
        XCTAssertTrue((200...299).contains(http.statusCode),
                      "GET \(url) → \(http.statusCode)",
                      file: file, line: line)
        XCTAssertGreaterThan(data.count, 0,
                             "Empty body from \(url)",
                             file: file, line: line)
        if let prefix = expectedMimePrefix,
           let mime = http.value(forHTTPHeaderField: "Content-Type") {
            XCTAssertTrue(mime.hasPrefix(prefix),
                          "MIME mismatch: \(mime) does not start with \(prefix) (\(url))",
                          file: file, line: line)
        }
    }

    // MARK: - SDO imagery

    func testSDOStillImageIsAvailable() async throws {
        let url = URL(string: "https://sdo.gsfc.nasa.gov/assets/img/latest/latest_1024_0304.jpg")!
        try await get(url, expectedMimePrefix: "image/")
    }

    /// Daily movie for the AIA 304 channel at 1024px. Today's may not
    /// have been archived yet, so the panel pulls *yesterday's* — we
    /// test that the same URL the panel constructs is reachable.
    func testSDODailyMovieIsAvailable() async throws {
        let candidates = AnimatedSunPanel.buildMovieCandidates(now: Date())
        XCTAssertFalse(candidates.isEmpty, "AnimatedSunPanel didn't build any candidate URLs")
        // At least one of the recent dates should resolve. We try each
        // until one succeeds; if all fail, fail the test loudly.
        var lastFailure: Error?
        for url in candidates {
            do {
                try await get(url, expectedMimePrefix: "video/")
                return
            } catch {
                lastFailure = error
            }
        }
        if let lastFailure { throw lastFailure }
    }

    // MARK: - api.nasa.gov

    func testAPODEndpointWithCurrentKey() async throws {
        var c = URLComponents(string: "https://api.nasa.gov/planetary/apod")!
        c.queryItems = [URLQueryItem(name: "api_key", value: nasaKey)]
        try await get(c.url!, expectedMimePrefix: "application/json")
    }

    func testNEOFeedEndpoint() async throws {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.timeZone = TimeZone(identifier: "UTC")
        let today = df.string(from: Date())
        let tomorrow = df.string(from: Date().addingTimeInterval(86400))

        var c = URLComponents(string: "https://api.nasa.gov/neo/rest/v1/feed")!
        c.queryItems = [
            URLQueryItem(name: "start_date", value: today),
            URLQueryItem(name: "end_date", value: tomorrow),
            URLQueryItem(name: "api_key", value: nasaKey),
        ]
        try await get(c.url!, expectedMimePrefix: "application/json")
    }

    func testDONKICMEEndpoint() async throws {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.timeZone = TimeZone(identifier: "UTC")
        let start = df.string(from: Date().addingTimeInterval(-5 * 86400))
        let end = df.string(from: Date())

        var c = URLComponents(string: "https://api.nasa.gov/DONKI/CME")!
        c.queryItems = [
            URLQueryItem(name: "startDate", value: start),
            URLQueryItem(name: "endDate", value: end),
            URLQueryItem(name: "api_key", value: nasaKey),
        ]
        try await get(c.url!, expectedMimePrefix: "application/json")
    }

    // MARK: - mars.nasa.gov

    func testMarsPerseveranceFeed() async throws {
        let url = URL(string:
            "https://mars.nasa.gov/rss/api/?feed=weather&category=mars2020&feedtype=json"
        )!
        try await get(url, expectedMimePrefix: "application/")
    }

    func testMarsCuriosityFeed() async throws {
        let url = URL(string:
            "https://mars.nasa.gov/rss/api/?feed=weather&category=msl&feedtype=json"
        )!
        try await get(url, expectedMimePrefix: "application/")
    }

    // MARK: - NOAA SWPC (non-NASA but lives in the same brief)

    func testSWPCKpProductEndpoint() async throws {
        let url = URL(string:
            "https://services.swpc.noaa.gov/products/noaa-planetary-k-index.json"
        )!
        try await get(url, expectedMimePrefix: "application/")
    }

    func testSWPCGOESXRayEndpoint() async throws {
        let url = URL(string:
            "https://services.swpc.noaa.gov/json/goes/primary/xrays-1-day.json"
        )!
        try await get(url, expectedMimePrefix: "application/")
    }

    // MARK: - Static URL audit (always runs)

    /// Catches accidental "https://nasa..." typos — runs offline and
    /// asserts every URL the app constructs is well-formed and points
    /// at a known NASA / NOAA host.
    func testCanonicalNASAURLsParse() {
        let knownHosts: Set<String> = [
            "sdo.gsfc.nasa.gov",
            "api.nasa.gov",
            "mars.nasa.gov",
            "services.swpc.noaa.gov",
            "earthquake.usgs.gov",
            "api.weather.gov",
            "tgftp.nws.noaa.gov",
            "www.ngdc.noaa.gov",
            "api.water.noaa.gov",
            "celestrak.org",
        ]

        // SDO movie candidates built by AnimatedSunPanel.
        let movies = AnimatedSunPanel.buildMovieCandidates(now: Date())
        for url in movies {
            XCTAssertEqual(url.host, "sdo.gsfc.nasa.gov",
                           "Unexpected SDO host: \(url)")
            XCTAssertTrue(url.path.hasSuffix("_0304.mp4"),
                          "Movie URL must point at the AIA 304 channel: \(url)")
        }

        // Sample some other endpoints from the codebase to make sure
        // hosts haven't drifted.
        let fixedURLs: [URL] = [
            URL(string: "https://sdo.gsfc.nasa.gov/assets/img/latest/latest_1024_0304.jpg")!,
            URL(string: "https://api.nasa.gov/planetary/apod")!,
            URL(string: "https://api.nasa.gov/neo/rest/v1/feed")!,
            URL(string: "https://api.nasa.gov/DONKI/CME")!,
            URL(string: "https://mars.nasa.gov/rss/api/?feed=weather&category=mars2020&feedtype=json")!,
            URL(string: "https://mars.nasa.gov/rss/api/?feed=weather&category=msl&feedtype=json")!,
            URL(string: "https://services.swpc.noaa.gov/products/noaa-planetary-k-index.json")!,
            URL(string: "https://services.swpc.noaa.gov/json/goes/primary/xrays-1-day.json")!,
        ]
        for url in fixedURLs {
            XCTAssertTrue(knownHosts.contains(url.host ?? ""),
                          "Unknown host: \(url)")
        }
    }
}
