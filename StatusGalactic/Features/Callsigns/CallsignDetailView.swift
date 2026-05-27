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
                        .font(.firaCode(.largeTitle, weight: .bold))
                        .foregroundStyle(GalacticPalette.neonCyan)
                        .neonGlow(GalacticPalette.neonCyan, intensity: 6)
                    Spacer()
                    if !callsign.label.isEmpty {
                        Text(callsign.label)
                            .font(.firaCode(.title3))
                            .foregroundStyle(GalacticPalette.peach)
                    }
                }
                if !callsign.notes.isEmpty {
                    Text(callsign.notes)
                        .font(.firaCode(.callout))
                        .foregroundStyle(GalacticPalette.peach.opacity(0.85))
                }
            }
            .listRowSeparator(.hidden)
            .listRowBackground(GalacticPalette.deepPurple.opacity(0.35))

            PhosphorSection("Last known position") {
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
                    if let course = fix.courseDeg {
                        LabeledContent("Course") {
                            Text(String(format: "%.0f° %@", course, Self.compass(for: course)))
                                .font(.callout.monospacedDigit())
                        }
                    }
                    if let speed = fix.speedKmh, speed > 0 {
                        let knots = speed * 0.5399568
                        let mph = speed * 0.6213712
                        LabeledContent("Speed") {
                            Text(String(format: "%.0f km/h • %.0f mph • %.0f kt", speed, mph, knots))
                                .font(.callout.monospacedDigit())
                        }
                    }
                    if let alt = fix.altitudeM {
                        let ft = alt * 3.28084
                        LabeledContent("Altitude") {
                            Text(String(format: "%.0f m (%.0f ft)", alt, ft))
                                .font(.callout.monospacedDigit())
                        }
                    }
                    if let symbol = fix.symbol, !symbol.isEmpty {
                        LabeledContent("Symbol") {
                            Text(symbol).font(.callout.monospaced())
                        }
                    }
                    if let kind = fix.stationType, !kind.isEmpty {
                        LabeledContent("Station type") {
                            Text(Self.label(forType: kind))
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if let status = fix.statusMessage {
                        LabeledContent("Status") {
                            Text(status)
                                .font(.callout)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    if let path = fix.path, !path.isEmpty {
                        LabeledContent("Path") {
                            Text(path)
                                .font(.callout.monospaced())
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                    if let phg = fix.phg, !phg.isEmpty {
                        LabeledContent("PHG") {
                            Text(phg).font(.callout.monospaced())
                        }
                    }
                    if let lastTime = fix.lastTime {
                        LabeledContent("Last heard") {
                            Text(lastTime, style: .relative)
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
                        .foregroundStyle(GalacticPalette.storm)
                }
            }
            .listRowBackground(GalacticPalette.deepPurple.opacity(0.35))
        }
        .listRowBackground(GalacticPalette.deepPurple.opacity(0.35))
        .scrollContentBackground(.hidden)
        .background(GalacticPalette.cosmicSky.ignoresSafeArea())
        .navigationTitle(callsign.call)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GalacticPalette.cosmicBlack.opacity(0.85), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
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

    fileprivate static func compass(for course: Double) -> String {
        let normalized = course.truncatingRemainder(dividingBy: 360)
        let bearing = normalized < 0 ? normalized + 360 : normalized
        let dirs = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                    "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let idx = Int((bearing / 22.5).rounded()) % 16
        return dirs[idx]
    }

    fileprivate static func label(forType type: String) -> String {
        switch type.lowercased() {
        case "l": return "APRS station"
        case "i": return "APRS item"
        case "o": return "APRS object"
        case "w": return "Weather station"
        case "a": return "AIS vessel"
        default:  return type
        }
    }
}
