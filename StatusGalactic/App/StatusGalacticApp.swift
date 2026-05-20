import SwiftUI

@main
struct StatusGalacticApp: App {
    @State private var location = LocationManager()
    @State private var callsigns = CallsignStore()
    @State private var config = ClientConfig()
    @State private var notifications = NotificationManager()
    @State private var aprsMessages = APRSMessageStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(location)
                .environment(callsigns)
                .environment(config)
                .environment(notifications)
                .environment(aprsMessages)
                .task {
                    await notifications.refreshAuthorization()
                }
        }
    }
}
