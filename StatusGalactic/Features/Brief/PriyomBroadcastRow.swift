import SwiftUI

/// Compact row for one upcoming Priyom shortwave broadcast — station
/// designator, frequency (color-coded by HF band), mode, target region,
/// and start time. Used in the RF tab's Upcoming Shortwave section.
struct PriyomBroadcastRow: View {
    let broadcast: PriyomBroadcast

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 8) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .foregroundStyle(GalacticPalette.electricBlue)
                    .neonGlow(GalacticPalette.electricBlue, intensity: 3)
                Text(broadcast.station)
                    .font(.firaCode(.subheadline, weight: .bold))
                    .foregroundStyle(GalacticPalette.neonCyan)
                Spacer()
                Text(broadcast.startTime, style: .relative)
                    .font(.firaCode(.caption2, weight: .semibold))
                    .foregroundStyle(GalacticPalette.hotPink)
                    .monospacedDigit()
            }
            HStack(spacing: 8) {
                Text(String(format: "%d kHz", broadcast.frequencyKHz))
                    .font(.firaCode(.caption, weight: .semibold))
                    .foregroundStyle(bandColor)
                    .monospacedDigit()
                Text(broadcast.mode)
                    .font(.firaCode(.caption2, weight: .semibold))
                    .foregroundStyle(GalacticPalette.mint)
                Spacer()
                Text(broadcast.startTime, format: .dateTime
                    .hour(.twoDigits(amPM: .omitted))
                    .minute(.twoDigits))
                    .font(.firaCode(.caption2))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                Text("UTC")
                    .font(.firaCode(.caption2))
                    .foregroundStyle(.secondary)
            }
            if let target = broadcast.target, !target.isEmpty {
                Text("→ \(target)")
                    .font(.firaCode(.caption2))
                    .foregroundStyle(GalacticPalette.peach)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
        .environment(\.timeZone, .gmt)
    }

    private var bandColor: Color {
        let mhz = Double(broadcast.frequencyKHz) / 1000
        switch mhz {
        case 14...:   return GalacticPalette.mint
        case 7..<14:  return GalacticPalette.peach
        case 3..<7:   return GalacticPalette.sunsetOrange
        default:      return GalacticPalette.storm
        }
    }
}
