import SwiftUI

struct RFView: View {
    @Environment(ClientConfig.self) private var config
    @Environment(APRSMessageStore.self) private var store
    @Environment(LocationManager.self) private var location
    @Environment(APRSStationLogStore.self) private var log
    @Environment(BriefViewModel.self) private var brief

    @State private var showCompose = false
    @State private var isRefreshing = false
    @State private var error: String?
    @State private var dxStats = APRSDXStats(today: nil, month: nil, year: nil)
    @State private var myFix: APRSFix?

    /// The latest brief snapshot, when one is available. Used to populate
    /// the RF Propagation + RF Activity sections at the top.
    private var loadedBrief: Brief? {
        if case .loaded(let b, _, _) = brief.state { return b }
        return nil
    }

    private var isStale: Bool {
        if case .loaded(_, _, let stale) = brief.state { return stale }
        return false
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("RF")
                .background(GalacticPalette.cosmicSky.ignoresSafeArea())
                .scrollContentBackground(.hidden)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showCompose = true
                        } label: {
                            Image(systemName: "square.and.pencil")
                        }
                        .disabled(config.myCallsign.isEmpty)
                    }
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            Task { await refresh() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .disabled(config.myCallsign.isEmpty || isRefreshing)
                    }
                }
                .task { await refresh() }
                .refreshable { await refresh() }
                .sheet(isPresented: $showCompose) {
                    APRSComposeView(prefilledRecipient: nil)
                }
                .navigationDestination(for: APRSThread.self) { thread in
                    APRSThreadView(thread: thread)
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if config.myCallsign.isEmpty {
            ContentUnavailableView {
                Label("Set your callsign", systemImage: "antenna.radiowaves.left.and.right")
            } description: {
                Text("Enter your ham radio callsign in Settings to send and receive APRS messages.")
            }
            .foregroundStyle(GalacticPalette.neonCyan)
        } else {
            let threads = store.threads(myCallsign: config.myCallsign)
            List {
                // RF propagation / activity sections sourced from the
                // shared brief. Rendered grey when the brief itself is
                // showing cached data.
                rfBriefSections
                    .opacity(isStale ? 0.55 : 1)
                    .grayscale(isStale ? 0.85 : 0)

                Section {
                    StationHeader(callsign: config.myCallsign, isRefreshing: isRefreshing)
                    if let fix = myFix {
                        MyStationFixRows(fix: fix)
                    }
                } header: {
                    Text("Your station")
                }
                .listRowBackground(GalacticPalette.deepPurple.opacity(0.4))

                if !log.entries.isEmpty {
                    Section("Station log") {
                        ForEach(log.entries.prefix(5)) { entry in
                            StationLogRow(entry: entry)
                        }
                        if log.entries.count > 5 {
                            Text("+\(log.entries.count - 5) older fixes stored")
                                .font(.firaCode(.caption2))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .listRowBackground(GalacticPalette.deepPurple.opacity(0.25))
                }

                if let error {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .font(.firaCode(.caption))
                            .foregroundStyle(GalacticPalette.storm)
                    }
                    .listRowBackground(Color.clear)
                }

                Section("DX Stats") {
                    APRSDXStatsView(stats: dxStats)
                }
                .listRowBackground(GalacticPalette.deepPurple.opacity(0.35))

                let bulletins = store.bulletins
                if !bulletins.isEmpty {
                    Section("Bulletins") {
                        ForEach(bulletins.prefix(10)) { msg in
                            BulletinRow(message: msg)
                        }
                    }
                    .listRowBackground(GalacticPalette.deepPurple.opacity(0.25))
                }

                if threads.isEmpty && bulletins.isEmpty {
                    Section {
                        Text("No conversations or bulletins yet. Pull to refresh.")
                            .font(.firaCode(.subheadline))
                            .foregroundStyle(GalacticPalette.peach.opacity(0.8))
                    }
                    .listRowBackground(Color.clear)
                } else if !threads.isEmpty {
                    Section("Conversations") {
                        ForEach(threads) { thread in
                            NavigationLink(value: thread) {
                                APRSThreadRow(thread: thread, myCallsign: config.myCallsign)
                            }
                        }
                    }
                    .listRowBackground(GalacticPalette.deepPurple.opacity(0.25))
                }
            }
        }
    }

    private func refresh() async {
        guard !config.myCallsign.isEmpty else { return }
        guard !config.aprsAPIKey.isEmpty else {
            error = "Set your aprs.fi API key in Settings to receive messages."
            return
        }
        isRefreshing = true
        defer { isRefreshing = false }
        let client = APRSMessaging(userAgent: config.userAgent)
        let aprs = APRSClient(userAgent: config.userAgent, apiKey: config.aprsAPIKey)
        do {
            async let incomingTask = client.receive(
                forCallsign: config.myCallsign,
                apiKey: config.aprsAPIKey
            )
            async let bulletinsTask: [APRSMessage] = (try? await client.receiveBulletins(
                apiKey: config.aprsAPIKey
            )) ?? []
            // Pull richer station data for the user's own callsign in the
            // same refresh cycle so the My Station block + log update in step.
            async let myFixTask: APRSFix? = (try? await aprs.locate(config.myCallsign))

            let incoming = try await incomingTask
            let bulletins = await bulletinsTask
            store.upsert(many: incoming)
            store.upsert(many: bulletins)
            if let fix = await myFixTask {
                myFix = fix
                log.append(fix)
            }
            error = nil
        } catch let http as HTTPError {
            error = http.errorDescription
        } catch {
            self.error = error.localizedDescription
        }

        // After messages settle, enrich every conversation's "other party"
        // with position + distance, then recompute the DX stats panel.
        // Bidirectional: outgoing messages now contribute to DX too.
        if let here = location.lastLocation {
            await store.enrichDistances(
                observerLat: here.coordinate.latitude,
                observerLng: here.coordinate.longitude,
                myCallsign: config.myCallsign,
                client: aprs
            )
        }
        dxStats = store.dxStats(myCallsign: config.myCallsign)
    }

    // MARK: - RF brief sections

    /// Sections pulled in from the shared Brief: HF propagation conditions,
    /// ionosonde readings, WWV bulletin, magnetic declination, then the
    /// activity feeds (POTA, SOTA, DX, repeaters).
    @ViewBuilder
    private var rfBriefSections: some View {
        if let brief = loadedBrief {
            if !brief.bandConditions.isEmpty {
                Section {
                    BandConditionsPanel(bands: brief.bandConditions)
                } header: {
                    Text("HF Band Conditions")
                }
                .listRowBackground(Color.clear)
            }
            if !brief.ionosondes.isEmpty {
                Section {
                    IonosondePanel(stations: brief.ionosondes)
                } header: {
                    Text("Ionosondes")
                }
                .listRowBackground(Color.clear)
            }
            if let wwv = brief.wwvBulletin {
                Section {
                    WWVBulletinPanel(bulletin: wwv)
                } header: {
                    Text("WWV propagation bulletin")
                }
                .listRowBackground(Color.clear)
            }
            if let mag = brief.magneticDeclination {
                Section("Magnetic declination") {
                    HStack {
                        Image(systemName: "location.north.fill")
                            .foregroundStyle(GalacticPalette.mint)
                        Text(mag.formatted)
                            .font(.firaCode(.headline, weight: .bold))
                            .foregroundStyle(GalacticPalette.neonCyan)
                        Spacer()
                        Text("Point antennas \(mag.formatted) off true north")
                            .font(.firaCode(.caption2))
                            .foregroundStyle(.secondary)
                    }
                }
                .listRowBackground(GalacticPalette.deepPurple.opacity(0.25))
            }
            if !brief.potaSpots.isEmpty {
                Section("Parks On The Air") {
                    ForEach(brief.potaSpots) { spot in
                        POTASpotRow(spot: spot)
                    }
                }
                .listRowBackground(GalacticPalette.deepPurple.opacity(0.25))
            }
            if !brief.sotaSpots.isEmpty {
                Section("Summits On The Air") {
                    ForEach(brief.sotaSpots) { spot in
                        SOTASpotRow(spot: spot)
                    }
                }
                .listRowBackground(GalacticPalette.deepPurple.opacity(0.25))
            }
            if !brief.dxSpots.isEmpty {
                Section("DX Cluster") {
                    ForEach(brief.dxSpots) { spot in
                        DXSpotRow(spot: spot)
                    }
                }
                .listRowBackground(GalacticPalette.deepPurple.opacity(0.25))
            }
            if !brief.repeaters.isEmpty {
                Section {
                    ForEach(brief.repeaters) { repeater in
                        RepeaterRow(repeater: repeater)
                    }
                } header: {
                    Text("Nearby Repeaters")
                } footer: {
                    Text("RepeaterBook · ham repeaters near \(brief.earth?.locationName ?? "your location").")
                        .font(.firaCode(.caption2))
                }
                .listRowBackground(GalacticPalette.deepPurple.opacity(0.25))
            }
        }
    }
}

