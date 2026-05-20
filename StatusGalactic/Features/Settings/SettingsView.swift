import SwiftUI
import CoreLocation

struct SettingsView: View {
    @Environment(ClientConfig.self) private var config
    @Environment(LocationManager.self) private var location
    @Environment(NotificationManager.self) private var notifications

    var body: some View {
        @Bindable var config = config
        @Bindable var notifications = notifications

        NavigationStack {
            Form {
                notificationsSection

                Section("APRS") {
                    TextField("Your callsign (e.g. W9FJC)", text: $config.myCallsign)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .font(.firaCode(.body, weight: .semibold))
                        .foregroundStyle(GalacticPalette.neonCyan)
                    if !config.myCallsign.isEmpty {
                        LabeledContent("APRS-IS passcode") {
                            Text("\(APRSMessaging.passcode(for: config.myCallsign))")
                                .font(.firaCode(.body))
                                .foregroundStyle(GalacticPalette.hotPink)
                                .monospacedDigit()
                        }
                    }
                    SecureField("aprs.fi API key", text: $config.aprsAPIKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Text("Callsign is required for APRS send/receive. The aprs.fi key is required for lookups and receiving messages.")
                        .font(.firaCode(.caption2))
                        .foregroundStyle(.secondary)
                }

                Section("NASA") {
                    SecureField("api.nasa.gov key (optional)", text: $config.nasaAPIKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Text("Used for APOD. DEMO_KEY works for a few requests per hour. Get a free key at api.nasa.gov.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("N2YO") {
                    SecureField("n2yo.com API key (optional)", text: $config.n2yoAPIKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Text("Adds upcoming visible ISS passes for your location. Free key at n2yo.com.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Marine zone (default)") {
                    TextField("e.g. GMZ033", text: $config.defaultMarineZone)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                    Text("Find your zone at weather.gov/marine. Leave blank if inland.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Network") {
                    TextField("User-Agent", text: $config.userAgent)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Text("NWS requires a contact-shaped User-Agent. Default is fine.")
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
                        "iOS repo",
                        destination: URL(string: "https://github.com/SpaceTrucker2196/StatusGalactic-iOS")!
                    )
                } header: {
                    Text("About")
                } footer: {
                    Text("Status Galactic runs entirely on-device. Weather, marine, space-weather, sun, moon, and planetary positions are all computed or fetched directly from public sources.")
                        .font(.caption)
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
                .onChange(of: notifications.goldenHourEnabled) { handleNotifChange() }
            Toggle("Astronomical dusk reminders", isOn: $notifications.astronomicalDuskEnabled)
                .onChange(of: notifications.astronomicalDuskEnabled) { handleNotifChange() }
            if let next = notifications.nextGoldenHour, notifications.goldenHourEnabled {
                LabeledContent("Next golden hour") {
                    Text(next, style: .relative).foregroundStyle(.secondary)
                }
            }
            if let next = notifications.nextAstroDusk, notifications.astronomicalDuskEnabled {
                LabeledContent("Next astro dusk") {
                    Text(next, style: .relative).foregroundStyle(.secondary)
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
            Text("Schedules up to 14 days of alerts at your last known location.")
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
