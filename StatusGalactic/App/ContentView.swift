import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            BriefView()
                .tabItem { Label("Brief", systemImage: "globe.americas.fill") }

            CallsignsView()
                .tabItem {
                    Label("Callsigns", systemImage: "antenna.radiowaves.left.and.right")
                }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

#Preview {
    ContentView()
        .environment(LocationManager())
        .environment(CallsignStore())
        .environment(ClientConfig())
        .environment(NotificationManager())
}
