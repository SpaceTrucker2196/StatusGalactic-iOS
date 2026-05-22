import SwiftUI

/// Tap-detail for the River Stage card. Shows the existing card up top
/// plus a "what to watch for" explainer that turns the flood-risk score
/// into ham-radio / boater-friendly guidance. Future passes can plug a
/// hydrograph here once NWPS history is wired in.
struct RiverStageAlmanacView: View {
    let gauge: RiverGauge
    let viewerLat: Double?
    let viewerLng: Double?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                RiverGaugeCard(gauge: gauge)
                interpretationPanel
                actionGuidance
                methodologyNote
            }
            .padding(16)
        }
        .background(GalacticPalette.cosmicSky.ignoresSafeArea())
        .navigationTitle("River Stage")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var statusColor: Color {
        switch gauge.floodStatus {
        case .noData, .belowAction: return GalacticPalette.mint
        case .action:               return GalacticPalette.active
        case .minor:                return GalacticPalette.storm
        case .moderate:             return GalacticPalette.neonMagenta
        case .major:                return GalacticPalette.severe
        }
    }

    private var interpretationPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Where you are on the scale")
                .font(.firaCode(.subheadline, weight: .semibold))
                .foregroundStyle(GalacticPalette.peach)
            HStack(spacing: 10) {
                bigTile(
                    label: "Risk",
                    value: "\(gauge.floodRiskScore)%",
                    accent: statusColor
                )
                bigTile(
                    label: "Status",
                    value: statusLabel,
                    accent: statusColor
                )
                if let delta = gauge.feetToNextThreshold {
                    bigTile(
                        label: delta >= 0 ? "Headroom" : "Over by",
                        value: String(format: "%.1f ft", abs(delta)),
                        accent: delta >= 0 ? GalacticPalette.mint : GalacticPalette.severe
                    )
                }
            }
            Text(gauge.riskNarrative)
                .font(.firaCode(.caption))
                .foregroundStyle(.primary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(GalacticPalette.deepPurple.opacity(0.42))
        )
    }

    private var statusLabel: String {
        switch gauge.floodStatus {
        case .noData:      return "No data"
        case .belowAction: return "Normal"
        case .action:      return "Action"
        case .minor:       return "Minor"
        case .moderate:    return "Moderate"
        case .major:       return "Major"
        }
    }

    private var actionGuidance: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("What to do now")
                .font(.firaCode(.subheadline, weight: .semibold))
                .foregroundStyle(GalacticPalette.peach)
            ForEach(guidanceLines, id: \.self) { line in
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundStyle(statusColor)
                    Text(line)
                        .font(.firaCode(.caption))
                        .foregroundStyle(.primary)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(GalacticPalette.deepPurple.opacity(0.35))
        )
    }

    /// Status-specific guidance, mirrors NWS-style language but condensed.
    private var guidanceLines: [String] {
        switch gauge.floodStatus {
        case .noData:
            return ["No current observation reported for this gauge — try refresh."]
        case .belowAction:
            if let peak = gauge.forecastPeakFt,
               let action = gauge.actionStageFt,
               peak >= action {
                return [
                    "Forecast peak crosses action stage — start watching.",
                    "Secure floating gear near the bank if you keep equipment riverside.",
                ]
            }
            return [
                "Normal flow — no action needed.",
                "Pull-to-refresh updates from NOAA NWPS roughly every 15 minutes.",
            ]
        case .action:
            return [
                "Action stage — water nearing low-lying spots.",
                "Move gear off floodplains; verify boats are tied with slack.",
                "Local emergency mgmt may pre-position equipment.",
            ]
        case .minor:
            return [
                "Minor flooding underway. Some roads and low fields will be inundated.",
                "Avoid driving across moving water. Update local nets if you're on-air.",
            ]
        case .moderate:
            return [
                "Moderate flooding — structures near the river are at risk.",
                "Evacuate floodplain residences. Watch for swift-water rescue traffic.",
                "Net traffic typically shifts to ARES / RACES on this stage.",
            ]
        case .major:
            return [
                "Major flooding. Widespread evacuations and bridge closures expected.",
                "Stay off the water. Listen for NWS Flash Flood Warnings.",
            ]
        }
    }

    private var methodologyNote: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("How the score works")
                .font(.firaCode(.subheadline, weight: .semibold))
                .foregroundStyle(GalacticPalette.peach)
            Text("Risk % is the position of the higher of current stage or forecast peak " +
                 "between Action (0%) and Major flood (100%) stages set by the local NWS office. " +
                 "Gauge data and thresholds come from NOAA NWPS; risk derivation is on-device.")
                .font(.firaCode(.caption2))
                .foregroundStyle(.secondary)
            if let lat = viewerLat, let lng = viewerLng {
                Text(String(format: "Viewer location: %.3f, %.3f · gauge %.1f km away",
                            lat, lng, gauge.distanceKm))
                    .font(.firaCode(.caption2))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func bigTile(label: String, value: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.firaCode(.caption2))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.firaCode(.title3, weight: .bold))
                .foregroundStyle(accent)
                .neonGlow(accent, intensity: 4)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(accent.opacity(0.4), lineWidth: 0.6)
        )
    }
}
