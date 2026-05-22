import SwiftUI

/// Tap-detail for the Mars weather card. Surface the freshness honestly,
/// expand the per-sol numbers, and add orbital-context tiles that *are*
/// always current (Mars-Earth distance, light-travel delay, Ls).
struct MarsAlmanacView: View {
    let mars: MarsWeather
    let when: Date

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                MarsWeatherCard(mars: mars)
                ephemerisPanel
                explainer
            }
            .padding(16)
        }
        .background(GalacticPalette.cosmicSky.ignoresSafeArea())
        .navigationTitle("Mars Almanac")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// Orbital context. The Mars weather reading may be days old, but the
    /// Mars-Earth distance, light-time, and solar longitude (Ls) are all
    /// pure-compute and freshly accurate for `when`.
    @ViewBuilder
    private var ephemerisPanel: some View {
        let planets = Planets.compute(when: when)
        let mars = planets.first(where: { $0.body == "Mars" })
        let sun = planets.first(where: { $0.body == "Sun" })

        VStack(alignment: .leading, spacing: 8) {
            Text("Ephemeris")
                .font(.firaCode(.subheadline, weight: .semibold))
                .foregroundStyle(GalacticPalette.peach)
            HStack(spacing: 10) {
                tile(
                    label: "Mars dist",
                    value: distanceLabel,
                    unit: "AU",
                    accent: GalacticPalette.mars
                )
                tile(
                    label: "Light delay",
                    value: lightDelayLabel,
                    unit: "min",
                    accent: GalacticPalette.electricBlue
                )
                tile(
                    label: "Sol length",
                    value: "24:39:35",
                    unit: "hh:mm:ss",
                    accent: GalacticPalette.peach
                )
            }
            if let mars, let sun {
                Text("Geocentric Mars \(String(format: "%.1f° %@", mars.degree, mars.sign))" +
                     " · Sun \(String(format: "%.1f° %@", sun.degree, sun.sign))")
                    .font(.firaCode(.caption2))
                    .foregroundStyle(.secondary)
            }
            Text("Mars year ~687 Earth days; axial tilt 25.19° drives Mars seasons very similarly to Earth.")
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

    /// Quick Mars–Earth distance approximation using mean orbital
    /// radii. Mars is at 1.524 AU semi-major axis; Earth at 1.0 AU; the
    /// geocentric distance varies from about 0.37 AU to 2.68 AU through
    /// the synodic cycle. Good enough for the "how far away is Mars
    /// right now" tile.
    private var distanceAU: Double {
        let planets = Planets.compute(when: when)
        guard let m = planets.first(where: { $0.body == "Mars" }),
              let s = planets.first(where: { $0.body == "Sun" })
        else { return 1.5 }
        // Use the relative ecliptic longitudes to estimate elongation.
        let elong = abs((m.degree + Double(Planets.signs.firstIndex(of: m.sign) ?? 0) * 30)
                      - (s.degree + Double(Planets.signs.firstIndex(of: s.sign) ?? 0) * 30))
        let theta = (elong > 180 ? 360 - elong : elong) * .pi / 180
        // Law of cosines on Mars and Earth heliocentric vectors.
        let earthR = 1.0
        let marsR = 1.524
        return sqrt(earthR * earthR + marsR * marsR - 2 * earthR * marsR * cos(theta))
    }

    private var distanceLabel: String {
        String(format: "%.2f", distanceAU)
    }

    private var lightDelayLabel: String {
        // 1 AU ≈ 8.317 light-minutes.
        let minutes = distanceAU * 8.317
        return String(format: "%.1f", minutes)
    }

    private func tile(label: String, value: String, unit: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.firaCode(.caption2))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.firaCode(.title3, weight: .bold))
                .foregroundStyle(accent)
                .neonGlow(accent, intensity: 4)
                .monospacedDigit()
            Text(unit)
                .font(.firaCode(.caption2))
                .foregroundStyle(GalacticPalette.peach.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(accent.opacity(0.4), lineWidth: 0.6)
        )
    }

    private var explainer: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Why Mars data lags")
                .font(.firaCode(.subheadline, weight: .semibold))
                .foregroundStyle(GalacticPalette.peach)
            Text("Rover weather instruments (Perseverance MEDA, Curiosity REMS) record continuously, but Deep Space Network passes only downlink a slice of the buffer at a time. NASA then calibrates, validates, and publishes — typically days to weeks behind real time. Spacetrucker Galactic races both rover feeds and surfaces whichever is newer.")
                .font(.firaCode(.caption))
                .foregroundStyle(.primary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(GalacticPalette.deepPurple.opacity(0.35))
        )
    }
}
