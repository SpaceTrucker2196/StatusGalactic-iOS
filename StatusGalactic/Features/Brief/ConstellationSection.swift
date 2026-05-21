import SwiftUI

struct ConstellationRow: View {
    let summary: ConstellationSummary

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(accent)
                .neonGlow(accent, intensity: 5)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(summary.name)
                    .font(.firaCode(.headline, weight: .semibold))
                    .foregroundStyle(GalacticPalette.neonCyan)
                if let when = summary.latestEpochAt {
                    Text("Latest element-set \(when, style: .relative) ago")
                        .font(.firaCode(.caption2))
                        .foregroundStyle(.secondary)
                } else {
                    Text("Celestrak GP · \(summary.group)")
                        .font(.firaCode(.caption2))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(summary.count)")
                    .font(.firaCode(.title2, weight: .bold))
                    .foregroundStyle(accent)
                    .neonGlow(accent, intensity: 6)
                    .monospacedDigit()
                Text("active")
                    .font(.firaCode(.caption2))
                    .foregroundStyle(GalacticPalette.peach)
            }
        }
        .padding(.vertical, 2)
    }

    private var icon: String {
        switch summary.group {
        case "starlink":      return "dot.radiowaves.up.forward"
        case "gps-ops":       return "location.viewfinder"
        default:              return "antenna.radiowaves.left.and.right"
        }
    }

    private var accent: Color {
        switch summary.group {
        case "starlink":      return GalacticPalette.hotPink
        case "gps-ops":       return GalacticPalette.electricBlue
        default:              return GalacticPalette.neonCyan
        }
    }
}