private struct BulletinRow: View {
    let message: APRSMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "megaphone.fill")
                    .foregroundStyle(GalacticPalette.electricBlue)
                    .neonGlow(GalacticPalette.electricBlue, intensity: 4)
                Text(message.to)
                    .font(.firaCode(.headline, weight: .semibold))
                    .foregroundStyle(GalacticPalette.neonCyan)
                Text("from \(message.from)")
                    .font(.firaCode(.caption2))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(message.sentAt, style: .relative)
                    .font(.firaCode(.caption2))
                    .foregroundStyle(.secondary)
            }
            Text(message.text)
                .font(.firaCode(.caption))
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 2)
    }
}

private struct StationHeader: View {
    let callsign: String
    let isRefreshing: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.title)
                .foregroundStyle(GalacticPalette.neonMagenta)
                .neonGlow(GalacticPalette.neonMagenta, intensity: 6)
            VStack(alignment: .leading, spacing: 2) {
                Text(callsign.uppercased())
                    .font(.firaCode(.title3, weight: .bold))
                    .foregroundStyle(GalacticPalette.neonCyan)
                    .neonGlow(GalacticPalette.neonCyan, intensity: 6)
                Text("Passcode \(APRSMessaging.passcode(for: callsign))")
                    .font(.firaCode(.caption2))
                    .foregroundStyle(GalacticPalette.peach)
            }
            Spacer()
            if isRefreshing {
                ProgressView().tint(GalacticPalette.neonCyan)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct APRSThreadRow: View {
    let thread: APRSThread
    let myCallsign: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "person.crop.square.fill")
                    .foregroundStyle(GalacticPalette.hotPink)
                    .neonGlow(GalacticPalette.hotPink, intensity: 4)
                Text(thread.partner)
                    .font(.firaCode(.headline, weight: .semibold))
                    .foregroundStyle(GalacticPalette.peach)
                Spacer()
                if let last = thread.lastMessageAt {
                    Text(last, style: .relative)
                        .font(.firaCode(.caption2))
                        .foregroundStyle(.secondary)
                }
            }
            if let last = thread.lastMessage {
                Text(last.text)
                    .font(.firaCode(.caption))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            }
            Text("\(thread.messages.count) message\(thread.messages.count == 1 ? "" : "s")")
                .font(.firaCode(.caption2))
                .foregroundStyle(GalacticPalette.neonCyan.opacity(0.7))
        }
        .padding(.vertical, 2)
    }
}
