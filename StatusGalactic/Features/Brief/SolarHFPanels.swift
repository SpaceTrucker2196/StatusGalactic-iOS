import SwiftUI

// MARK: - Solar wind

struct SolarWindPanel: View {
    let wind: SolarWind

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Solar wind (L1)")
                .font(.firaCode(.subheadline, weight: .semibold))
                .foregroundStyle(GalacticPalette.peach)
            HStack(spacing: 10) {
                tile(
                    label: "Speed",
                    value: wind.speedKmS.map { String(format: "%.0f", $0) } ?? "—",
                    unit: "km/s",
                    accent: speedColor(wind.speedKmS)
                )
                tile(
                    label: "Density",
                    value: wind.densityP.map { String(format: "%.1f", $0) } ?? "—",
                    unit: "p/cc",
                    accent: GalacticPalette.electricBlue
                )
                tile(
                    label: "Bz",
                    value: wind.bzNT.map { String(format: "%+.1f", $0) } ?? "—",
                    unit: "nT",
                    accent: bzColor(wind.bzNT)
                )
                tile(
                    label: "Bt",
                    value: wind.btNT.map { String(format: "%.1f", $0) } ?? "—",
                    unit: "nT",
                    accent: GalacticPalette.mint
                )
            }
            Text("DSCOVR/ACE · \(wind.observedAt.formatted(.dateTime.hour().minute().timeZone()))")
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

    private func tile(label: String, value: String, unit: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.firaCode(.caption2))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.firaCode(.title3, weight: .bold))
                .foregroundStyle(accent)
                .neonGlow(accent, intensity: 5)
                .monospacedDigit()
            Text(unit)
                .font(.firaCode(.caption2))
                .foregroundStyle(GalacticPalette.peach.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func speedColor(_ v: Double?) -> Color {
        guard let v else { return GalacticPalette.peach }
        switch v {
        case ..<400:  return GalacticPalette.mint
        case ..<550:  return GalacticPalette.peach
        case ..<700:  return GalacticPalette.sunsetOrange
        case ..<900:  return GalacticPalette.hotPink
        default:      return GalacticPalette.severe
        }
    }

    private func bzColor(_ v: Double?) -> Color {
        guard let v else { return GalacticPalette.peach }
        // Aurora kicks in when Bz turns strongly negative.
        switch v {
        case ..<(-10): return GalacticPalette.severe
        case ..<(-5):  return GalacticPalette.hotPink
        case ..<0:     return GalacticPalette.sunsetOrange
        default:       return GalacticPalette.mint
        }
    }
}

// MARK: - Flare probability

struct FlareProbabilityPanel: View {
    let flare: FlareProbability

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Flare probability (24h)")
                .font(.firaCode(.subheadline, weight: .semibold))
                .foregroundStyle(GalacticPalette.peach)
            HStack(spacing: 10) {
                bar(label: "C", pct: flare.cClassPct, accent: GalacticPalette.mint)
                bar(label: "M", pct: flare.mClassPct, accent: GalacticPalette.sunsetOrange)
                bar(label: "X", pct: flare.xClassPct, accent: GalacticPalette.severe)
                bar(label: "Proton", pct: flare.protonEventPct, accent: GalacticPalette.hotPink)
            }
            if let when = flare.issuedAt {
                Text("Issued \(when.formatted(.dateTime.month(.abbreviated).day().hour().minute()))")
                    .font(.firaCode(.caption2))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(GalacticPalette.deepPurple.opacity(0.42))
        )
    }

    private func bar(label: String, pct: Int, accent: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.firaCode(.caption2))
                .foregroundStyle(.secondary)
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(accent.opacity(0.15))
                    .frame(height: 56)
                RoundedRectangle(cornerRadius: 3)
                    .fill(accent)
                    .frame(height: max(2, 56 * CGFloat(pct) / 100))
                    .neonGlow(accent, intensity: 4)
            }
            Text("\(pct)%")
                .font(.firaCode(.caption, weight: .bold))
                .foregroundStyle(accent)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Kp forecast

struct KpForecastPanel: View {
    let days: [KpForecastDay]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Geomagnetic forecast (3d)")
                .font(.firaCode(.subheadline, weight: .semibold))
                .foregroundStyle(GalacticPalette.peach)
            HStack(spacing: 8) {
                ForEach(days) { day in
                    forecastDayCard(day)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(GalacticPalette.deepPurple.opacity(0.42))
        )
    }

