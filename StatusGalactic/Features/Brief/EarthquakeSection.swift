import SwiftUI

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
