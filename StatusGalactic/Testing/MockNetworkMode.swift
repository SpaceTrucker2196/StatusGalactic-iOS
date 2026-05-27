import Foundation
import CoreLocation

/// Test-only network mocking. Activated by launching the app with the
/// `-UITEST_MOCK_NETWORK` launch argument; intercepts every
/// `URLSession.shared` request via `GalacticMockURLProtocol` and returns canned
/// JSON / text bodies for the three fixture locations in
/// `MockNetworkFixtures`. Off by default outside that flag, so the
/// production network path is never touched.
///
/// Sibling to `ScreenshotMode` — same gating pattern, different purpose:
///   - `ScreenshotMode` seeds an in-memory hero brief and skips refresh.
///   - `MockNetworkMode` lets the real `BriefViewModel.load` flow run,
///     intercepting outbound HTTP. Useful for UI tests that verify
///     "select source X → UI shows location-X's weather" wiring.
///
/// They can both be active simultaneously, but the typical case is
/// MockNetworkMode alone for source-picker / weather-route tests.
enum MockNetworkMode {

    /// Keep in sync with the test target.
    static let launchArgument = "-UITEST_MOCK_NETWORK"

    static var isActive: Bool {
        ProcessInfo.processInfo.arguments.contains(launchArgument)
    }

    /// Default "Me" coordinates when no callsign is selected. Picked to
    /// not collide with any of the three callsign-pinned fixtures so a
    /// test can verify the picker switches between four distinct
    /// surfaces (Me / W1AW / VE3XYZ / KC1HBI).
    static let defaultLocation = CLLocation(latitude: 45.68, longitude: -111.04) // Bozeman, MT

    /// URLSession that production clients should use — `.shared` in
    /// normal runs, an ephemeral session wired up with
    /// `GalacticMockURLProtocol` under `-UITEST_MOCK_NETWORK`. iOS does
    /// not reliably honor `URLProtocol.registerClass` for
    /// `URLSession.shared`, so we plumb a session through explicitly
    /// rather than relying on the global registry.
    static let sessionForClients: URLSession = {
        guard isActive else { return .shared }
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [GalacticMockURLProtocol.self]
        config.timeoutIntervalForRequest = 10
        return URLSession(configuration: config)
    }()

    /// Register the URL protocol and pre-seed the in-memory state the
    /// app reads at launch. Idempotent — safe to call multiple times.
    @MainActor
    static func applyIfActive(
        location: LocationManager,
        callsigns: CallsignStore,
        config: ClientConfig
    ) {
        guard isActive else { return }

        URLProtocol.registerClass(GalacticMockURLProtocol.self)

        // Pre-populate "Me" location so the Brief tab can load without
        // the system location-permission dialog. Tests skip the
        // `requestPermissionIfNeeded` call under MockNetworkMode.
        location.lastLocation = defaultLocation
        location.authorizationStatus = .authorizedWhenInUse

        // A configured user-agent + API key so the clients construct
        // valid URLs; GalacticMockURLProtocol doesn't actually authenticate.
        if config.userAgent.isEmpty {
            config.userAgent = "StatusGalactic-UITest/1.0 (test@example.com)"
        }
        if config.aprsAPIKey.isEmpty {
            config.aprsAPIKey = "test-mock-key"
        }

        // Three callsigns pinned to fixture locations. Selecting one
        // from the Brief tab's source picker resolves to the mocked
        // lat/lng and then renders that location's weather.
        if callsigns.callsigns.isEmpty {
            for entry in MockNetworkFixtures.allByCall {
                _ = callsigns.add(entry.callsign,
                                  label: entry.locationLabel,
                                  notes: "")
            }
        }
    }
}
