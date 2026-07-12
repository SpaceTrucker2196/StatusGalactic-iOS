import SwiftUI
import CoreLocation

struct SettingsView: View {
    @Environment(ClientConfig.self) private var config
    @Environment(LocationManager.self) private var location
    @Environment(NotificationManager.self) private var notifications

    @State private var showFeedback = false

    var body: some View {
        @Bindable var config = config
        @Bindable var notifications = notifications

        NavigationStack {
            Form {
                notificationsSection

                Section {
                    TextField("Your callsign (e.g. W9FJC)", text: $config.myCallsign)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .font(.firaCode(.body, weight: .semibold))
                        .foregroundStyle(GalacticPalette.neonCyan)
                        .accessibilityIdentifier(A11yID.Settings.callsign)
                    if !config.myCallsign.isEmpty {
                        LabeledContent("APRS-IS passcode") {
                            Text("\(APRSMessaging.passcode(for: config.myCallsign))")
                                .font(.firaCode(.body))
                                .foregroundStyle(GalacticPalette.hotPink)
                                .monospacedDigit()
                        }
                    }
                    HStack {
                        SecureField("aprs.fi API key", text: $config.aprsAPIKey)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .accessibilityIdentifier(A11yID.Settings.aprsKey)
                        APIKeyHelpButton(info: .aprsFi)
                    }
                    Text("Callsign is required for APRS send/receive. The aprs.fi key is required for lookups and receiving messages.")
                        .font(.firaCode(.caption2))
                        .foregroundStyle(.secondary)
                } header: {
                    Text("APRS")
                }

                Section {
                    HStack {
                        SecureField("api.nasa.gov key (optional)", text: $config.nasaAPIKey)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .accessibilityIdentifier(A11yID.Settings.nasaKey)
                        APIKeyHelpButton(info: .nasa)
                    }
                    Text("Used for APOD, NEO close approaches, and DONKI CMEs. DEMO_KEY works for a few requests/hour.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("NASA")
                }

                Section {
                    HStack {
                        SecureField("RepeaterBook app token (rbuapp_…)", text: $config.repeaterBookToken)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        APIKeyHelpButton(info: .repeaterBook)
                    }
                    Text("RepeaterBook now requires a per-user token. Request API access for Status Galactic, then paste your app token. Leave blank to hide the repeaters card.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("RepeaterBook")
                }

                Section {
                    HStack {
                        SecureField("n2yo.com API key (optional)", text: $config.n2yoAPIKey)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .accessibilityIdentifier(A11yID.Settings.n2yoKey)
                        APIKeyHelpButton(info: .n2yo)
                    }
                    Text("Adds upcoming visible ISS passes for your location.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("N2YO")
                }

                Section("Marine zone (default)") {
                    NavigationLink {
                        MarineZonePickerView(selection: $config.defaultMarineZone)
                    } label: {
                        marineZoneRow
                    }
                    .accessibilityIdentifier(A11yID.Settings.marineZone)
                    Text("Sets the marine forecast for coastal & boating use. Leave as None if inland.")
                        .font(.firaCode(.caption2))
                        .foregroundStyle(.secondary)
                }

                Section {
                    Toggle("APOD as brief background", isOn: $config.useAPODBackground)
                        .accessibilityIdentifier(A11yID.Settings.apodToggle)
                    Button("Clear image cache") {
                        Task { await ImageCache.shared.clear() }
                    }
                    .foregroundStyle(GalacticPalette.hotPink)
                    .accessibilityIdentifier(A11yID.Settings.clearCache)
                } header: {
                    Text("Imagery")
                } footer: {
                    Text("Images are cached on-device; stale entries are purged after 90 days.")
                        .font(.caption)
                }

                Section {
                    HStack {
                        TextField("User-Agent", text: $config.userAgent)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .accessibilityIdentifier(A11yID.Settings.userAgent)
                        APIKeyHelpButton(info: .userAgent)
                    }
                    Text("NWS requires a contact-shaped User-Agent. Default is fine.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Network")
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
                    .accessibilityIdentifier(A11yID.Settings.refreshLocation)
                }

                Section {
                    LabeledContent("App version") {
                        Text(Bundle.main.shortVersion)
                    }
                    Button {
                        showFeedback = true
                    } label: {
                        Label("Report a bug or request a feature", systemImage: "ladybug.fill")
                            .foregroundStyle(GalacticPalette.hotPink)
                    }
                    .accessibilityIdentifier(A11yID.Settings.feedback)
                } header: {
                    Text("About")
                } footer: {
                    Text("Spacetrucker Galactic runs entirely on-device. Weather, marine, space-weather, sun, moon, and planetary positions are all computed or fetched directly from public sources.")
                        .font(.caption)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showFeedback) {
                FeedbackView()
                    .environment(config)
            }
        }
    }

    @ViewBuilder
    private var marineZoneRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "water.waves")
                .foregroundStyle(GalacticPalette.electricBlue)
            VStack(alignment: .leading, spacing: 2) {
                Text("Marine zone")
                    .font(.firaCode(.subheadline))
                marineZoneValue
            }
        }
    }

    @ViewBuilder
    private var marineZoneValue: some View {
        if config.defaultMarineZone.isEmpty {
            Text("None")
                .font(.firaCode(.caption2))
                .foregroundStyle(.secondary)
        } else {
            HStack(spacing: 6) {
                Text(config.defaultMarineZone)
                    .font(.firaCode(.caption, weight: .semibold))
                    .foregroundStyle(GalacticPalette.neonCyan)
                if let name = MarineZoneCatalog.name(forCode: config.defaultMarineZone) {
                    Text(name)
                        .font(.firaCode(.caption2))
                        .foregroundStyle(GalacticPalette.peach.opacity(0.85))
                        .lineLimit(1)
                }
            }
        }
    }

    @ViewBuilder
    private var notificationsSection: some View {
        @Bindable var notifications = notifications

        Section {
            Toggle("Golden hour reminders", isOn: $notifications.goldenHourEnabled)
                .onChange(of: notifications.goldenHourEnabled) { handleNotifChange() }
                .accessibilityIdentifier(A11yID.Settings.Notif.goldenHour)
            Toggle("Astronomical dusk reminders", isOn: $notifications.astronomicalDuskEnabled)
                .onChange(of: notifications.astronomicalDuskEnabled) { handleNotifChange() }
                .accessibilityIdentifier(A11yID.Settings.Notif.astroDusk)
            Toggle("Aurora alert at my location", isOn: $notifications.auroraAlertsEnabled)
                .onChange(of: notifications.auroraAlertsEnabled) { handleNotifChange() }
                .accessibilityIdentifier(A11yID.Settings.Notif.aurora)
            if notifications.auroraAlertsEnabled {
                Stepper(
                    "Fire when ≥ \(notifications.auroraThresholdPct)%",
                    value: $notifications.auroraThresholdPct,
                    in: 5...90,
                    step: 5
                )
                .font(.firaCode(.caption))
                .accessibilityIdentifier(A11yID.Settings.Notif.auroraThreshold)
            }
            Toggle("R / S / G storm alerts", isOn: $notifications.stormAlertsEnabled)
                .onChange(of: notifications.stormAlertsEnabled) { handleNotifChange() }
                .accessibilityIdentifier(A11yID.Settings.Notif.storm)
            if notifications.stormAlertsEnabled {
                Stepper(
                    "Fire when scale ≥ \(notifications.stormMinLevel)",
                    value: $notifications.stormMinLevel,
                    in: 1...5
                )
                .font(.firaCode(.caption))
                .accessibilityIdentifier(A11yID.Settings.Notif.stormLevel)
            }
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
