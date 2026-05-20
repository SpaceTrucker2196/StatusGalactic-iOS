import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            BriefView()
                .tabItem { Label("Brief", systemImage: "globe.americas.fill") }

            APRSView()
                .tabItem {
                    Label("APRS", systemImage: "antenna.radiowaves.left.and.right.circle.fill")
                }

            CallsignsView()
                .tabItem {
                    Label("Callsigns", systemImage: "person.2.crop.square.stack.fill")
                }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(GalacticPalette.neonCyan)
    }
}

#Preview {
    ContentView()
        .environment(LocationManager())
        .environment(CallsignStore())
        .environment(ClientConfig())
        .environment(NotificationManager())
        .environment(APRSMessageStore())
}
