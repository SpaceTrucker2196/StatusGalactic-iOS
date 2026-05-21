import SwiftUI

/// Footer-style chrono panel: Local Sidereal Time, GMST, and Julian Date.
struct SiderealFooter: View {
    let when: Date
    let longitudeEastDeg: Double
    let magnetic: MagneticDeclination?

    init(when: Date, longitudeEastDeg: Double, magnetic: MagneticDeclination? = nil) {
        self.when = when
        self.longitudeEastDeg = longitudeEastDeg
        self.magnetic = magnetic
    }

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
                if let magnetic {
                    clockColumn(
                        label: "Mag dec",
                        value: magnetic.formatted,
                        accent: GalacticPalette.mint
                    )
                }
            }
            if let magnetic, let model = magnetic.model {
                Text("\(model) · point compass \(magnetic.formatted) off true north")
                    .font(.firaCode(.caption2))
                    .foregroundStyle(.secondary)
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
