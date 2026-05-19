import SwiftUI

@main
struct StatusGalacticApp: App {
    @State private var location = LocationManager()
    @State private var callsigns = CallsignStore()
    @State private var server = ServerConfig()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(location)
                .environment(callsigns)
                .environment(server)
        }
    }
}
