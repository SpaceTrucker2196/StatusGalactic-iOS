import SwiftUI

/// Per-band day/night status table — ham operator's at-a-glance "should I
/// even fire up the radio" view. Synthesized from existing SFI / Kp /
/// R-scale / MUF values; no extra fetch.
struct BandConditionsPanel: View {
    let bands: [BandCondition]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("HF Band Conditions")
                    .font(.firaCode(.subheadline, weight: .semibold))
                    .foregroundStyle(GalacticPalette.peach)
                Spacer()
                Text("Day / Night")
                    .font(.firaCode(.caption2))
                    .foregroundStyle(.secondary)
            }
            ForEach(bands) { band in
                row(band)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(GalacticPalette.deepPurple.opacity(0.42))
        )
    }

    private func row(_ b: BandCondition) -> some View {
        HStack(spacing: 10) {
            Text(b.band)
                .font(.firaCode(.subheadline, weight: .bold))
                .foregroundStyle(GalacticPalette.neonCyan)
                .frame(width: 42, alignment: .leading)
            Text(String(format: "%.1f MHz", b.centerMHz))
                .font(.firaCode(.caption2))
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .frame(width: 80, alignment: .leading)
            statusPill(b.dayStatus)
            statusPill(b.nightStatus)
            Spacer()
            if let reason = b.reason {
                Text(reason)
                    .font(.firaCode(.caption2))
                    .foregroundStyle(GalacticPalette.peach.opacity(0.85))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
    }

    private func statusPill(_ status: String) -> some View {
        let accent = Self.color(for: status)
        return Text(status)
            .font(.firaCode(.caption2, weight: .bold))
            .foregroundStyle(accent)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(accent.opacity(0.18)))
            .overlay(Capsule().stroke(accent, lineWidth: 0.5))
            .frame(width: 58)
    }

    static func color(for status: String) -> Color {
        switch status {
        case "Good", "Open": return GalacticPalette.mint
        case "Fair":         return GalacticPalette.peach
        case "Poor":         return GalacticPalette.sunsetOrange
        case "Closed":       return GalacticPalette.storm
        default:             return GalacticPalette.peach
        }
    }
}
