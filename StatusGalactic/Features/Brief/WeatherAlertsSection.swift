import SwiftUI

struct WeatherAlertCard: View {
    let alert: WeatherAlert

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(accent)
                    .neonGlow(accent, intensity: 6)
                VStack(alignment: .leading, spacing: 1) {
                    Text(alert.event)
                        .font(.firaCode(.headline, weight: .bold))
                        .foregroundStyle(accent)
                        .neonGlow(accent, intensity: 5)
                    if let area = alert.areaDesc {
                        Text(area)
                            .font(.firaCode(.caption2))
                            .foregroundStyle(GalacticPalette.peach)
                            .lineLimit(1)
                    }
                }
                Spacer()
                Text(alert.severity.uppercased())
                    .font(.firaCode(.caption2, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(accent))
            }
            if let headline = alert.headline {
                Text(headline)
                    .font(.firaCode(.caption, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(3)
            }
            HStack(spacing: 8) {
                if let onset = alert.onsetAt {
                    Text("Onset \(onset, style: .relative)")
                        .font(.firaCode(.caption2))
                        .foregroundStyle(.secondary)
                }
                if let expires = alert.expiresAt {
                    Text("expires \(expires, style: .relative)")
                        .font(.firaCode(.caption2))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            if let instruction = alert.instruction, !instruction.isEmpty {
                DisclosureGroup {
                    Text(instruction)
                        .font(.firaCode(.caption))
                        .foregroundStyle(.primary)
                        .padding(.top, 4)
                } label: {
                    Text("Instructions")
                        .font(.firaCode(.caption, weight: .semibold))
                        .foregroundStyle(accent)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(accent.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(accent.opacity(0.6), lineWidth: 1)
        )
    }

    private var accent: Color {
        switch alert.severityLevel {
        case 4: return GalacticPalette.severe       // Extreme
        case 3: return GalacticPalette.storm        // Severe
        case 2: return GalacticPalette.sunsetOrange // Moderate
        case 1: return GalacticPalette.peach        // Minor
        default: return GalacticPalette.electricBlue
        }
    }

    private var icon: String {
        let upper = alert.event.uppercased()
        if upper.contains("TORNADO")              { return "tornado" }
        if upper.contains("HURRICANE")            { return "hurricane" }
        if upper.contains("FLOOD")                { return "drop.triangle.fill" }
        if upper.contains("THUNDER")              { return "cloud.bolt.fill" }
        if upper.contains("WINTER") ||
           upper.contains("SNOW") ||
           upper.contains("ICE") ||
           upper.contains("BLIZZARD")             { return "snowflake" }
        if upper.contains("WIND")                 { return "wind" }
        if upper.contains("HEAT")                 { return "thermometer.sun.fill" }
        if upper.contains("FIRE")                 { return "flame.fill" }
        if upper.contains("FOG")                  { return "cloud.fog.fill" }
        return "exclamationmark.triangle.fill"
    }
}
