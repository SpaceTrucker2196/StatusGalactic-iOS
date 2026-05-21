import SwiftUI
import Charts

/// Long-term solar-cycle progression — monthly sunspot number (or F10.7)
/// over the last ~5 years with the smoothed line overlaid so the trend
/// past solar max stands out.
struct SolarCyclePanel: View {
    let points: [SolarCyclePoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("Solar cycle")
                    .font(.firaCode(.subheadline, weight: .semibold))
                    .foregroundStyle(GalacticPalette.peach)
                Spacer()
                if let last = points.last {
                    Text(String(format: "SSN %.0f · F10.7 %.0f", last.sunspotNumber, last.radioFlux))
                        .font(.firaCode(.caption2, weight: .semibold))
                        .foregroundStyle(GalacticPalette.sun)
                        .monospacedDigit()
                }
            }
            ssnChart
            Text("NOAA observed indices · trailing 5 years")
                .font(.firaCode(.caption2))
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(GalacticPalette.deepPurple.opacity(0.42))
        )
    }

    private var ssnChart: some View {
        let smoothed = points.compactMap { p in
            p.smoothedSunspotNumber.map { (month: p.month, value: $0) }
        }
        return Chart {
            ForEach(points) { p in
                BarMark(
                    x: .value("Month", p.month),
                    y: .value("SSN", p.sunspotNumber)
                )
                .foregroundStyle(GalacticPalette.sun.opacity(0.5))
            }
            ForEach(smoothed, id: \.month) { s in
                LineMark(
                    x: .value("Month", s.month),
                    y: .value("Smoothed", s.value)
                )
                .foregroundStyle(GalacticPalette.hotPink)
                .lineStyle(StrokeStyle(lineWidth: 2))
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .year, count: 1)) { _ in
                AxisGridLine().foregroundStyle(.white.opacity(0.08))
                AxisValueLabel(format: .dateTime.year())
                    .font(.firaCode(.caption2))
                    .foregroundStyle(GalacticPalette.peach.opacity(0.7))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine().foregroundStyle(.white.opacity(0.08))
                AxisValueLabel()
                    .font(.firaCode(.caption2))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 110)
    }
}
