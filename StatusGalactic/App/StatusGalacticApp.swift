import SwiftUI

@main
struct StatusGalacticApp: App {
    @State private var location = LocationManager()
    @State private var callsigns = CallsignStore()
    @State private var config = ClientConfig()
    @State private var notifications = NotificationManager()
    @State private var aprsMessages = APRSMessageStore()
    @State private var aprsStationLog = APRSStationLogStore()
    @State private var brief = BriefViewModel()

    init() {
        // No-op outside of `-UITEST_SCREENSHOT_MODE`. Inside it, this seeds
        // a deterministic hero brief + APRS state so screenshot captures
        // don't depend on network, location prompts, or real API keys.
        let loc = LocationManager()
        let cfg = ClientConfig()
        let cs = CallsignStore()
        let msgs = APRSMessageStore()
        let bvm = BriefViewModel()
        MainActor.assumeIsolated {
            ScreenshotMode.applyIfActive(
                config: cfg, location: loc, brief: bvm,
                callsigns: cs, aprsMessages: msgs
            )
        }
        _location = State(wrappedValue: loc)
        _config = State(wrappedValue: cfg)
        _callsigns = State(wrappedValue: cs)
        _aprsMessages = State(wrappedValue: msgs)
        _brief = State(wrappedValue: bvm)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(brief: brief)
                .environment(location)
                .environment(callsigns)
                .environment(config)
                .environment(notifications)
                .environment(aprsMessages)
                .environment(aprsStationLog)
                .task {
                    await notifications.refreshAuthorization()
                    await ImageCache.shared.purgeExpired()
                }
        }
    }
}
