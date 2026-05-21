import SwiftUI
import Charts

// MARK: - D-region absorption (HF blackout) image

/// SolarHam-style "HF Radio Blackout" panel — the global D-RAP overlay
/// showing live D-region absorption from solar X-ray flares. Image is
/// updated every minute by NOAA; the CachedAsyncImage layer dedupes hits.
struct DRAPPanel: View {
    static let url = URL(string:
        "https://services.swpc.noaa.gov/images/animations/d-rap/global/d-rap_global_latest.png"
    )!

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("HF Radio Blackout (D-RAP)")
                .font(.firaCode(.subheadline, weight: .semibold))
                .foregroundStyle(GalacticPalette.peach)
            CachedAsyncImage(
                url: Self.url,
                placeholder: {
                    ZStack {
                        Color.black
                        ProgressView().tint(GalacticPalette.neonCyan)
                    }
                    .aspectRatio(2, contentMode: .fit)
                },
                failure: {
                    ZStack {
                        Color.black
                        Label("D-RAP image unavailable", systemImage: "antenna.radiowaves.left.and.right.slash")
                            .font(.firaCode(.caption))
                            .foregroundStyle(GalacticPalette.peach.opacity(0.7))
                    }
                    .aspectRatio(2, contentMode: .fit)
                }
            )
            .aspectRatio(contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            Text("D-region absorption (dB) — current solar X-ray impact on HF.")
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
}

// MARK: - DONKI CME tracker

struct CMETrackerPanel: View {
    let cmes: [CMEEvent]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Recent CMEs")
                    .font(.firaCode(.subheadline, weight: .semibold))
                    .foregroundStyle(GalacticPalette.peach)
                Spacer()
                Text("NASA DONKI · 5d")
                    .font(.firaCode(.caption2))
                    .foregroundStyle(.secondary)
            }
            ForEach(cmes) { cme in
                cmeRow(cme)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(GalacticPalette.deepPurple.opacity(0.42))
        )
    }

    private func cmeRow(_ c: CMEEvent) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 8) {
                Image(systemName: c.isHalo ? "sun.haze.fill" : "burst.fill")
                    .foregroundStyle(c.isHalo ? GalacticPalette.severe : GalacticPalette.hotPink)
                    .neonGlow(c.isHalo ? GalacticPalette.severe : GalacticPalette.hotPink, intensity: 3)
                Text(c.startTime, style: .relative)
                    .font(.firaCode(.caption, weight: .semibold))
                    .foregroundStyle(GalacticPalette.neonCyan)
                Spacer()
                if c.isHalo {
                    Text("HALO")
                        .font(.firaCode(.caption2, weight: .bold))
                        .foregroundStyle(GalacticPalette.severe)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(GalacticPalette.severe.opacity(0.18)))
                        .overlay(Capsule().stroke(GalacticPalette.severe, lineWidth: 0.5))
                }
            }
            HStack(spacing: 10) {
                if let src = c.sourceLocation, !src.isEmpty {
                    Text(src)
                        .font(.firaCode(.caption2, weight: .semibold))
                        .foregroundStyle(GalacticPalette.peach)
                }
                if let v = c.speedKmS {
                    Text(String(format: "%.0f km/s", v))
                        .font(.firaCode(.caption2))
                        .foregroundStyle(GalacticPalette.hotPink)
                        .monospacedDigit()
                }
                if let arr = c.arrivalEstimateUtc {
                    Text("ETA \(arr, style: .relative)")
                        .font(.firaCode(.caption2))
                        .foregroundStyle(GalacticPalette.electricBlue)
                }
                Spacer()
            }
            if let note = c.note, !note.isEmpty {
                Text(note)
                    .font(.firaCode(.caption2))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - 27-day outlook

struct SolarOutlookPanel: View {
    let days: [SolarOutlookDay]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("27-day Outlook")
                    .font(.firaCode(.subheadline, weight: .semibold))
                    .foregroundStyle(GalacticPalette.peach)
                Spacer()
                Text("F10.7 · Ap · Kp")
                    .font(.firaCode(.caption2))
                    .foregroundStyle(.secondary)
            }
            fluxChart
            apKpChart
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(GalacticPalette.deepPurple.opacity(0.42))
        )
    }

    private var fluxChart: some View {
        Chart {
            ForEach(days) { d in
                LineMark(
                    x: .value("Day", d.date),
                    y: .value("F10.7", d.radioFlux)
                )
                .foregroundStyle(GalacticPalette.sun)
                .lineStyle(StrokeStyle(lineWidth: 2))
                AreaMark(
                    x: .value("Day", d.date),
                    y: .value("F10.7", d.radioFlux)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [GalacticPalette.sun.opacity(0.4), GalacticPalette.sun.opacity(0.02)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
            }
            RuleMark(y: .value("Good HF", 100))
                .lineStyle(StrokeStyle(lineWidth: 0.6, dash: [3, 3]))
                .foregroundStyle(GalacticPalette.electricBlue.opacity(0.5))
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                AxisGridLine().foregroundStyle(.white.opacity(0.08))
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
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

    private var apKpChart: some View {
        Chart {
            ForEach(days) { d in
                BarMark(
                    x: .value("Day", d.date),
                    y: .value("Ap", d.aIndex)
                )
                .foregroundStyle(GalacticPalette.kp(Double(d.largestKp)))
            }
            RuleMark(y: .value("Storm", 30))
                .lineStyle(StrokeStyle(lineWidth: 0.6, dash: [3, 3]))
                .foregroundStyle(GalacticPalette.storm.opacity(0.6))
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                AxisGridLine().foregroundStyle(.white.opacity(0.08))
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
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
        .frame(height: 80)
    }
}
