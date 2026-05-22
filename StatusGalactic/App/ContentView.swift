import SwiftUI

struct ContentView: View {
    /// Lifted to ContentView so both the Brief and RF tabs read from the
    /// same model. The Brief tab drives refresh; RF reads + projects the
    /// ham-radio subset.
    @State private var brief = BriefViewModel()

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
