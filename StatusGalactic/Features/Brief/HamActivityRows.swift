import SwiftUI

struct SOTASpotRow: View {
    let spot: SOTASpot

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: "mountain.2.fill")
                    .foregroundStyle(GalacticPalette.peach)
                    .neonGlow(GalacticPalette.peach, intensity: 3)
                Text(spot.activator)
                    .font(.firaCode(.subheadline, weight: .bold))
                    .foregroundStyle(GalacticPalette.neonCyan)
                Text(spot.summitCode)
                    .font(.firaCode(.caption2, weight: .semibold))
                    .foregroundStyle(GalacticPalette.peach)
                Spacer()
                Text(spot.spotTime, style: .relative)
                    .font(.firaCode(.caption2))
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                Text(String(format: "%.4f MHz", spot.frequencyKHz / 1000))
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
            }
            Text(spot.summitDetails)
                .font(.firaCode(.caption2))
                .foregroundStyle(.primary)
                .lineLimit(1)
            if let comments = spot.comments, !comments.isEmpty {
                Text(comments)
                    .font(.firaCode(.caption2))
                    .foregroundStyle(GalacticPalette.peach.opacity(0.8))
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }

    private var bandColor: Color {
        let mhz = spot.frequencyKHz / 1000
        switch mhz {
        case 14...:   return GalacticPalette.mint
        case 7..<14:  return GalacticPalette.peach
        case 3..<7:   return GalacticPalette.sunsetOrange
        default:      return GalacticPalette.storm
        }
    }
}

struct DXSpotRow: View {
    let spot: DXSpot

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 8) {
                Image(systemName: "globe.americas.fill")
                    .foregroundStyle(GalacticPalette.hotPink)
                    .neonGlow(GalacticPalette.hotPink, intensity: 3)
                Text(spot.dxCallsign)
                    .font(.firaCode(.subheadline, weight: .bold))
                    .foregroundStyle(GalacticPalette.neonCyan)
                Spacer()
                Text(spot.spotTime, style: .relative)
                    .font(.firaCode(.caption2))
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                Text(String(format: "%.3f kHz", spot.frequencyKHz))
                    .font(.firaCode(.caption, weight: .semibold))
                    .foregroundStyle(bandColor)
                    .monospacedDigit()
                Text("by \(spot.spotter)")
                    .font(.firaCode(.caption2))
                    .foregroundStyle(GalacticPalette.peach)
                Spacer()
            }
            if let info = spot.info, !info.isEmpty {
                Text(info)
                    .font(.firaCode(.caption2))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }

    private var bandColor: Color {
        let mhz = spot.frequencyKHz / 1000
        switch mhz {
        case 14...:   return GalacticPalette.mint
        case 7..<14:  return GalacticPalette.peach
        case 3..<7:   return GalacticPalette.sunsetOrange
        default:      return GalacticPalette.storm
        }
    }
}
