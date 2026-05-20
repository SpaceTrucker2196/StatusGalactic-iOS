import SwiftUI

@main
struct StatusGalacticWatchApp: App {
    @State private var location = LocationManager()
    @State private var config = ClientConfig()

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environment(location)
                .environment(config)
        }
    }
}
