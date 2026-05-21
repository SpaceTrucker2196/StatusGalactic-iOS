import SwiftUI

/// Nearest ionosonde stations from the KC2G digisonde aggregator. foF2 is
/// the F2-layer critical frequency (vertical incidence); MUF(3000)F2 is
/// the long-haul HF ceiling for 3000 km hops.
struct IonosondePanel: View {
    let stations: [IonosondeStation]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundStyle(GalacticPalette.electricBlue)
                Text("Ionosondes")
                    .font(.firaCode(.subheadline, weight: .semibold))
                    .foregroundStyle(GalacticPalette.peach)
                Spacer()
                Text("KC2G · foF2 / MUF(3000)F2")
                    .font(.firaCode(.caption2))
                    .foregroundStyle(.secondary)
            }
            if let near = stations.first {
                headlineRow(near)
            }
            ForEach(stations.dropFirst().prefix(4)) { station in
                stationRow(station)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(GalacticPalette.deepPurple.opacity(0.42))
        )
    }

    private func headlineRow(_ s: IonosondeStation) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(s.name)
                    .font(.firaCode(.headline, weight: .bold))
                    .foregroundStyle(GalacticPalette.neonCyan)
                if let d = s.distanceKm {
                    Text(String(format: "%.0f km", d))
                        .font(.firaCode(.caption2))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
            Spacer()
            metricColumn(label: "foF2", value: s.fof2MHz, accent: bandColor(s.fof2MHz))
            metricColumn(label: "MUF", value: s.mufMHz, accent: bandColor(s.mufMHz))
        }
    }

    private func stationRow(_ s: IonosondeStation) -> some View {
        HStack(spacing: 12) {
            Text(s.name)
                .font(.firaCode(.caption, weight: .semibold))
                .foregroundStyle(GalacticPalette.peach)
                .frame(width: 60, alignment: .leading)
            if let d = s.distanceKm {
                Text(String(format: "%.0f km", d))
                    .font(.firaCode(.caption2))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .frame(width: 64, alignment: .leading)
            }
            Spacer()
            if let f = s.fof2MHz {
                Text(String(format: "foF2 %.1f", f))
                    .font(.firaCode(.caption2, weight: .semibold))
                    .foregroundStyle(bandColor(f))
                    .monospacedDigit()
            }
            if let m = s.mufMHz {
                Text(String(format: "MUF %.1f", m))
                    .font(.firaCode(.caption2, weight: .semibold))
                    .foregroundStyle(bandColor(m))
                    .monospacedDigit()
            }
        }
    }

    private func metricColumn(label: String, value: Double?, accent: Color) -> some View {
        VStack(alignment: .trailing, spacing: 1) {
            Text(label)
                .font(.firaCode(.caption2))
                .foregroundStyle(.secondary)
            Text(value.map { String(format: "%.1f", $0) } ?? "—")
                .font(.firaCode(.title3, weight: .bold))
                .foregroundStyle(accent)
                .neonGlow(accent, intensity: 4)
                .monospacedDigit()
            Text("MHz")
                .font(.firaCode(.caption2))
                .foregroundStyle(GalacticPalette.peach.opacity(0.8))
        }
    }

    /// Color the MHz value by which ham band it unlocks. Higher foF2 means
    /// the higher HF bands stay open.
    private func bandColor(_ mhz: Double?) -> Color {
        guard let mhz else { return GalacticPalette.peach }
        switch mhz {
        case 14...:  return GalacticPalette.mint        // 20m, 17m, 15m, 12m, 10m
        case 7..<14: return GalacticPalette.peach       // 40m, 30m, 20m
        case 3..<7:  return GalacticPalette.sunsetOrange// 80m, 60m, 40m
        default:     return GalacticPalette.storm
        }
    }
}
