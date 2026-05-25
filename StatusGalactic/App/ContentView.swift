import SwiftUI

struct ContentView: View {
    /// Lifted to ContentView so both the Brief and RF tabs read from the
    /// same model. The Brief tab drives refresh; RF reads + projects the
    /// ham-radio subset. Injected by the App so screenshot-mode seeding
    /// in `StatusGalacticApp.init` survives all the way through.
    @State var brief: BriefViewModel

    /// Track first-mount + last successful load so we can:
    ///   - kick off a refresh exactly once on app launch
    ///   - only re-fetch on background→foreground when the data is
    ///     actually old (avoiding "open the app, gray flash, color" loops)
    @State private var didInitialLoad = false
    @State private var lastLoadAt: Date = .distantPast

    @Environment(\.scenePhase) private var scenePhase
    @Environment(LocationManager.self) private var location
    @Environment(ClientConfig.self) private var config
    @Environment(NotificationManager.self) private var notifications

    /// Skip the foreground refresh entirely when we already loaded within
    /// this window. 5 minutes lines up with NWS/SWPC publish cadence.
    private let foregroundFreshness: TimeInterval = 5 * 60

    var body: some View {
        TabView {
            BriefView()
                .tabItem { Label("Brief", systemImage: "globe.americas.fill") }

            RFView()
                .tabItem {
                    Label("RF", systemImage: "antenna.radiowaves.left.and.right.circle.fill")
                }

            CallsignsView()
                .tabItem {
                    Label("Callsigns", systemImage: "person.2.crop.square.stack.fill")
                }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(GalacticPalette.neonCyan)
        .environment(brief)
        .task {
            if !didInitialLoad {
                didInitialLoad = true
                if ScreenshotMode.isActive { return }
                location.requestPermissionIfNeeded()
                await briefLoad()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Returning from background — refresh only if the data is
            // older than `foregroundFreshness`. Tab switches and sheet
            // dismissals stay in the same scene phase and don't trigger.
            if newPhase == .active && !ScreenshotMode.isActive {
                Task { await briefLoadIfStale() }
            }
        }
    }

    private func briefLoad() async {
        if brief.marineZone.isEmpty {
            brief.marineZone = config.defaultMarineZone
        }
        await brief.load(
            config: config,
            location: location.lastLocation,
            tz: TimeZone.current.identifier,
            notifications: notifications
        )
        lastLoadAt = Date()
    }

    private func briefLoadIfStale() async {
        if Date().timeIntervalSince(lastLoadAt) < foregroundFreshness {
            return
        }
        if case .loaded(_, let fetchedAt, _) = brief.state,
           Date().timeIntervalSince(fetchedAt) < foregroundFreshness {
            return
        }
        await briefLoad()
    }
}

#Preview {
    ContentView(brief: BriefViewModel())
        .environment(LocationManager())
        .environment(CallsignStore())
        .environment(ClientConfig())
        .environment(NotificationManager())
        .environment(APRSMessageStore())
}
