import SwiftUI

struct POTASpotRow: View {
    let spot: POTASpot

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: "tree.fill")
                    .foregroundStyle(GalacticPalette.mint)
                    .neonGlow(GalacticPalette.mint, intensity: 3)
                Text(spot.activator)
                    .font(.firaCode(.subheadline, weight: .bold))
                    .foregroundStyle(GalacticPalette.neonCyan)
                Text(spot.parkRef)
                    .font(.firaCode(.caption2, weight: .semibold))
                    .foregroundStyle(GalacticPalette.peach)
                Spacer()
                if let d = spot.distanceKm {
                    HStack(spacing: 4) {
                        Text(String(format: "%.0f km", d))
                            .foregroundStyle(GalacticPalette.hotPink)
                        if let az = spot.azimuthDeg {
                            Text("·")
                                .foregroundStyle(.secondary)
                            Text("\(compassPoint(forBearing: az)) \(Int(az.rounded()))°")
                                .foregroundStyle(GalacticPalette.mint)
                        }
                    }
                    .font(.firaCode(.caption2))
                    .monospacedDigit()
                }
            }
            HStack(spacing: 8) {
                Text(frequencyLabel)
                    .font(.firaCode(.caption, weight: .semibold))
                    .foregroundStyle(bandColor)
                    .monospacedDigit()
                Text(spot.mode)
                    .font(.firaCode(.caption2, weight: .bold))
                    .foregroundStyle(GalacticPalette.neonCyan)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(GalacticPalette.neonCyan.opacity(0.18)))
                Spacer()
                Text(spot.spotTime, style: .relative)
                    .font(.firaCode(.caption2))
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 6) {
                Text(spot.parkName)
                    .font(.firaCode(.caption2))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                if let loc = spot.locationDesc {
                    Text("· \(loc)")
                        .font(.firaCode(.caption2))
                        .foregroundStyle(.secondary)
                }
            }
            if let comments = spot.comments, !comments.isEmpty {
                Text(comments)
                    .font(.firaCode(.caption2))
                    .foregroundStyle(GalacticPalette.peach.opacity(0.8))
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }

    private var frequencyLabel: String {
        let mhz = spot.frequencyKHz / 1000
        return String(format: "%.4f MHz", mhz)
    }

    private var bandColor: Color {
        // Convert kHz → MHz then map to the same band palette the
        // Ionosonde panel uses.
        let mhz = spot.frequencyKHz / 1000
        switch mhz {
        case 14...:   return GalacticPalette.mint
        case 7..<14:  return GalacticPalette.peach
        case 3..<7:   return GalacticPalette.sunsetOrange
        default:      return GalacticPalette.storm
        }
    }
}
