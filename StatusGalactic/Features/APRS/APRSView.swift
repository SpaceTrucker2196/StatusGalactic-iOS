import SwiftUI

struct APRSView: View {
    @Environment(ClientConfig.self) private var config
    @Environment(APRSMessageStore.self) private var store

    @State private var showCompose = false
    @State private var isRefreshing = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("APRS")
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
                    APRSComposeView()
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
            List {
                Section {
                    HStack(spacing: 10) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.title)
                            .foregroundStyle(GalacticPalette.neonMagenta)
                            .neonGlow(GalacticPalette.neonMagenta, intensity: 6)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(config.myCallsign.uppercased())
                                .font(.firaCode(.title3, weight: .bold))
                                .foregroundStyle(GalacticPalette.neonCyan)
                                .neonGlow(GalacticPalette.neonCyan, intensity: 6)
                            Text("Passcode \(APRSMessaging.passcode(for: config.myCallsign))")
                                .font(.firaCode(.caption2))
                                .foregroundStyle(GalacticPalette.peach)
                        }
                        Spacer()
                        if isRefreshing {
                            ProgressView().tint(GalacticPalette.neonCyan)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Your station")
                }
                .listRowBackground(GalacticPalette.deepPurple.opacity(0.4))

                if let error {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .font(.firaCode(.caption))
                            .foregroundStyle(GalacticPalette.storm)
                    }
                    .listRowBackground(Color.clear)
                }

                if store.messages.isEmpty {
                    Section {
                        Text("No messages yet. Pull to refresh.")
                            .font(.firaCode(.subheadline))
                            .foregroundStyle(GalacticPalette.peach.opacity(0.8))
                    }
                    .listRowBackground(Color.clear)
                } else {
                    Section("Messages") {
                        ForEach(store.messages) { msg in
                            APRSMessageRow(message: msg)
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
        do {
            let incoming = try await client.receive(
                forCallsign: config.myCallsign,
                apiKey: config.aprsAPIKey
            )
            store.upsert(many: incoming)
            error = nil
        } catch let http as HTTPError {
            error = http.errorDescription
        } catch {
            self.error = error.localizedDescription
        }
    }
}

private struct APRSMessageRow: View {
    let message: APRSMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: message.direction == .incoming
                      ? "arrow.down.left.circle.fill"
                      : "arrow.up.right.circle.fill")
                    .foregroundStyle(message.direction == .incoming
                                     ? GalacticPalette.neonCyan
                                     : GalacticPalette.hotPink)
                    .neonGlow(message.direction == .incoming
                              ? GalacticPalette.neonCyan
                              : GalacticPalette.hotPink, intensity: 4)
                Text(message.direction == .incoming ? message.from : message.to)
                    .font(.firaCode(.headline, weight: .semibold))
                    .foregroundStyle(GalacticPalette.peach)
                Spacer()
                Text(message.sentAt, style: .relative)
                    .font(.firaCode(.caption2))
                    .foregroundStyle(.secondary)
            }
            Text(message.text)
                .font(.firaCode(.body))
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 4)
    }
}
