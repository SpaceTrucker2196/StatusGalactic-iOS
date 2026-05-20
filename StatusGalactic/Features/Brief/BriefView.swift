import SwiftUI

struct BriefView: View {
    @Environment(LocationManager.self) private var location
    @Environment(ClientConfig.self) private var config
    @Environment(CallsignStore.self) private var callsigns
    @Environment(NotificationManager.self) private var notifications

    @State private var vm = BriefViewModel()

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Galactic Weather")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        sourcePicker
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            Task { await refresh() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
                .task {
                    location.requestPermissionIfNeeded()
                    await refresh()
                }
                .refreshable { await refresh() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch vm.state {
        case .idle:
            ContentUnavailableView(
                "No brief yet",
                systemImage: "globe.americas",
                description: Text("Tap refresh to load.")
            )
        case .loading:
            ProgressView("Loading brief...")
        case .loaded(let brief, let fetchedAt):
            BriefDetailView(brief: brief, fetchedAt: fetchedAt)
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
            }
        }
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
    }

    private func refresh() async {
        if vm.marineZone.isEmpty {
            vm.marineZone = config.defaultMarineZone
        }
        await vm.load(
            config: config,
            location: location.lastLocation,
            tz: TimeZone.current.identifier
        )
        // Refresh local notification schedule from the freshest known location.
        if case .loaded(let brief, _) = vm.state {
            await notifications.reschedule(latitude: brief.lat, longitude: brief.lng)
        }
    }
}
