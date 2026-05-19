import SwiftUI

@main
struct StatusGalacticApp: App {
    @State private var location = LocationManager()
    @State private var callsigns = CallsignStore()
    @State private var server = ServerConfig()
    @State private var notifications = NotificationManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(location)
                .environment(callsigns)
                .environment(server)
                .environment(notifications)
                .task {
                    await notifications.refreshAuthorization()
                }
        }
    }
}
