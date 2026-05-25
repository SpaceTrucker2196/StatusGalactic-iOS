import SwiftUI

/// R/S/G storm-scale pills near the top of the brief — NOAA's three
/// space-weather storm scales, mirroring the badges SolarHam shows. Each
/// pill collapses to "—" if its underlying feed missed. Stacked
/// vertically so each row gets its full pill width for the radio /
/// solar / geomagnetic context plus value.
struct StormScaleRow: View {
    let brief: Brief

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            scale(
                letter: "R",
                level: brief.xRay?.rScale ?? "R0",
                value: brief.xRay?.peakClass24h ?? "—",
                tag: "Radio"
            )
            scale(
                letter: "S",
                level: brief.proton?.sScale ?? "S0",
                value: brief.proton.map { String(format: "%.1f pfu", $0.fluxPfu) } ?? "—",
                tag: "Solar"
            )
            scale(
                letter: "G",
                level: gScale,
                value: brief.space?.kpIndex.map { String(format: "Kp %.1f", $0) } ?? "—",
                tag: "Geomag"
            )
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var gScale: String {
        guard let kp = brief.space?.kpIndex else { return "G0" }
        return SpaceWeatherForecastClient.gScaleString(forKp: kp)
    }

    private func scale(letter: String, level: String, value: String, tag: String) -> some View {
        let accent = Self.color(forLevel: level)
        return VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 4) {
                Text(level)
                    .font(.firaCode(.headline, weight: .bold))
                    .foregroundStyle(accent)
                    .neonGlow(accent, intensity: 5)
                Spacer()
                Text(tag)
                    .font(.firaCode(.caption2))
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.firaCode(.caption2, weight: .semibold))
                .foregroundStyle(GalacticPalette.peach)
                .monospacedDigit()
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(accent.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(accent.opacity(0.55), lineWidth: 0.75)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(tag) storm scale \(level), \(value)")
    }

    static func color(forLevel level: String) -> Color {
        // R/S/G last digit gives severity 0..5.
        let digit = level.last.flatMap { Int(String($0)) } ?? 0
        switch digit {
        case 0:   return GalacticPalette.mint
        case 1:   return GalacticPalette.peach
        case 2:   return GalacticPalette.sunsetOrange
        case 3:   return GalacticPalette.hotPink
        case 4:   return GalacticPalette.severe
        default:  return GalacticPalette.severe
        }
    }
}
