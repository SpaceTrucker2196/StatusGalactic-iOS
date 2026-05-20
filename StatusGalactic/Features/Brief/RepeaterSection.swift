import SwiftUI

struct RepeaterRow: View {
    let repeater: Repeater

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(formattedFreq)
                    .font(.firaCode(.title3, weight: .bold))
                    .foregroundStyle(GalacticPalette.neonCyan)
                    .neonGlow(GalacticPalette.neonCyan, intensity: 5)
                    .monospacedDigit()
                if let offset = repeater.offsetMHz, offset != 0 {
                    Text(offset > 0 ? "+\(String(format: "%.1f", offset))" : String(format: "%.1f", offset))
                        .font(.firaCode(.caption, weight: .semibold))
                        .foregroundStyle(GalacticPalette.peach)
                }
                Spacer()
                Text(repeater.callsign)
                    .font(.firaCode(.subheadline, weight: .bold))
                    .foregroundStyle(GalacticPalette.hotPink)
                    .neonGlow(GalacticPalette.hotPink, intensity: 3)
            }

            HStack(spacing: 6) {
                ForEach(repeater.modes, id: \.self) { mode in
                    Text(mode)
                        .font(.firaCode(.caption2, weight: .semibold))
                        .foregroundStyle(modeColor(mode))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule().fill(modeColor(mode).opacity(0.18))
                        )
                        .overlay(
                            Capsule().stroke(modeColor(mode).opacity(0.7), lineWidth: 0.5)
                        )
                }
                if let pl = repeater.plTone {
                    Label(pl, systemImage: "waveform")
                        .font(.firaCode(.caption2))
                        .foregroundStyle(GalacticPalette.mint)
                }
                Spacer()
                if let status = repeater.operationalStatus,
                   status.lowercased() != "on-air" {
                    Text(status)
                        .font(.firaCode(.caption2))
                        .foregroundStyle(GalacticPalette.storm)
                }
            }

            if let city = repeater.nearestCity {
                Text(city + (repeater.landmark.map { " · \($0)" } ?? ""))
                    .font(.firaCode(.caption2))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }

    private var formattedFreq: String {
        String(format: "%.3f", repeater.frequencyMHz)
    }

    private func modeColor(_ mode: String) -> Color {
        switch mode {
        case "FM", "Analog":  return GalacticPalette.neonCyan
        case "DMR":           return GalacticPalette.neonMagenta
        case "D-Star":        return GalacticPalette.electricBlue
        case "Fusion":        return GalacticPalette.hotPink
        case "P25":           return GalacticPalette.peach
        case "NXDN":          return GalacticPalette.mint
        case "M17":           return GalacticPalette.neonPurple
        case "Tetra":         return GalacticPalette.sunsetOrange
        default:              return GalacticPalette.peach
        }
    }
}
