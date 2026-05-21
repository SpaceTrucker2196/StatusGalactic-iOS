import SwiftUI

/// Footer-style chrono panel: Local Sidereal Time, GMST, and Julian Date.
struct SiderealFooter: View {
    let when: Date
    let longitudeEastDeg: Double

    private var clock: SiderealClock {
        SiderealClock(when: when, longitudeEastDeg: longitudeEastDeg)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "globe")
                    .foregroundStyle(GalacticPalette.neonCyan)
                    .neonGlow(GalacticPalette.neonCyan, intensity: 5)
                Text("Sidereal")
                    .font(.firaCode(.subheadline, weight: .bold))
                    .foregroundStyle(GalacticPalette.neonCyan)
                Spacer()
                Text(String(format: "JD %.4f", clock.julianDate))
                    .font(.firaCode(.caption2))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            HStack(spacing: 12) {
                clockColumn(label: "LST", value: clock.lstFormatted, accent: GalacticPalette.hotPink)
                clockColumn(label: "GMST", value: clock.gmstFormatted, accent: GalacticPalette.electricBlue)
            }
        }
    }

    private func clockColumn(label: String, value: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.firaCode(.caption2))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.firaCode(.title3, weight: .bold))
                .foregroundStyle(accent)
                .neonGlow(accent, intensity: 5)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
