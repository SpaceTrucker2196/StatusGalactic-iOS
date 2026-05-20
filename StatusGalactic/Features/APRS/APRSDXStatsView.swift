import SwiftUI

struct APRSDXStatsView: View {
    let stats: APRSDXStats

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            row(label: "Today",      entry: stats.today)
            row(label: "This month", entry: stats.month)
            row(label: "This year",  entry: stats.year)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func row(label: String, entry: APRSDXEntry?) -> some View {
        HStack(spacing: 10) {
            Image(systemName: iconFor(label))
                .foregroundStyle(GalacticPalette.hotPink)
                .neonGlow(GalacticPalette.hotPink, intensity: 3)
                .frame(width: 22)
            Text(label)
                .font(.firaCode(.caption, weight: .semibold))
                .foregroundStyle(GalacticPalette.peach)
                .frame(width: 88, alignment: .leading)
            if let entry {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.0f mi", entry.distanceMi))
                            .font(.firaCode(.headline, weight: .bold))
                            .foregroundStyle(GalacticPalette.neonCyan)
                            .neonGlow(GalacticPalette.neonCyan, intensity: 4)
                        Text(String(format: "(%.0f km)", entry.distanceKm))
                            .font(.firaCode(.caption2))
                            .foregroundStyle(.secondary)
                    }
                    Text(entry.callsign)
                        .font(.firaCode(.caption, weight: .semibold))
                        .foregroundStyle(GalacticPalette.hotPink)
                        .neonGlow(GalacticPalette.hotPink, intensity: 2)
                }
            } else {
                Text("—")
                    .font(.firaCode(.headline))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private func iconFor(_ label: String) -> String {
        switch label {
        case "Today":      return "sun.max.fill"
        case "This month": return "calendar"
        case "This year":  return "calendar.badge.clock"
        default:           return "arrow.up.right"
        }
    }
}
