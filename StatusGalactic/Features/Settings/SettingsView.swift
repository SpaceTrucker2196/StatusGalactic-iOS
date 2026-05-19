import SwiftUI
import CoreLocation

struct SettingsView: View {
    @Environment(ServerConfig.self) private var server
    @Environment(LocationManager.self) private var location

    var body: some View {
        @Bindable var server = server

        NavigationStack {
            Form {
                Section("Server") {
                    TextField("Backend URL", text: $server.serverURLString)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Text("Default: \(ServerConfig.defaultURLString)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Marine zone (default)") {
                    TextField("e.g. GMZ033", text: $server.defaultMarineZone)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                    Text("Find your zone at weather.gov/marine. Leave blank if inland.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Location") {
                    LabeledContent("Permission") {
                        Text(authString)
                    }
                    if let loc = location.lastLocation {
                        LabeledContent("Last fix") {
                            Text(String(format: "%.4f, %.4f", loc.coordinate.latitude, loc.coordinate.longitude))
                                .font(.callout.monospacedDigit())
                        }
                    }
                    Button("Refresh location") {
                        location.requestLocation()
                    }
                }

                Section {
                    LabeledContent("App version") {
                        Text(Bundle.main.shortVersion)
                    }
                    Link(
                        "Backend repo",
                        destination: URL(string: "https://github.com/SpaceTrucker2196/weathergalactic")!
                    )
                    Link(
                        "iOS repo",
                        destination: URL(string: "https://github.com/SpaceTrucker2196/StatusGalactic-iOS")!
                    )
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
        }
    }

    private var authString: String {
        switch location.authorizationStatus {
        case .notDetermined: return "Not requested"
        case .restricted: return "Restricted"
        case .denied: return "Denied (open iOS Settings)"
        case .authorizedWhenInUse: return "When in use"
        case .authorizedAlways: return "Always"
        @unknown default: return "Unknown"
        }
    }
}

private extension Bundle {
    var shortVersion: String {
        (infoDictionary?["CFBundleShortVersionString"] as? String) ?? "0.0.0"
    }
}
