import SwiftUI

struct BriefView: View {
    @Environment(LocationManager.self) private var location
    @Environment(ClientConfig.self) private var config
    @Environment(CallsignStore.self) private var callsigns
    @Environment(NotificationManager.self) private var notifications
    @Environment(BriefViewModel.self) private var vm
    @State private var loadCount: Int = 0
    @State private var errorCount: Int = 0

    /// Brief tab title — "<CALL> Galactic" once the operator has set
    /// their callsign in Settings, "Spacetrucker Galactic" otherwise.
    /// Personalizes the brief and mirrors the way ham operators sign
    /// off their own kit.
    private var navTitle: String {
        let call = config.myCallsign.trimmingCharacters(in: .whitespacesAndNewlines)
        return call.isEmpty ? "Spacetrucker Galactic" : "\(call.uppercased()) Galactic"
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(navTitle)
                .sensoryFeedback(.success, trigger: loadCount)
                .sensoryFeedback(.error, trigger: errorCount)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        sourcePicker
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            Task { await refresh() }
                        } label: {
                            if vm.isRefreshing {
                                ProgressView()
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                        }
                        .disabled(vm.isRefreshing)
                        .accessibilityIdentifier(A11yID.Brief.refresh)
                        .accessibilityLabel(vm.isRefreshing ? "Refreshing brief" : "Refresh brief")
                    }
                }
                // Intentionally no `.task { refresh() }` here — refresh
                // is driven by ContentView's app-launch + scenePhase
                // observers so tab switches and navigation pops don't
                // re-fire the network fan-out.
                .refreshable { await refresh() }
                .onAppear { location.requestPermissionIfNeeded() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch vm.state {
        case .idle:
            if needsLocationPermission {
                locationPermissionEmptyState
            } else {
                ContentUnavailableView(
                    "No brief yet",
                    systemImage: "globe.americas",
                    description: Text("Tap refresh to load.")
                )
            }
        case .loading:
            ProgressView("Loading brief…")
        case .loaded(let brief, let fetchedAt, let isStale):
            BriefDetailView(brief: brief, fetchedAt: fetchedAt, isStale: isStale)
        case .error(let message):
            VStack(spacing: 16) {
                ContentUnavailableView(
                    "Could not load brief",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
                Button("Try Again") {
                    Task { await refresh() }
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 32)
                .accessibilityIdentifier(A11yID.Brief.retry)
            }
        }
    }

    private var needsLocationPermission: Bool {
        location.lastLocation == nil
            && (location.authorizationStatus == .notDetermined
                || location.authorizationStatus == .denied
                || location.authorizationStatus == .restricted)
    }

    private var locationPermissionEmptyState: some View {
        VStack(spacing: 18) {
            ContentUnavailableView {
                Label("Location needed", systemImage: "location.slash")
            } description: {
                Text("Spacetrucker Galactic uses your location to build a brief for where you are. You can also add a callsign instead.")
            }
            HStack {
                if location.authorizationStatus == .notDetermined {
                    Button("Allow Location") {
                        location.requestPermissionIfNeeded()
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier(A11yID.Brief.locationAllow)
                } else {
                    Button("Open iOS Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier(A11yID.Brief.locationOpenSettings)
                }
            }
        }
        .padding(.bottom, 32)
    }

    private var sourcePicker: some View {
        Menu {
            Button {
                vm.selectedCallsign = nil
                Task { await refresh() }
            } label: {
                Label("My location", systemImage: "location.fill")
            }

            if !callsigns.callsigns.isEmpty {
                Divider()
                ForEach(callsigns.callsigns) { entry in
                    Button {
                        vm.selectedCallsign = entry.call
                        Task { await refresh() }
                    } label: {
                        Label(entry.call, systemImage: "antenna.radiowaves.left.and.right")
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: vm.selectedCallsign == nil
                      ? "location.fill"
                      : "antenna.radiowaves.left.and.right")
                Text(vm.selectedCallsign ?? "Me")
                    .font(.footnote.weight(.medium))
            }
        }
        .accessibilityIdentifier(A11yID.Brief.sourcePicker)
        .accessibilityLabel("Brief source. Currently \(vm.selectedCallsign ?? "my location").")
    }

    private func refresh() async {
        if vm.marineZone.isEmpty {
            vm.marineZone = config.defaultMarineZone
        }
        await vm.load(
            config: config,
            location: location.lastLocation,
            tz: TimeZone.current.identifier,
            notifications: notifications
        )
        // Notification reschedule + App Group mirror now happen inside
        // vm.load so any caller (here, pull-to-refresh, or ContentView's
        // scenePhase observer) gets the same housekeeping.
        if case .loaded = vm.state { loadCount &+= 1 }
        if case .error = vm.state { errorCount &+= 1 }
    }
}
