import SwiftUI
import Charts

/// GOES soft X-ray 24-hour sparkline. Flux is plotted on a log Y axis so
/// the A → X class band-jumps are evenly spaced. Reference rules at the
/// M, X, and X10 class boundaries make flare events instantly readable.
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
            if state.history.count >= 2 {
                Chart {
                    ForEach(state.history, id: \.time) { s in
                        LineMark(
                            x: .value("Time", s.time),
                            y: .value("Flux", s.flux)
                        )
                        .foregroundStyle(GalacticPalette.sun)
                        .lineStyle(StrokeStyle(lineWidth: 1.5))
                        AreaMark(
                            x: .value("Time", s.time),
                            y: .value("Flux", s.flux)
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
                    // NOAA letter-class reference lines.
                    RuleMark(y: .value("M", 1e-5))
                        .lineStyle(StrokeStyle(lineWidth: 0.6, dash: [3, 3]))
                        .foregroundStyle(GalacticPalette.peach.opacity(0.65))
                        .annotation(position: .topTrailing, alignment: .trailing) {
                            Text("M").font(.firaCode(.caption2))
                                .foregroundStyle(GalacticPalette.peach.opacity(0.85))
                        }
                    RuleMark(y: .value("X", 1e-4))
                        .lineStyle(StrokeStyle(lineWidth: 0.6, dash: [3, 3]))
                        .foregroundStyle(GalacticPalette.storm.opacity(0.7))
                        .annotation(position: .topTrailing, alignment: .trailing) {
                            Text("X").font(.firaCode(.caption2))
                                .foregroundStyle(GalacticPalette.storm)
                        }
                    RuleMark(y: .value("X10", 1e-3))
                        .lineStyle(StrokeStyle(lineWidth: 0.6, dash: [3, 3]))
                        .foregroundStyle(GalacticPalette.severe.opacity(0.7))
                        .annotation(position: .topTrailing, alignment: .trailing) {
                            Text("X10").font(.firaCode(.caption2))
                                .foregroundStyle(GalacticPalette.severe)
                        }
                }
                .chartYScale(type: .log)
                .chartYAxis {
                    AxisMarks(position: .leading, values: [1e-8, 1e-7, 1e-6, 1e-5, 1e-4, 1e-3]) { value in
                        AxisGridLine().foregroundStyle(.white.opacity(0.08))
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text(letterClass(for: v))
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
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(GalacticPalette.deepPurple.opacity(0.42))
        )
    }

    /// Letter label for the bottom of each X-ray decade (A,B,C,M,X,X10).
    private func letterClass(for flux: Double) -> String {
        switch flux {
        case 1e-3...:     return "X10"
        case 1e-4..<1e-3: return "X"
        case 1e-5..<1e-4: return "M"
        case 1e-6..<1e-5: return "C"
        case 1e-7..<1e-6: return "B"
        default:          return "A"
        }
    }
}
