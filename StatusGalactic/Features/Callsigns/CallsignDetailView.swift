import SwiftUI
import MapKit

struct CallsignDetailView: View {
    let callsign: Callsign

    @Environment(ClientConfig.self) private var config
    @Environment(CallsignStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var fix: APRSFix?
    @State private var error: String?
    @State private var isLoading = false
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        List {
            Section {
                HStack(alignment: .firstTextBaseline) {
                    Text(callsign.call)
                        .font(.largeTitle.monospaced().weight(.bold))
                    Spacer()
                    if !callsign.label.isEmpty {
                        Text(callsign.label)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
                if !callsign.notes.isEmpty {
                    Text(callsign.notes)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            .listRowSeparator(.hidden)

            Section("Last known position") {
                mapContent
                    .frame(height: 220)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                if let fix {
                    LabeledContent("Coordinates") {
                        Text(String(format: "%.4f, %.4f", fix.lat, fix.lng))
                            .font(.callout.monospacedDigit())
                    }
                    if let comment = fix.comment, !comment.isEmpty {
                        LabeledContent("Comment") {
                            Text(comment)
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Button {
                    Task { await refresh() }
                } label: {
                    Label("Refresh position", systemImage: "arrow.clockwise")
                }
                if let fix {
                    Button {
                        MapsLauncher.openDirections(
                            to: .init(latitude: fix.lat, longitude: fix.lng),
                            name: callsign.call
                        )
                    } label: {
                        Label("Get directions in Maps", systemImage: "map.fill")
                    }
                    Button {
                        MapsLauncher.show(
                            at: .init(latitude: fix.lat, longitude: fix.lng),
                            name: callsign.call
                        )
                    } label: {
                        Label("Show in Maps", systemImage: "mappin.and.ellipse")
                    }
                }
            }

            Section {
                Button(role: .destructive) {
                    store.remove(call: callsign.call)
                    dismiss()
                } label: {
                    Label("Remove from list", systemImage: "trash")
                }
            }
        }
        .navigationTitle(callsign.call)
        .navigationBarTitleDisplayMode(.inline)
        .task { await refresh() }
    }

    @ViewBuilder
    private var mapContent: some View {
        if let fix {
            Map(position: $cameraPosition) {
                Marker(callsign.call, coordinate: .init(latitude: fix.lat, longitude: fix.lng))
                    .tint(.orange)
            }
            .mapStyle(.standard(elevation: .realistic))
        } else if isLoading {
            ZStack {
                Color.secondary.opacity(0.08)
                ProgressView()
            }
        } else if let error {
            ZStack {
                Color.secondary.opacity(0.08)
                Label(error, systemImage: "exclamationmark.triangle")
                    .multilineTextAlignment(.center)
                    .padding()
            }
        } else {
            ZStack {
                Color.secondary.opacity(0.08)
                Text("No position yet").foregroundStyle(.secondary)
            }
        }
    }

    private func refresh() async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        let client = APRSClient(userAgent: config.userAgent, apiKey: config.aprsAPIKey)
        do {
            let result = try await client.locate(callsign.call)
            fix = result
            cameraPosition = .region(MKCoordinateRegion(
                center: .init(latitude: result.lat, longitude: result.lng),
                span: .init(latitudeDelta: 0.5, longitudeDelta: 0.5)
            ))
        } catch let http as HTTPError {
            error = http.errorDescription
        } catch {
            self.error = error.localizedDescription
        }
    }
}
