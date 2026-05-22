import SwiftUI

struct CrewedLaunchRow: View {
    let launch: CrewedLaunch

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: "person.2.crop.square.stack.fill")
                    .foregroundStyle(GalacticPalette.hotPink)
                    .neonGlow(GalacticPalette.hotPink, intensity: 4)
                Text(launch.missionName ?? launch.name)
                    .font(.firaCode(.subheadline, weight: .bold))
                    .foregroundStyle(GalacticPalette.neonCyan)
                    .lineLimit(2)
                Spacer()
                Text(launch.whenUtc, style: .relative)
                    .font(.firaCode(.caption2))
                    .foregroundStyle(GalacticPalette.peach)
            }
            HStack(spacing: 6) {
                if let rocket = launch.rocketName {
                    Text(rocket)
                        .font(.firaCode(.caption, weight: .semibold))
                        .foregroundStyle(GalacticPalette.peach)
                }
                if let provider = launch.provider {
                    Text("· \(provider)")
                        .font(.firaCode(.caption2))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
            }
            HStack(spacing: 6) {
                if let destination = launch.destination {
                    Label(destination, systemImage: "scope")
                        .font(.firaCode(.caption2))
                        .foregroundStyle(GalacticPalette.electricBlue)
                }
                if let pad = launch.pad {
                    Text("· \(pad)")
                        .font(.firaCode(.caption2))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                if let status = launch.status {
                    Text(status)
                        .font(.firaCode(.caption2, weight: .semibold))
                        .foregroundStyle(statusColor(status))
                }
            }
            if let desc = launch.missionDescription, !desc.isEmpty {
                Text(desc)
                    .font(.firaCode(.caption2))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 2)
    }

    private func statusColor(_ status: String) -> Color {
        let s = status.lowercased()
        if s.contains("go") || s.contains("success") { return GalacticPalette.mint }
        if s.contains("hold") || s.contains("tbd")   { return GalacticPalette.peach }
        if s.contains("fail") || s.contains("scrub") { return GalacticPalette.storm }
        return GalacticPalette.neonCyan
    }
}
