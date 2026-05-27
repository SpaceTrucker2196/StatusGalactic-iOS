import SwiftUI

struct CallsignsView: View {
    @Environment(CallsignStore.self) private var store
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            Group {
                if store.callsigns.isEmpty {
                    ContentUnavailableView {
                        Label("No callsigns yet", systemImage: "antenna.radiowaves.left.and.right")
                            .foregroundStyle(GalacticPalette.neonCyan)
                    } description: {
                        Text("Add APRS callsigns to track positions and load briefs at those locations.")
                            .foregroundStyle(GalacticPalette.peach.opacity(0.85))
                    } actions: {
                        Button("Add a Callsign") { showAdd = true }
                            .buttonStyle(.borderedProminent)
                            .tint(GalacticPalette.neonMagenta)
                            .accessibilityIdentifier(A11yID.Callsigns.addEmpty)
                    }
                } else {
                    List {
                        PhosphorSection("Saved callsigns") {
                            ForEach(store.callsigns) { entry in
                                NavigationLink(value: entry) {
                                    CallsignRow(entry: entry)
                                }
                                .accessibilityIdentifier("callsigns.row.\(entry.call)")
                            }
                            .onDelete { offsets in
                                store.remove(at: offsets)
                            }
                        }
                        .listRowBackground(GalacticPalette.deepPurple.opacity(0.35))
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .accessibilityIdentifier(A11yID.Callsigns.list)
                    .navigationDestination(for: Callsign.self) { entry in
                        CallsignDetailView(callsign: entry)
                    }
                }
            }
            .background(GalacticPalette.cosmicSky.ignoresSafeArea())
            .navigationTitle("Callsigns")
            .toolbarBackground(GalacticPalette.cosmicBlack.opacity(0.85), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityIdentifier(A11yID.Callsigns.addToolbar)
                    .accessibilityLabel("Add callsign")
                }
                if !store.callsigns.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        EditButton()
                            .accessibilityIdentifier(A11yID.Callsigns.edit)
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddCallsignView()
                    .presentationDetents([.medium])
            }
        }
    }
}

private struct CallsignRow: View {
    let entry: Callsign

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .foregroundStyle(GalacticPalette.neonMagenta)
                    .neonGlow(GalacticPalette.neonMagenta, intensity: 4)
                Text(entry.call)
                    .font(.firaCode(.headline, weight: .bold))
                    .foregroundStyle(GalacticPalette.neonCyan)
                    .neonGlow(GalacticPalette.neonCyan, intensity: 4)
                if !entry.label.isEmpty {
                    Text(entry.label)
                        .font(.firaCode(.subheadline))
                        .foregroundStyle(GalacticPalette.peach)
                }
                Spacer()
                Text(entry.addedAt, style: .date)
                    .font(.firaCode(.caption2))
                    .foregroundStyle(GalacticPalette.mint.opacity(0.75))
                    .monospacedDigit()
            }
            if !entry.notes.isEmpty {
                Text(entry.notes)
                    .font(.firaCode(.caption))
                    .foregroundStyle(GalacticPalette.peach.opacity(0.8))
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 2)
    }
}
