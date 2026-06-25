import SwiftUI
import MapKit
import Charts

/// Detail page for a single USGS earthquake. Pushed from the Recent
/// Earthquakes section in the brief. Layers a MapKit epicentre pin, the
/// vital-stats sheet (magnitude / depth / felt distance), the 7-day
/// magnitude timeline with this event highlighted, and — when GOES X-ray
/// history is available — an independently-scaled correlation chart
/// overlaying world-quake counts vs flare flux so a viewer can eyeball
/// whether this event sits near a flare spike.
struct EarthquakeDetailView: View {
    let quake: Earthquake
    let allQuakes: [Earthquake]
    /// 90-day daily binning of world M4.5+ quakes vs solar flares.
    /// Optional because the upstream feeds may still be in flight or
    /// throttled (DEMO_KEY) on first load.
    let correlation: SeismicSolarCorrelation?

    var body: some View {
        List {
            Section {
                EarthquakeMapView(quake: quake)
                    .frame(height: 240)
                    .listRowInsets(EdgeInsets())
            }
            .listRowBackground(Color.clear)

            PhosphorSection("Event") {
                LabeledRow("Magnitude",
                           value: String(format: "M %.1f", quake.magnitude),
                           valueColor: magColor(quake.magnitude))
                LabeledRow("Place", value: quake.place,
                           valueColor: GalacticPalette.neonCyan)
                LabeledRow("When",
                           value: quake.time.formatted(date: .abbreviated,
                                                       time: .standard),
                           valueColor: GalacticPalette.peach)
                LabeledRow("Ago",
                           value: quake.time.formatted(.relative(presentation: .named)),
                           valueColor: GalacticPalette.hotPink)
                LabeledRow("Depth",
                           value: String(format: "%.1f km", quake.depthKm),
                           valueColor: depthColor(quake.depthKm))
                LabeledRow("Coordinates",
                           value: String(format: "%.3f°, %.3f°",
                                         quake.latitude, quake.longitude),
                           valueColor: .secondary)
                if quake.isSignificant {
                    LabeledRow("Flag", value: "Significant",
                               valueColor: GalacticPalette.severe)
                }
                if let d = quake.distanceKm {
                    LabeledRow("From you",
                               value: String(format: "%.0f km · %.0f mi",
                                             d, d * 0.62137),
                               valueColor: GalacticPalette.mint)
                }
            }
            .listRowBackground(GalacticPalette.deepPurple.opacity(0.30))

            if correlation != nil {
                PhosphorSection("Solar ↔ seismic (90d)") {
                    SeismicSolarCorrelationChart(data: correlation)
                    .listRowInsets(EdgeInsets(top: 6, leading: 8,
                                              bottom: 6, trailing: 8))
                }
                .listRowBackground(Color.clear)
            }

            PhosphorSection("Seismic timeline (7d)") {
                EarthquakeContextChart(
                    quakes: globalQuakes,
                    highlight: quake
                )
                .listRowInsets(EdgeInsets(top: 6, leading: 8,
                                          bottom: 6, trailing: 8))
            }
            .listRowBackground(Color.clear)

            if let urlString = quake.usgsURL, let url = URL(string: urlString) {
                Section {
                    Link(destination: url) {
                        HStack {
                            Image(systemName: "arrow.up.right.square")
                            Text("Open on USGS")
                                .font(.firaCode(.callout, weight: .semibold))
                        }
                        .foregroundStyle(GalacticPalette.neonCyan)
                    }
                }
                .listRowBackground(GalacticPalette.deepPurple.opacity(0.30))
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(GalacticPalette.cosmicSky.ignoresSafeArea())
        .navigationTitle(String(format: "M%.1f", quake.magnitude))
        .navigationBarTitleDisplayMode(.inline)
    }

    /// All quakes in the feed are world events (significant_week + local).
    /// We pass them straight through to the charts so the correlation
    /// view sees the full set, not just this single tap.
    private var globalQuakes: [Earthquake] { allQuakes }

    private func magColor(_ m: Double) -> Color {
        switch m {
        case ..<3:   return GalacticPalette.mint
        case ..<4.5: return GalacticPalette.peach
        case ..<6:   return GalacticPalette.sunsetOrange
        case ..<7:   return GalacticPalette.hotPink
        default:     return GalacticPalette.severe
        }
    }

    private func depthColor(_ km: Double) -> Color {
        switch km {
        case ..<35:   return GalacticPalette.hotPink     // shallow — felt strongest
        case ..<70:   return GalacticPalette.peach
        case ..<300:  return GalacticPalette.mint
        default:      return GalacticPalette.neonCyan
        }
    }
}

// MARK: - Map

private struct EarthquakeMapView: View {
    let quake: Earthquake

    var body: some View {
        let center = CLLocationCoordinate2D(latitude: quake.latitude,
                                            longitude: quake.longitude)
        let span = Self.span(forMagnitude: quake.magnitude)
        Map(initialPosition: .region(MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)
        ))) {
            Annotation("M\(String(format: "%.1f", quake.magnitude))",
                       coordinate: center) {
                ZStack {
                    Circle()
                        .stroke(magColor(quake.magnitude).opacity(0.6),
                                lineWidth: 2)
                        .frame(width: 44, height: 44)
                        .blur(radius: 1.5)
                    Circle()
                        .fill(magColor(quake.magnitude))
                        .frame(width: 14, height: 14)
                        .overlay(Circle().stroke(.white.opacity(0.9),
                                                 lineWidth: 1))
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
    }

    /// Wider region for bigger quakes so the basemap context is readable.
    static func span(forMagnitude m: Double) -> Double {
        switch m {
        case ..<3:    return 1.5
        case ..<5:    return 4
        case ..<6.5:  return 10
        case ..<7.5:  return 20
        default:      return 35
        }
    }

    private func magColor(_ m: Double) -> Color {
        switch m {
        case ..<3:   return GalacticPalette.mint
        case ..<4.5: return GalacticPalette.peach
        case ..<6:   return GalacticPalette.sunsetOrange
        case ..<7:   return GalacticPalette.hotPink
        default:     return GalacticPalette.severe
        }
    }
}

// MARK: - 7-day context chart with the tapped event highlighted

private struct EarthquakeContextChart: View {
    let quakes: [Earthquake]
    let highlight: Earthquake

    var body: some View {
        Chart {
            ForEach(quakes) { q in
                BarMark(
                    x: .value("When", q.time),
                    y: .value("Mag", q.magnitude)
                )
                .foregroundStyle(q.id == highlight.id
                                 ? GalacticPalette.severe
                                 : magColor(q.magnitude).opacity(0.5))
            }
            RuleMark(x: .value("This event", highlight.time))
                .lineStyle(StrokeStyle(lineWidth: 0.8, dash: [2, 3]))
                .foregroundStyle(GalacticPalette.severe.opacity(0.7))
            RuleMark(y: .value("M5", 5))
                .lineStyle(StrokeStyle(lineWidth: 0.6, dash: [3, 3]))
                .foregroundStyle(GalacticPalette.storm.opacity(0.7))
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 1)) { _ in
                AxisGridLine().foregroundStyle(.white.opacity(0.08))
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .font(.firaCode(.caption2))
                    .foregroundStyle(GalacticPalette.peach.opacity(0.7))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: [0, 3, 5, 7]) { _ in
                AxisGridLine().foregroundStyle(.white.opacity(0.08))
                AxisValueLabel()
                    .font(.firaCode(.caption2))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 120)
        .padding(.vertical, 4)
    }

    private func magColor(_ m: Double) -> Color {
        switch m {
        case ..<3:   return GalacticPalette.mint
        case ..<4.5: return GalacticPalette.peach
        case ..<6:   return GalacticPalette.sunsetOrange
        case ..<7:   return GalacticPalette.hotPink
        default:     return GalacticPalette.severe
        }
    }
}

// MARK: - Shared label row

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
                .frame(width: 110, alignment: .leading)
            Text(value)
                .font(.firaCode(.callout, weight: .semibold))
                .foregroundStyle(valueColor)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .monospacedDigit()
        }
    }
}
