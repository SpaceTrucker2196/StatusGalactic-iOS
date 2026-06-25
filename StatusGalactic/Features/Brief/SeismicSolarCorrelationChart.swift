import SwiftUI
import Charts

/// Overlays world M4.5+ earthquake counts and GOES soft X-ray flare peak
/// flux on a shared 90-day time axis so visual correlations between
/// solar activity and seismic activity become legible. Each series is
/// independently scaled — quake counts are normalised against their own
/// 90-day peak, flare flux is normalised against its own log-domain
/// peak — and then plotted onto a unitless 0..1 frame. Axis labels on
/// the left show flare class (A/B/C/M/X), labels on the right show the
/// quakes-per-day scale, so each series keeps a real-world reading.
struct SeismicSolarCorrelationChart: View {
    let data: SeismicSolarCorrelation?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("Quakes vs solar flares (90d)")
                    .font(.firaCode(.subheadline, weight: .semibold))
                    .foregroundStyle(GalacticPalette.peach)
                Spacer()
                legend
            }
            chart
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(GalacticPalette.deepPurple.opacity(0.42))
        )
    }

    // MARK: - Series prep

    private struct QuakeBin: Identifiable, Hashable {
        let id: Date
        let date: Date
        let count: Int
        /// Largest magnitude in the bin; nil when no quakes.
        let peakMagnitude: Double?
        /// Count normalised against the 90-day peak (0..1).
        let unit: Double
    }

    private struct FlareBin: Identifiable, Hashable {
        let id: Date
        let date: Date
        let count: Int
        let logFlux: Double
        /// log-flux normalised across the window's own min..max (0..1).
        let unit: Double
    }

    private var quakeBins: [QuakeBin] {
        guard let days = data?.days else { return [] }
        let peak = max(1, days.map(\.quakeCount).max() ?? 1)
        return days.map {
            QuakeBin(id: $0.date,
                     date: $0.date,
                     count: $0.quakeCount,
                     peakMagnitude: $0.peakMagnitude,
                     unit: Double($0.quakeCount) / Double(peak))
        }
    }

    private var flareBins: [FlareBin] {
        guard let days = data?.days else { return [] }
        let logged = days.compactMap { d -> (Date, Int, Double)? in
            guard let v = d.peakFlareFluxLog10 else { return nil }
            return (d.date, d.flareCount, v)
        }
        guard let lo = logged.map(\.2).min(),
              let hi = logged.map(\.2).max(), hi > lo else { return [] }
        let span = hi - lo
        return logged.map { (date, count, v) in
            FlareBin(id: date, date: date, count: count, logFlux: v,
                     unit: (v - lo) / span)
        }
    }

    private var peakCount: Int { quakeBins.map(\.count).max() ?? 0 }

    private var fluxBounds: (lo: Double, hi: Double)? {
        let v = flareBins.map(\.logFlux)
        guard let lo = v.min(), let hi = v.max(), hi > lo else { return nil }
        return (lo, hi)
    }

    private var xDomain: ClosedRange<Date>? {
        guard let days = data?.days, let first = days.first?.date,
              let last = days.last?.date else { return nil }
        return first ... last.addingTimeInterval(86400)
    }

    // MARK: - Chart

    @ViewBuilder
    private var chart: some View {
        let bins = quakeBins
        let flares = flareBins
        if bins.isEmpty && flares.isEmpty {
            Text("Awaiting USGS + DONKI 90-day samples…")
                .font(.firaCode(.caption))
                .foregroundStyle(.secondary)
                .frame(height: 32)
        } else {
            Chart {
                ForEach(bins) { b in
                    BarMark(
                        x: .value("Day", b.date, unit: .day),
                        y: .value("Quakes (norm)", b.unit)
                    )
                    .foregroundStyle(Self.color(forPeakMagnitude: b.peakMagnitude))
                    .cornerRadius(1)
                }
                ForEach(flares) { f in
                    LineMark(
                        x: .value("Day", f.date),
                        y: .value("Flux (norm)", f.unit),
                        series: .value("Series", "flare")
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(GalacticPalette.sun)
                    .lineStyle(StrokeStyle(lineWidth: 1.7))
                    AreaMark(
                        x: .value("Day", f.date),
                        y: .value("Flux (norm)", f.unit),
                        series: .value("Series", "flare-area")
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                GalacticPalette.sun.opacity(0.35),
                                GalacticPalette.sun.opacity(0.0)
                            ],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                }
            }
            .chartYScale(domain: 0 ... 1)
            .chartXScale(domain: xDomain ?? Date.distantPast ... Date.distantFuture)
            .chartYAxis {
                AxisMarks(position: .leading, values: leadingAxisValues) { value in
                    AxisGridLine().foregroundStyle(.white.opacity(0.06))
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(leadingLabel(for: v))
                                .font(.firaCode(.caption2))
                                .foregroundStyle(GalacticPalette.sun.opacity(0.85))
                        }
                    }
                }
                AxisMarks(position: .trailing, values: trailingAxisValues) { value in
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(trailingLabel(for: v))
                                .font(.firaCode(.caption2))
                                .foregroundStyle(GalacticPalette.peach.opacity(0.9))
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 15)) { _ in
                    AxisGridLine().foregroundStyle(.white.opacity(0.08))
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        .font(.firaCode(.caption2))
                        .foregroundStyle(GalacticPalette.peach.opacity(0.7))
                }
            }
            .frame(height: 150)
        }
    }

    // MARK: - Axis labels

    private var leadingAxisValues: [Double] { fluxBounds == nil ? [] : [0, 0.5, 1] }
    private var trailingAxisValues: [Double] { peakCount == 0 ? [] : [0, 0.5, 1] }

    private func leadingLabel(for unit: Double) -> String {
        guard let b = fluxBounds else { return "" }
        let logFlux = b.lo + (b.hi - b.lo) * unit
        return XRayFluxPanel.letterClass(forLog10: logFlux)
    }

    private func trailingLabel(for unit: Double) -> String {
        let n = Int((Double(peakCount) * unit).rounded())
        return "\(n)"
    }

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: 8) {
            legendSwatch(color: GalacticPalette.sun, label: "Flare")
            legendSwatch(
                color: Color(red: 1.00, green: 0.92, blue: 0.40),
                label: "<5"
            )
            legendSwatch(color: GalacticPalette.peach, label: "5+")
            legendSwatch(color: GalacticPalette.sunsetOrange, label: "6+")
            legendSwatch(
                color: Color(red: 1.00, green: 0.18, blue: 0.18),
                label: "7+"
            )
        }
    }

    private func legendSwatch(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(color)
                .frame(width: 10, height: 4)
            Text(label)
                .font(.firaCode(.caption2, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Magnitude → bar color

    /// Color a daily count bar by the largest event in that day's bin —
    /// red for M7+, sliding through orange and amber to yellow for the
    /// smaller M4.5–6 bands so a strong-event day reads at a glance even
    /// when its count is unremarkable. Empty days get a dim neutral.
    static func color(forPeakMagnitude m: Double?) -> Color {
        guard let m else { return GalacticPalette.dustyRose.opacity(0.35) }
        switch m {
        case 7...:    return Color(red: 1.00, green: 0.18, blue: 0.18)   // red
        case 6..<7:   return GalacticPalette.sunsetOrange                // orange
        case 5..<6:   return GalacticPalette.peach                       // amber
        default:      return Color(red: 1.00, green: 0.92, blue: 0.40)   // yellow
        }
    }
}
