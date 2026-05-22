import SwiftUI
import Charts

/// Compact bar chart of recent earthquake magnitudes. Each event is one
/// bar; bars sit on the event timestamp and color by magnitude band.
struct EarthquakeTimelineChart: View {
    let quakes: [Earthquake]

    var body: some View {
        Chart {
            ForEach(quakes) { q in
                BarMark(
                    x: .value("When", q.time),
                    y: .value("Mag", q.magnitude)
                )
                .foregroundStyle(magColor(q.magnitude))
            }
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
        .frame(height: 90)
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

struct EarthquakeRow: View {
    let quake: Earthquake

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                MagnitudePill(magnitude: quake.magnitude)
                Text(quake.place)
                    .font(.firaCode(.subheadline, weight: .semibold))
                    .foregroundStyle(GalacticPalette.neonCyan)
                    .lineLimit(1)
                Spacer()
                if quake.isSignificant {
                    Text("SIG")
                        .font(.firaCode(.caption2, weight: .bold))
                        .foregroundStyle(GalacticPalette.severe)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(GalacticPalette.severe.opacity(0.18)))
                        .overlay(Capsule().stroke(GalacticPalette.severe, lineWidth: 0.5))
                }
            }
            HStack(spacing: 8) {
                Text(quake.time, style: .relative)
                    .font(.firaCode(.caption))
                    .foregroundStyle(GalacticPalette.hotPink)
                Spacer()
                Text(String(format: "%.0f km deep", quake.depthKm))
                    .font(.firaCode(.caption2))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                if let d = quake.distanceKm {
                    Text(String(format: "Δ %.0f km", d))
                        .font(.firaCode(.caption2, weight: .semibold))
                        .foregroundStyle(GalacticPalette.peach)
                        .monospacedDigit()
                }
            }
        }
        .padding(.vertical, 2)
    }
}

private struct MagnitudePill: View {
    let magnitude: Double

    var body: some View {
        Text(String(format: "M%.1f", magnitude))
            .font(.firaCode(.subheadline, weight: .bold))
            .foregroundStyle(.black)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(color))
            .neonGlow(color, intensity: 4)
            .monospacedDigit()
    }

    private var color: Color {
        switch magnitude {
        case ..<3:   return GalacticPalette.mint
        case ..<4.5: return GalacticPalette.peach
        case ..<6:   return GalacticPalette.sunsetOrange
        case ..<7:   return GalacticPalette.hotPink
        default:     return GalacticPalette.severe
        }
    }
}
