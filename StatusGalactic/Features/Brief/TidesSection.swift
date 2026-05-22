import SwiftUI
import Charts

struct TidesCard: View {
    let tides: Tides
    let timezoneName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            tideCurve
            ForEach(upcoming) { event in
                TideRow(event: event, timezoneName: timezoneName)
            }
            footer
        }
    }

    /// Smooth Catmull-Rom interpolation through the published high/low
    /// events gives a serviceable approximation of the tide curve. The
    /// PointMark glyphs sit on each event so the reader can still spot
    /// the discrete predictions.
    @ViewBuilder
    private var tideCurve: some View {
        let visible = Array(tides.events.prefix(8))
        if visible.count >= 2 {
            Chart {
                ForEach(visible) { event in
                    LineMark(
                        x: .value("Time", event.time),
                        y: .value("Ft", event.heightFt)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(GalacticPalette.electricBlue)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    AreaMark(
                        x: .value("Time", event.time),
                        y: .value("Ft", event.heightFt)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                GalacticPalette.electricBlue.opacity(0.4),
                                GalacticPalette.electricBlue.opacity(0.02)
                            ],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    PointMark(
                        x: .value("Time", event.time),
                        y: .value("Ft", event.heightFt)
                    )
                    .foregroundStyle(event.kind == .high
                                     ? GalacticPalette.hotPink
                                     : GalacticPalette.electricBlue)
                    .symbolSize(40)
                }
                if let now = (tides.events.first { $0.time >= Date() })?.time {
                    RuleMark(x: .value("Now", now))
                        .lineStyle(StrokeStyle(lineWidth: 0.7, dash: [3, 3]))
                        .foregroundStyle(GalacticPalette.neonCyan.opacity(0.7))
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .hour, count: 12)) { _ in
                    AxisGridLine().foregroundStyle(.white.opacity(0.08))
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated).hour())
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
            .frame(height: 90)
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "water.waves")
                .foregroundStyle(GalacticPalette.electricBlue)
                .neonGlow(GalacticPalette.electricBlue, intensity: 5)
            VStack(alignment: .leading, spacing: 0) {
                Text(tides.stationName)
                    .font(.firaCode(.headline, weight: .bold))
                    .foregroundStyle(GalacticPalette.neonCyan)
                Text("Station \(tides.stationId) • \(distanceLabel)")
                    .font(.firaCode(.caption2))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var distanceLabel: String {
        let km = tides.distanceKm
        let mi = km * 0.6213711922
        return String(format: "%.0f mi (%.0f km) away", mi, km)
    }

    private var upcoming: [TideEvent] {
        let now = Date()
        let future = tides.events.filter { $0.time >= now }
        if future.isEmpty {
            // Predictions older than now (could happen near midnight UTC).
            return Array(tides.events.suffix(4))
        }
        return Array(future.prefix(4))
    }

    private var footer: some View {
        Text("Predictions from NOAA CO-OPS · MLLW datum")
            .font(.firaCode(.caption2))
            .foregroundStyle(.secondary)
    }
}

private struct TideRow: View {
    let event: TideEvent
    let timezoneName: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: event.kind == .high ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .foregroundStyle(color)
                .neonGlow(color, intensity: 3)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(event.kind == .high ? "High" : "Low")
                        .font(.firaCode(.subheadline, weight: .bold))
                        .foregroundStyle(color)
                    Text(localTime)
                        .font(.firaCode(.subheadline))
                        .foregroundStyle(GalacticPalette.peach)
                }
                Text(event.time, style: .relative)
                    .font(.firaCode(.caption2))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(String(format: "%.1f ft", event.heightFt))
                .font(.firaCode(.subheadline, weight: .semibold))
                .foregroundStyle(GalacticPalette.neonCyan)
                .neonGlow(GalacticPalette.neonCyan, intensity: 3)
                .monospacedDigit()
        }
    }

    private var color: Color {
        event.kind == .high ? GalacticPalette.hotPink : GalacticPalette.electricBlue
    }

    private var localTime: String {
        let f = DateFormatter()
        f.timeZone = TimeZone(identifier: timezoneName) ?? .current
        f.dateFormat = "EEE h:mm a"
        return f.string(from: event.time)
    }
}
