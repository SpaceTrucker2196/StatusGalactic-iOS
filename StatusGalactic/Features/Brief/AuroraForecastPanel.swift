import SwiftUI

/// OVATION-derived local aurora probability with a horizontal probability
/// bar and the global oval-peak number for context.
struct AuroraForecastPanel: View {
    let forecast: AuroraForecast

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "aqi.medium")
                    .foregroundStyle(GalacticPalette.neonMagenta)
                    .neonGlow(GalacticPalette.neonMagenta, intensity: 5)
                Text("Aurora at your location")
                    .font(.firaCode(.subheadline, weight: .semibold))
                    .foregroundStyle(GalacticPalette.peach)
                Spacer()
                if let when = forecast.forecastFor {
                    Text(when, style: .relative)
                        .font(.firaCode(.caption2))
                        .foregroundStyle(.secondary)
                }
            }
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text("\(forecast.localProbabilityPct)%")
                    .font(.firaCode(.largeTitle, weight: .bold))
                    .foregroundStyle(accent)
                    .neonGlow(accent, intensity: 7)
                    .monospacedDigit()
                Text("local probability")
                    .font(.firaCode(.caption))
                    .foregroundStyle(.secondary)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Oval peak")
                        .font(.firaCode(.caption2))
                        .foregroundStyle(.secondary)
                    Text("\(forecast.globalMaxPct)%")
                        .font(.firaCode(.subheadline, weight: .semibold))
                        .foregroundStyle(GalacticPalette.hotPink)
                        .monospacedDigit()
                }
            }
            probabilityBar
            Text("NOAA SWPC OVATION · 30-min forecast")
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

    private var accent: Color {
        switch forecast.localProbabilityPct {
        case ..<5:   return GalacticPalette.mint
        case ..<15:  return GalacticPalette.peach
        case ..<35:  return GalacticPalette.hotPink
        case ..<60:  return GalacticPalette.neonMagenta
        default:     return GalacticPalette.severe
        }
    }

    private var probabilityBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(GalacticPalette.cosmicBlack.opacity(0.7))
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: [accent.opacity(0.7), accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * CGFloat(forecast.localProbabilityPct) / 100)
                    .neonGlow(accent, intensity: 5)
            }
        }
        .frame(height: 8)
    }
}
