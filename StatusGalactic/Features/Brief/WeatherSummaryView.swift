import SwiftUI

/// Compact single-period weather headline rendered in the same neon-cyan
/// glowing style as the location title above it. Replaces the older multi-
/// period list. Tap target opens an almanac-style detail (TBD).
struct WeatherSummaryView: View {
    let period: WeatherPeriod

    private var iconName: String {
        GalacticSymbols.weatherSymbol(
            for: period.shortForecast,
            isDaytime: period.isDaytime
        )
    }

    private var iconColor: Color {
        period.isDaytime ? GalacticPalette.sun : GalacticPalette.electricBlue
    }

    private var tempColor: Color {
        if let t = period.temperature { return GalacticPalette.temperature(t) }
        return GalacticPalette.neonCyan
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundStyle(iconColor)
                    .neonGlow(iconColor, intensity: 6)

                if let temp = period.temperature {
                    Text("\(temp)°")
                        .font(.firaCode(.title, weight: .bold))
                        .foregroundStyle(tempColor)
                        .neonGlow(tempColor, intensity: 6)
                        .monospacedDigit()
                }

                Spacer()

                Text(period.name)
                    .font(.firaCode(.caption, weight: .semibold))
                    .foregroundStyle(GalacticPalette.peach)
            }

            Text(period.shortForecast)
                .font(.firaCode(.subheadline))
                .foregroundStyle(.primary)
                .lineLimit(2)

            if let wind = period.wind, !wind.isEmpty {
                Label(wind, systemImage: "wind")
                    .font(.firaCode(.caption))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
