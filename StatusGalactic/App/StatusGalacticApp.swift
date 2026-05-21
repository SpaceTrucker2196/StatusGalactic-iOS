import SwiftUI

@main
struct StatusGalacticApp: App {
    @State private var location = LocationManager()
    @State private var callsigns = CallsignStore()
    @State private var config = ClientConfig()
    @State private var notifications = NotificationManager()
    @State private var aprsMessages = APRSMessageStore()
    @State private var aprsStationLog = APRSStationLogStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(location)
                .environment(callsigns)
                .environment(config)
                .environment(notifications)
                .environment(aprsMessages)
                .environment(aprsStationLog)
                .task {
                    await notifications.refreshAuthorization()
                }
        }
    }
}
