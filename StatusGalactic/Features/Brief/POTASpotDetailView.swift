import SwiftUI
import MapKit

/// Detail page for a single Parks On The Air spot. Pushed from the POTA
/// section in the RF tab. Shows the activator + park metadata, the
/// frequency / mode, the distance and azimuth from the viewer (when
/// known), comments, and — if the spot carries coordinates — a small
/// MapKit pin for the park.
struct POTASpotDetailView: View {
    let spot: POTASpot

    var body: some View {
        List {
            PhosphorSection("Activator") {
                LabeledRow("Callsign", value: spot.activator,
                           valueColor: GalacticPalette.neonCyan)
                LabeledRow("Park ref", value: spot.parkRef,
                           valueColor: GalacticPalette.peach)
                LabeledRow("Park name", value: spot.parkName,
                           valueColor: .primary)
                if let loc = spot.locationDesc {
                    LabeledRow("Location", value: loc,
                               valueColor: GalacticPalette.peach.opacity(0.85))
                }
            }
            .listRowBackground(GalacticPalette.deepPurple.opacity(0.30))

            PhosphorSection("Operating") {
                LabeledRow("Frequency",
                           value: String(format: "%.4f MHz", spot.frequencyKHz / 1000),
                           valueColor: bandColor)
                LabeledRow("Mode", value: spot.mode,
                           valueColor: GalacticPalette.neonCyan)
                LabeledRow("Spotted",
                           value: spot.spotTime.formatted(.relative(presentation: .named)),
                           valueColor: .secondary)
            }
            .listRowBackground(GalacticPalette.deepPurple.opacity(0.30))

            if spot.distanceKm != nil || spot.azimuthDeg != nil {
                PhosphorSection("From your location") {
                    if let d = spot.distanceKm {
                        LabeledRow("Distance",
                                   value: String(format: "%.0f km · %.0f mi", d, d * 0.62137),
                                   valueColor: GalacticPalette.hotPink)
                    }
                    if let az = spot.azimuthDeg {
                        LabeledRow(
                            "Bearing",
                            value: "\(compassPoint(forBearing: az)) · \(Int(az.rounded()))° true",
                            valueColor: GalacticPalette.mint
                        )
                    }
                }
                .listRowBackground(GalacticPalette.deepPurple.opacity(0.30))
            }

            if let comments = spot.comments, !comments.isEmpty {
                PhosphorSection("Spot comments") {
                    Text(comments)
                        .font(.firaCode(.caption))
                        .foregroundStyle(GalacticPalette.peach)
                }
                .listRowBackground(GalacticPalette.deepPurple.opacity(0.30))
            }

            if let lat = spot.latitude, let lng = spot.longitude {
                PhosphorSection("Park location") {
                    POTAMapView(latitude: lat, longitude: lng, label: spot.parkRef)
                        .frame(height: 220)
                        .listRowInsets(EdgeInsets())
                }
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(GalacticPalette.cosmicSky.ignoresSafeArea())
        .navigationTitle(spot.parkRef)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var bandColor: Color {
        let mhz = spot.frequencyKHz / 1000
        switch mhz {
        case 14...:   return GalacticPalette.mint
        case 7..<14:  return GalacticPalette.peach
        case 3..<7:   return GalacticPalette.sunsetOrange
        default:      return GalacticPalette.storm
        }
    }
}

/// Detail page for a single Summits On The Air spot. Mirrors the POTA
/// layout but drops the distance/azimuth section (SOTA spots don't
/// carry coordinates in our feed) and shows the summit's name + height
/// instead of a map.
struct SOTASpotDetailView: View {
    let spot: SOTASpot

    var body: some View {
        List {
            PhosphorSection("Activator") {
                LabeledRow("Callsign", value: spot.activator,
                           valueColor: GalacticPalette.neonCyan)
                LabeledRow("Summit code", value: spot.summitCode,
                           valueColor: GalacticPalette.peach)
                LabeledRow("Summit", value: spot.summitDetails,
                           valueColor: .primary)
            }
            .listRowBackground(GalacticPalette.deepPurple.opacity(0.30))

            PhosphorSection("Operating") {
                LabeledRow("Frequency",
                           value: String(format: "%.4f MHz", spot.frequencyKHz / 1000),
                           valueColor: bandColor)
                LabeledRow("Mode", value: spot.mode,
                           valueColor: GalacticPalette.neonCyan)
                LabeledRow("Spotted",
                           value: spot.spotTime.formatted(.relative(presentation: .named)),
                           valueColor: .secondary)
            }
            .listRowBackground(GalacticPalette.deepPurple.opacity(0.30))

            if let comments = spot.comments, !comments.isEmpty {
                PhosphorSection("Spot comments") {
                    Text(comments)
                        .font(.firaCode(.caption))
                        .foregroundStyle(GalacticPalette.peach)
                }
                .listRowBackground(GalacticPalette.deepPurple.opacity(0.30))
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(GalacticPalette.cosmicSky.ignoresSafeArea())
        .navigationTitle(spot.summitCode)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var bandColor: Color {
        let mhz = spot.frequencyKHz / 1000
        switch mhz {
        case 14...:   return GalacticPalette.mint
        case 7..<14:  return GalacticPalette.peach
        case 3..<7:   return GalacticPalette.sunsetOrange
        default:      return GalacticPalette.storm
        }
    }
}

// MARK: - Shared row + map helpers

private struct LabeledRow: View {
    let label: String
    let value: String
    let valueColor: Color

    init(_ label: String, value: String, valueColor: Color) {
        self.label = label
        self.value = value
        self.valueColor = valueColor
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.firaCode(.caption))
                .foregroundStyle(.secondary)
                .frame(width: 96, alignment: .leading)
            Text(value)
                .font(.firaCode(.callout, weight: .semibold))
                .foregroundStyle(valueColor)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

private struct POTAMapView: View {
    let latitude: Double
    let longitude: Double
    let label: String

    var body: some View {
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        Map(initialPosition: .region(MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 1.5, longitudeDelta: 1.5)
        ))) {
            Annotation(label, coordinate: center) {
                Image(systemName: "tree.fill")
                    .font(.title2)
                    .foregroundStyle(GalacticPalette.mint)
                    .padding(6)
                    .background(Circle().fill(GalacticPalette.cosmicBlack.opacity(0.7)))
            }
        }
    }
}