    private func forecastDayCard(_ day: KpForecastDay) -> some View {
        let accent = GalacticPalette.kp(day.maxKp)
        return VStack(alignment: .leading, spacing: 4) {
            Text(day.date.formatted(.dateTime.weekday(.abbreviated)))
                .font(.firaCode(.caption2))
                .foregroundStyle(.secondary)
            Text(String(format: "Kp %.1f", day.maxKp))
                .font(.firaCode(.subheadline, weight: .bold))
                .foregroundStyle(accent)
                .neonGlow(accent, intensity: 4)
                .monospacedDigit()
            Text(day.gScale)
                .font(.firaCode(.caption2, weight: .semibold))
                .foregroundStyle(day.gScale == "G0" ? GalacticPalette.mint : accent)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(accent.opacity(0.18)))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(accent.opacity(0.4), lineWidth: 0.6)
        )
    }
}

// MARK: - Active regions

struct ActiveRegionsPanel: View {
    let regions: [ActiveRegion]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Active regions")
                    .font(.firaCode(.subheadline, weight: .semibold))
                    .foregroundStyle(GalacticPalette.peach)
                Spacer()
                if let when = regions.first?.observedAt {
                    Text("SRS \(when.formatted(.dateTime.month(.abbreviated).day()))")
                        .font(.firaCode(.caption2))
                        .foregroundStyle(.secondary)
                }
            }
            ForEach(regions) { region in
                regionRow(region)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(GalacticPalette.deepPurple.opacity(0.42))
        )
    }

    private func regionRow(_ r: ActiveRegion) -> some View {
        HStack(spacing: 10) {
            Text(String(r.region))
                .font(.firaCode(.subheadline, weight: .bold))
                .foregroundStyle(GalacticPalette.neonCyan)
                .neonGlow(GalacticPalette.neonCyan, intensity: 3)
                .frame(width: 56, alignment: .leading)
            Text(r.location)
                .font(.firaCode(.caption, weight: .semibold))
                .foregroundStyle(GalacticPalette.peach)
                .frame(width: 60, alignment: .leading)
            if let mag = r.magClass {
                Text(mag)
                    .font(.firaCode(.caption))
                    .foregroundStyle(accentFor(mag))
                    .neonGlow(accentFor(mag), intensity: 3)
            }
            if let spot = r.spotClass {
                Text(spot)
                    .font(.firaCode(.caption))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let n = r.numberOfSpots {
                Text("\(n)")
                    .font(.firaCode(.caption, weight: .semibold))
                    .foregroundStyle(GalacticPalette.hotPink)
                    .monospacedDigit()
                Text("spots")
                    .font(.firaCode(.caption2))
                    .foregroundStyle(.secondary)
            }
            if let a = r.area {
                Text("\(a)")
                    .font(.firaCode(.caption2))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
    }

    /// Mt Wilson magnetic-class threat coloring. Beta-Gamma-Delta is high-risk.
    private func accentFor(_ magClass: String) -> Color {
        let upper = magClass.uppercased()
        if upper.contains("DELTA") { return GalacticPalette.severe }
        if upper.contains("GAMMA") { return GalacticPalette.hotPink }
        if upper.contains("BETA")  { return GalacticPalette.sunsetOrange }
        return GalacticPalette.mint
    }
}

// MARK: - WWV bulletin

struct WWVBulletinPanel: View {
    let bulletin: WWVBulletin

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .foregroundStyle(GalacticPalette.electricBlue)
                Text("WWV propagation")
                    .font(.firaCode(.subheadline, weight: .semibold))
                    .foregroundStyle(GalacticPalette.peach)
                Spacer()
                if let when = bulletin.issuedAt {
                    Text(when.formatted(.dateTime.month(.abbreviated).day().hour()))
                        .font(.firaCode(.caption2))
                        .foregroundStyle(.secondary)
                }
            }
            HStack(spacing: 14) {
                wwvTile("SFI", bulletin.solarFlux.map(String.init))
                wwvTile("A", bulletin.aIndex.map(String.init))
                wwvTile("K", bulletin.kIndex.map(String.init))
            }
            if let geomag = bulletin.geomagSummary {
                Text(geomag)
                    .font(.firaCode(.caption))
                    .foregroundStyle(.primary)
            }
            if let prop = bulletin.propagationSummary {
                Text(prop)
                    .font(.firaCode(.caption))
                    .foregroundStyle(GalacticPalette.hotPink)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(GalacticPalette.deepPurple.opacity(0.42))
        )
    }

    private func wwvTile(_ label: String, _ value: String?) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.firaCode(.caption2))
                .foregroundStyle(.secondary)
            Text(value ?? "—")
                .font(.firaCode(.headline, weight: .bold))
                .foregroundStyle(GalacticPalette.neonCyan)
                .monospacedDigit()
        }
    }
}
