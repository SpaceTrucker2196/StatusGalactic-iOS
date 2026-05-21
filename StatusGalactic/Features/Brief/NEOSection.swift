import SwiftUI

struct NEORow: View {
    let neo: NearEarthObject

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: neo.isHazardous ? "exclamationmark.triangle.fill" : "asterisk")
                    .foregroundStyle(neo.isHazardous ? GalacticPalette.severe : GalacticPalette.peach)
                    .neonGlow(neo.isHazardous ? GalacticPalette.severe : GalacticPalette.peach, intensity: 3)
                Text(neo.name)
                    .font(.firaCode(.subheadline, weight: .bold))
                    .foregroundStyle(GalacticPalette.neonCyan)
                    .lineLimit(1)
                Spacer()
                if neo.isHazardous {
                    Text("PHA")
                        .font(.firaCode(.caption2, weight: .bold))
                        .foregroundStyle(GalacticPalette.severe)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(GalacticPalette.severe.opacity(0.18)))
                        .overlay(Capsule().stroke(GalacticPalette.severe, lineWidth: 0.5))
                }
            }
            HStack(spacing: 8) {
                Text(neo.approachAt, style: .relative)
                    .font(.firaCode(.caption))
                    .foregroundStyle(GalacticPalette.hotPink)
                Spacer()
                Text("Δ \(formattedDistance(neo.missDistanceKm))")
                    .font(.firaCode(.caption, weight: .semibold))
                    .foregroundStyle(GalacticPalette.neonCyan)
                    .neonGlow(GalacticPalette.neonCyan, intensity: 3)
                    .monospacedDigit()
            }
            HStack(spacing: 8) {
                Text("Ø \(Int(neo.diameterMinM))-\(Int(neo.diameterMaxM)) m")
                    .font(.firaCode(.caption2))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "%.1f km/s", neo.velocityKps))
                    .font(.firaCode(.caption2))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .padding(.vertical, 2)
    }

    private func formattedDistance(_ km: Double) -> String {
        let lunar = km / 384_400.0
        if lunar < 1.0 {
            return String(format: "%.2f LD · %.0f km", lunar, km)
        }
        return String(format: "%.1f LD · %.0f km", lunar, km)
    }
}

struct InterstellarRow: View {
    let obj: InterstellarObject

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles.rectangle.stack")
                    .foregroundStyle(GalacticPalette.neonPurple)
                    .neonGlow(GalacticPalette.neonPurple, intensity: 4)
                Text(obj.designation)
                    .font(.firaCode(.subheadline, weight: .bold))
                    .foregroundStyle(GalacticPalette.neonCyan)
                Spacer()
                Text(obj.discoveryDate)
                    .font(.firaCode(.caption2))
                    .foregroundStyle(GalacticPalette.peach)
            }
            Text(obj.status)
                .font(.firaCode(.caption, weight: .semibold))
                .foregroundStyle(GalacticPalette.hotPink)
            Text(obj.notes)
                .font(.firaCode(.caption2))
                .foregroundStyle(.primary)
                .lineLimit(3)
            HStack(spacing: 10) {
                if let e = obj.eccentricity {
                    Text(String(format: "e %.2f", e))
                        .font(.firaCode(.caption2))
                        .foregroundStyle(.secondary)
                }
                if let q = obj.perihelionAU {
                    Text(String(format: "q %.2f AU", q))
                        .font(.firaCode(.caption2))
                        .foregroundStyle(.secondary)
                }
                if let i = obj.inclinationDeg {
                    Text(String(format: "i %.1f°", i))
                        .font(.firaCode(.caption2))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
