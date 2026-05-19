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
                    } description: {
                        Text("Add APRS callsigns to track positions and load briefs at those locations.")
                    } actions: {
                        Button("Add a Callsign") { showAdd = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach(store.callsigns) { entry in
                            CallsignRow(entry: entry)
                        }
                        .onDelete { offsets in
                            store.remove(at: offsets)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Callsigns")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                if !store.callsigns.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        EditButton()
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
            HStack {
                Text(entry.call)
                    .font(.headline.monospaced())
                if !entry.label.isEmpty {
                    Text(entry.label)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(entry.addedAt, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            if !entry.notes.isEmpty {
                Text(entry.notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 2)
    }
}
