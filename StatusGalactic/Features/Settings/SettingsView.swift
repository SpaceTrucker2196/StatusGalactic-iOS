import SwiftUI
import CoreLocation

struct SettingsView: View {
    @Environment(ServerConfig.self) private var server
    @Environment(LocationManager.self) private var location
    @Environment(NotificationManager.self) private var notifications

    var body: some View {
        @Bindable var server = server
        @Bindable var notifications = notifications

        NavigationStack {
            Form {
                notificationsSection

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

    @ViewBuilder
    private var notificationsSection: some View {
        @Bindable var notifications = notifications

        Section {
            Toggle("Golden hour reminders", isOn: $notifications.goldenHourEnabled)
                .onChange(of: notifications.goldenHourEnabled) {
                    handleNotifChange()
                }
            Toggle("Astronomical dusk reminders", isOn: $notifications.astronomicalDuskEnabled)
                .onChange(of: notifications.astronomicalDuskEnabled) {
                    handleNotifChange()
                }
            if let next = notifications.nextGoldenHour, notifications.goldenHourEnabled {
                LabeledContent("Next golden hour") {
                    Text(next, style: .relative)
                        .foregroundStyle(.secondary)
                }
            }
            if let next = notifications.nextAstroDusk, notifications.astronomicalDuskEnabled {
                LabeledContent("Next astro dusk") {
                    Text(next, style: .relative)
                        .foregroundStyle(.secondary)
                }
            }
            if notifications.authorizationStatus == .denied {
                Label(
                    "Notifications denied. Enable in iOS Settings.",
                    systemImage: "exclamationmark.triangle"
                )
                .foregroundStyle(.orange)
                .font(.caption)
            }
        } header: {
            Text("Notifications")
        } footer: {
            Text("Schedules up to 14 days of alerts at your last known location. Times computed locally; precise events come from the backend.")
                .font(.caption)
        }
    }

    private func handleNotifChange() {
        Task {
            if notifications.goldenHourEnabled || notifications.astronomicalDuskEnabled {
                if notifications.authorizationStatus == .notDetermined {
                    _ = await notifications.requestAuthorization()
                }
                if let loc = location.lastLocation {
                    await notifications.reschedule(
                        latitude: loc.coordinate.latitude,
                        longitude: loc.coordinate.longitude
                    )
                }
            } else {
                notifications.cancelAll()
            }
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
