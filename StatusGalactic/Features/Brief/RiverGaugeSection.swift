import SwiftUI

struct RiverGaugeCard: View {
    let gauge: RiverGauge

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            currentAndForecast
            thresholdsRow
            footer
        }
    }

    private var statusColor: Color {
        switch gauge.floodStatus {
        case .noData, .belowAction: return GalacticPalette.mint
        case .action:               return GalacticPalette.active
        case .minor:                return GalacticPalette.storm
        case .moderate:             return GalacticPalette.neonMagenta
        case .major:                return GalacticPalette.severe
        }
    }

    private var statusLabel: String {
        switch gauge.floodStatus {
        case .noData:       return "no data"
        case .belowAction:  return "Normal"
        case .action:       return "Action"
        case .minor:        return "Minor flood"
        case .moderate:     return "Moderate flood"
        case .major:        return "Major flood"
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "water.waves.and.arrow.trianglehead.up")
                .foregroundStyle(GalacticPalette.electricBlue)
                .neonGlow(GalacticPalette.electricBlue, intensity: 5)
            VStack(alignment: .leading, spacing: 0) {
                Text(gauge.name)
                    .font(.firaCode(.headline, weight: .bold))
                    .foregroundStyle(GalacticPalette.neonCyan)
                Text("LID \(gauge.lid) • \(distanceLabel)")
                    .font(.firaCode(.caption2))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(statusLabel)
                .font(.firaCode(.caption, weight: .bold))
                .foregroundStyle(statusColor)
                .neonGlow(statusColor, intensity: 4)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(statusColor.opacity(0.15)))
                .overlay(Capsule().stroke(statusColor, lineWidth: 0.6))
        }
    }

    private var distanceLabel: String {
        let km = gauge.distanceKm
        let mi = km * 0.6213711922
        return String(format: "%.0f mi (%.0f km) away", mi, km)
    }

    @ViewBuilder
    private var currentAndForecast: some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            if let stage = gauge.currentStageFt {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Current")
                        .font(.firaCode(.caption2))
                        .foregroundStyle(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.1f", stage))
                            .font(.firaCode(.title2, weight: .bold))
                            .foregroundStyle(statusColor)
                            .neonGlow(statusColor, intensity: 4)
                            .monospacedDigit()
                        Text("ft")
                            .font(.firaCode(.caption))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            if let peak = gauge.forecastPeakFt {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Forecast peak")
                        .font(.firaCode(.caption2))
                        .foregroundStyle(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.1f", peak))
                            .font(.firaCode(.headline, weight: .bold))
                            .foregroundStyle(GalacticPalette.hotPink)
                            .monospacedDigit()
                        Text("ft")
                            .font(.firaCode(.caption2))
                            .foregroundStyle(.secondary)
                    }
                    if let at = gauge.forecastPeakAt {
                        Text(at, style: .relative)
                            .font(.firaCode(.caption2))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
        }
    }

    @ViewBuilder
    private var thresholdsRow: some View {
        let pairs: [(String, Double?, Color)] = [
            ("Action",   gauge.actionStageFt,        GalacticPalette.active),
            ("Minor",    gauge.minorFloodStageFt,    GalacticPalette.storm),
            ("Moderate", gauge.moderateFloodStageFt, GalacticPalette.neonMagenta),
            ("Major",    gauge.majorFloodStageFt,    GalacticPalette.severe),
        ]
        let present = pairs.filter { $0.1 != nil }
        if !present.isEmpty {
            HStack(spacing: 12) {
                ForEach(present.indices, id: \.self) { i in
                    let (label, value, color) = present[i]
                    VStack(alignment: .leading, spacing: 0) {
                        Text(label)
                            .font(.firaCode(.caption2))
                            .foregroundStyle(color)
                        Text(String(format: "%.1f ft", value ?? 0))
                            .font(.firaCode(.caption, weight: .semibold))
                            .foregroundStyle(.primary)
                            .monospacedDigit()
                    }
                }
                Spacer()
            }
        }
    }

    private var footer: some View {
        Text("Observed " +
             (gauge.observedAt.map { "\($0.formatted(.relative(presentation: .named)))" } ?? "—") +
             " • NOAA NWPS")
            .font(.firaCode(.caption2))
            .foregroundStyle(.secondary)
    }
}
