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
            rootView
                .environment(location)
                .environment(callsigns)
                .environment(config)
                .environment(notifications)
                .environment(aprsMessages)
                .environment(aprsStationLog)
                // Force dark mode under screenshot mode so the App Store
                // gallery reads as one consistent neon scheme — otherwise
                // Callsigns + Settings (which use system Form/List
                // chrome) render light against the RF + Brief darks.
                .preferredColorScheme(ScreenshotMode.isActive ? .dark : nil)
                .task {
                    await notifications.refreshAuthorization()
                    await ImageCache.shared.purgeExpired()
                }
        }
    }

    /// Swap in the widget home-screen preview when the dedicated launch
    /// flag is set; otherwise the normal app shell. ScreenshotMode is
    /// already gating the seeded brief that the widget will render.
    @ViewBuilder
    private var rootView: some View {
        if WidgetHomeScreenPreview.isActive {
            WidgetHomeScreenPreview(
                entry: BriefWidgetEntry(
                    date: Date(),
                    brief: BriefWidgetEntryFactory.fromBriefViewModel(brief),
                    errorMessage: nil
                )
            )
        } else {
            ContentView(brief: brief)
        }
    }
}

/// Builds a `BriefWidgetEntry.brief` payload from the in-app
/// BriefViewModel's seeded state. Lives in the app target because
/// `BriefViewModel` isn't available to the widget extension.
enum BriefWidgetEntryFactory {
    @MainActor
    static func fromBriefViewModel(_ vm: BriefViewModel) -> Brief? {
        if case .loaded(let brief, _, _) = vm.state {
            return brief
        }
        return nil
    }
}
