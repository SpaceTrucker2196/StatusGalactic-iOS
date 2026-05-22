import SwiftUI
import Charts

/// GOES soft X-ray 24-hour sparkline. Flux is plotted on a log10-transformed
/// linear Y axis (we avoid SwiftUI Charts' `.chartYScale(type: .log)` because
/// it crashes on degenerate domains — single value, all zeros, all-equal —
/// observed on iOS 17). Reference rules sit at M, X, and X10 so flare events
/// pop visually.
struct XRayFluxPanel: View {
    let state: XRayState

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("GOES X-ray flux (24h)")
                    .font(.firaCode(.subheadline, weight: .semibold))
                    .foregroundStyle(GalacticPalette.peach)
                Spacer()
                Text("Now \(state.currentClass) · Peak \(state.peakClass24h)")
                    .font(.firaCode(.caption2, weight: .semibold))
                    .foregroundStyle(StormScaleRow.color(forLevel: state.rScale))
                    .monospacedDigit()
            }
            chartContent
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(GalacticPalette.deepPurple.opacity(0.42))
        )
    }

    /// Pre-transformed log10 sample. Clamping to a sane floor stops a
    /// stray near-zero flux from sliding the chart's y-axis to -∞.
    private struct PlottableSample: Identifiable, Hashable {
        let id = UUID()
        let time: Date
        let logFlux: Double
    }

    private var transformedSamples: [PlottableSample] {
        let floor: Double = 1e-9
        return state.history.compactMap { s -> PlottableSample? in
            guard s.flux > 0 else { return nil }
            return PlottableSample(time: s.time, logFlux: log10(max(s.flux, floor)))
        }
    }

    @ViewBuilder
    private var chartContent: some View {
        let samples = transformedSamples
        let uniqueValues = Set(samples.map { $0.logFlux })
        if samples.count >= 2 && uniqueValues.count >= 2 {
            Chart {
                ForEach(samples) { s in
                    LineMark(
                        x: .value("Time", s.time),
                        y: .value("log10 flux", s.logFlux)
                    )
                    .foregroundStyle(GalacticPalette.sun)
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                    AreaMark(
                        x: .value("Time", s.time),
                        y: .value("log10 flux", s.logFlux)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                GalacticPalette.sun.opacity(0.4),
                                GalacticPalette.sun.opacity(0.02)
                            ],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                }
                RuleMark(y: .value("M", log10(1e-5)))
                    .lineStyle(StrokeStyle(lineWidth: 0.6, dash: [3, 3]))
                    .foregroundStyle(GalacticPalette.peach.opacity(0.65))
                RuleMark(y: .value("X", log10(1e-4)))
                    .lineStyle(StrokeStyle(lineWidth: 0.6, dash: [3, 3]))
                    .foregroundStyle(GalacticPalette.storm.opacity(0.7))
                RuleMark(y: .value("X10", log10(1e-3)))
                    .lineStyle(StrokeStyle(lineWidth: 0.6, dash: [3, 3]))
                    .foregroundStyle(GalacticPalette.severe.opacity(0.7))
            }
            .chartYScale(domain: log10(1e-8) ... log10(1e-3))
            .chartYAxis {
                AxisMarks(position: .leading,
                          values: [-8, -7, -6, -5, -4, -3]) { value in
                    AxisGridLine().foregroundStyle(.white.opacity(0.08))
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(Self.letterClass(forLog10: v))
                                .font(.firaCode(.caption2))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .hour, count: 6)) { _ in
                    AxisGridLine().foregroundStyle(.white.opacity(0.08))
                    AxisValueLabel(format: .dateTime.hour())
                        .font(.firaCode(.caption2))
                        .foregroundStyle(GalacticPalette.peach.opacity(0.7))
                }
            }
            .frame(height: 110)
        } else {
            Text("Awaiting GOES samples…")
                .font(.firaCode(.caption))
                .foregroundStyle(.secondary)
                .frame(height: 32)
        }
    }

    static func letterClass(forLog10 lv: Double) -> String {
        switch lv {
        case (-3)...:        return "X10"
        case (-4)..<(-3):    return "X"
        case (-5)..<(-4):    return "M"
        case (-6)..<(-5):    return "C"
        case (-7)..<(-6):    return "B"
        default:             return "A"
        }
    }
}
