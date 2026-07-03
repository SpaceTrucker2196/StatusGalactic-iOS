import SwiftUI

/// Shared solar-terrestrial panel — used both by the WidgetKit
/// `SolarTerrestrialWidget` and by the iPad `PanelGrid`. Factored out
/// of `StatusGalacticWidget/SolarTerrestrialWidget.swift` so the two
/// hosts render the exact same pixels.
///
/// The renderer accepts the two things every host has independently: a
/// (possibly-nil) `Brief` and a reference date for the header timestamp.
/// It never touches App-Group defaults or WidgetKit types.
///
/// Initial slice: `.tall` and `.large` reuse the `.small` / `.wide`
/// layouts respectively. Bespoke layouts for the new sizes land per-panel
/// as visual design iterates.
struct SolarPanel: View {
    let size: PanelSize
    let brief: Brief?
    let referenceDate: Date

    init(size: PanelSize, brief: Brief?, referenceDate: Date = Date()) {
        self.size = size
        self.brief = brief
        self.referenceDate = referenceDate
    }

    var body: some View {
        switch size {
        case .small: SolarSmallView(brief: brief, referenceDate: referenceDate)
        case .wide:  SolarMediumView(brief: brief, referenceDate: referenceDate)
        case .tall:  SolarTallView(brief: brief, referenceDate: referenceDate)
        case .large: SolarLargeView(brief: brief, referenceDate: referenceDate)
        }
    }
}

// MARK: - Local color helpers

enum SolarTokens {
    static let mutedText = Color(red: 0.78, green: 0.82, blue: 0.96)

    static func sfiColor(_ sfi: Double) -> Color {
        switch sfi {
        case 150...:    return GalacticPalette.mint
        case 100..<150: return GalacticPalette.peach
        case 80..<100:  return GalacticPalette.hotPink
        default:        return GalacticPalette.neonMagenta
        }
    }

    static func xRayColor(_ klass: String) -> Color {
        guard let first = klass.first else { return mutedText }
        switch first {
        case "A", "B": return GalacticPalette.neonCyan
        case "C":      return GalacticPalette.mint
        case "M":      return GalacticPalette.peach
        case "X":      return GalacticPalette.neonMagenta
        default:       return mutedText
        }
    }
}

// MARK: - Small

struct SolarSmallView: View {
    let brief: Brief?
    let referenceDate: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            headerBar
            Divider().background(GalacticPalette.phosphorGreen.opacity(0.4))

            let m = SolarMetrics(brief: brief)
            VStack(alignment: .leading, spacing: 2) {
                bigReadout("SFI", value: m.sfiText, color: m.sfiColor)
                miniRow("Kp",    m.kpText,    color: m.kpColor)
                miniRow("X-RAY", m.xRayClass, color: m.xRayColor)
                miniRow("AUR",   m.auroraText, color: GalacticPalette.hotPink)
            }
            Spacer(minLength: 0)
            geomagPill(m.geomag)
        }
        .padding(2)
        .foregroundStyle(SolarTokens.mutedText)
    }

    private var headerBar: some View {
        HStack {
            Text("SOLAR")
                .font(.firaCodeFixed(size: 11, weight: .bold))
                .tracking(2)
                .foregroundStyle(GalacticPalette.phosphorGreen)
                .neonGlow(GalacticPalette.phosphorGreen, intensity: 3)
            Spacer()
            Text(solarZuluTime(brief?.space?.observedAt ?? referenceDate))
                .font(.firaCodeFixed(size: 9))
                .foregroundStyle(GalacticPalette.phosphorGreen.opacity(0.75))
        }
    }

    private func bigReadout(_ label: String, value: String, color: Color) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(label)
                .font(.firaCodeFixed(size: 10, weight: .semibold))
                .foregroundStyle(SolarTokens.mutedText.opacity(0.7))
            Text(value)
                .font(.firaCodeFixed(size: 26, weight: .bold))
                .foregroundStyle(color)
                .neonGlow(color, intensity: 4)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
    }

    private func miniRow(_ label: String, _ value: String, color: Color) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .font(.firaCodeFixed(size: 9, weight: .semibold))
                .foregroundStyle(SolarTokens.mutedText.opacity(0.7))
                .frame(width: 38, alignment: .leading)
            Text(value)
                .font(.firaCodeFixed(size: 11, weight: .bold))
                .foregroundStyle(color)
                .lineLimit(1)
        }
    }

    private func geomagPill(_ label: String) -> some View {
        let color = solarGeomagColor(label)
        return HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6).neonGlow(color, intensity: 3)
            Text(label.uppercased())
                .font(.firaCodeFixed(size: 9, weight: .bold))
                .tracking(1)
                .foregroundStyle(color)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule().stroke(color.opacity(0.6), lineWidth: 0.6)
        )
    }
}

// MARK: - Medium

struct SolarMediumView: View {
    let brief: Brief?
    let referenceDate: Date

    var body: some View {
        let m = SolarMetrics(brief: brief)
        VStack(spacing: 4) {
            headerBar
            Divider().background(GalacticPalette.phosphorGreen.opacity(0.4))

            HStack(alignment: .top, spacing: 10) {
                bigColumn(m)
                Divider().background(GalacticPalette.neonCyan.opacity(0.25))
                tableColumn(m)
                Divider().background(GalacticPalette.neonCyan.opacity(0.25))
                sunColumn(m)
            }

            Divider().background(GalacticPalette.phosphorGreen.opacity(0.4))
            statusFooter(m)
        }
        .padding(2)
        .foregroundStyle(SolarTokens.mutedText)
    }

    private var headerBar: some View {
        HStack {
            Text("SOLAR-TERRESTRIAL")
                .font(.firaCodeFixed(size: 11, weight: .bold))
                .tracking(2.5)
                .foregroundStyle(GalacticPalette.phosphorGreen)
                .neonGlow(GalacticPalette.phosphorGreen, intensity: 4)
            Spacer()
            Text(solarUTCStamp(brief?.space?.observedAt ?? referenceDate))
                .font(.firaCodeFixed(size: 10))
                .foregroundStyle(GalacticPalette.phosphorGreen.opacity(0.75))
        }
    }

    private func bigColumn(_ m: SolarMetrics) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            readout("SFI", value: m.sfiText, color: m.sfiColor, size: 22)
            readout("Kp",  value: m.kpText,  color: m.kpColor,  size: 22)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func tableColumn(_ m: SolarMetrics) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            tableRow("A-IDX",  m.aIdxText,    color: GalacticPalette.peach)
            tableRow("X-RAY",  m.xRayClass,   color: m.xRayColor)
            tableRow("24H PK", m.xRayPeak,    color: m.xRayPeakColor)
            tableRow("PROTON", m.protonText,  color: m.protonColor)
            tableRow("AURORA", m.auroraText,  color: GalacticPalette.hotPink)
            tableRow("M-FLR",  m.mFlareText,  color: GalacticPalette.neonMagenta)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sunColumn(_ m: SolarMetrics) -> some View {
        VStack(spacing: 4) {
            Image(systemName: "sun.max.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 36, height: 36)
                .foregroundStyle(GalacticPalette.sunsetOrange)
                .neonGlow(GalacticPalette.sunsetOrange, intensity: 6)
            HStack(spacing: 3) {
                scaleChip(m.rScale)
                scaleChip(m.sScale)
                scaleChip(m.gScale)
            }
            if let sn = m.sunspotNumber {
                Text("SN \(sn)")
                    .font(.firaCodeFixed(size: 9, weight: .bold))
                    .foregroundStyle(GalacticPalette.mint)
            }
            Spacer(minLength: 0)
        }
        .frame(width: 70)
    }

    private func statusFooter(_ m: SolarMetrics) -> some View {
        HStack(spacing: 8) {
            statusPill(label: "GEOMAG", value: m.geomag, color: solarGeomagColor(m.geomag))
            statusPill(label: "HF DAY", value: m.hfDay, color: solarHFColor(m.hfDay))
            statusPill(label: "HF NIGHT", value: m.hfNight, color: solarHFColor(m.hfNight))
            Spacer(minLength: 0)
        }
    }

    private func readout(_ label: String, value: String, color: Color, size: CGFloat) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(label)
                .font(.firaCodeFixed(size: 10, weight: .semibold))
                .foregroundStyle(SolarTokens.mutedText.opacity(0.7))
                .frame(width: 28, alignment: .leading)
            Text(value)
                .font(.firaCodeFixed(size: size, weight: .bold))
                .foregroundStyle(color)
                .neonGlow(color, intensity: 4)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
    }

    private func tableRow(_ label: String, _ value: String, color: Color) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .font(.firaCodeFixed(size: 9, weight: .semibold))
                .foregroundStyle(SolarTokens.mutedText.opacity(0.65))
                .frame(width: 48, alignment: .leading)
            Text(value)
                .font(.firaCodeFixed(size: 11, weight: .bold))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private func scaleChip(_ level: String) -> some View {
        let digit = level.last.flatMap { Int(String($0)) } ?? 0
        let color: Color = {
            switch digit {
            case 0:  return GalacticPalette.neonCyan
            case 1:  return GalacticPalette.mint
            case 2:  return GalacticPalette.peach
            case 3:  return GalacticPalette.hotPink
            default: return GalacticPalette.neonMagenta
            }
        }()
        return Text(level)
            .font(.firaCodeFixed(size: 9, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(
                Capsule().stroke(color.opacity(0.7), lineWidth: 0.6)
            )
    }

    private func statusPill(label: String, value: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Text(label)
                .font(.firaCodeFixed(size: 8, weight: .semibold))
                .foregroundStyle(SolarTokens.mutedText.opacity(0.6))
            Text(value.uppercased())
                .font(.firaCodeFixed(size: 9, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(color)
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(
            Capsule().stroke(color.opacity(0.55), lineWidth: 0.5)
        )
    }
}

// MARK: - Tall (1×2)

/// Portrait Solar readout: SFI + Kp headline stacked, then the full
/// 6-row data table, then a stacked sun icon + R/S/G chips + geomag
/// pill at the bottom.
struct SolarTallView: View {
    let brief: Brief?
    let referenceDate: Date

    var body: some View {
        let m = SolarMetrics(brief: brief)
        VStack(alignment: .leading, spacing: 6) {
            headerBar
            Divider().background(GalacticPalette.phosphorGreen.opacity(0.4))

            readout("SFI", value: m.sfiText, color: m.sfiColor, size: 26)
            readout("Kp",  value: m.kpText,  color: m.kpColor,  size: 26)

            Divider().background(GalacticPalette.neonCyan.opacity(0.25))

            VStack(alignment: .leading, spacing: 3) {
                tableRow("A-IDX",  m.aIdxText,   color: GalacticPalette.peach)
                tableRow("X-RAY",  m.xRayClass,  color: m.xRayColor)
                tableRow("24H PK", m.xRayPeak,   color: m.xRayPeakColor)
                tableRow("PROTON", m.protonText, color: m.protonColor)
                tableRow("AURORA", m.auroraText, color: GalacticPalette.hotPink)
                tableRow("M-FLR",  m.mFlareText, color: GalacticPalette.neonMagenta)
            }

            Spacer(minLength: 0)

            HStack(spacing: 6) {
                Image(systemName: "sun.max.fill")
                    .resizable().aspectRatio(contentMode: .fit)
                    .frame(width: 28, height: 28)
                    .foregroundStyle(GalacticPalette.sunsetOrange)
                    .neonGlow(GalacticPalette.sunsetOrange, intensity: 5)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 3) {
                        scaleChip(m.rScale)
                        scaleChip(m.sScale)
                        scaleChip(m.gScale)
                    }
                    if let sn = m.sunspotNumber {
                        Text("SN \(sn)")
                            .font(.firaCodeFixed(size: 9, weight: .bold))
                            .foregroundStyle(GalacticPalette.mint)
                    }
                }
                Spacer(minLength: 0)
                geomagPill(m.geomag)
            }
        }
        .padding(2)
        .foregroundStyle(SolarTokens.mutedText)
    }

    private var headerBar: some View {
        HStack {
            Text("SOLAR")
                .font(.firaCodeFixed(size: 11, weight: .bold))
                .tracking(2)
                .foregroundStyle(GalacticPalette.phosphorGreen)
                .neonGlow(GalacticPalette.phosphorGreen, intensity: 3)
            Spacer()
            Text(solarZuluTime(brief?.space?.observedAt ?? referenceDate))
                .font(.firaCodeFixed(size: 9))
                .foregroundStyle(GalacticPalette.phosphorGreen.opacity(0.75))
        }
    }

    private func readout(_ label: String, value: String, color: Color, size: CGFloat) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(label)
                .font(.firaCodeFixed(size: 10, weight: .semibold))
                .foregroundStyle(SolarTokens.mutedText.opacity(0.7))
                .frame(width: 28, alignment: .leading)
            Text(value)
                .font(.firaCodeFixed(size: size, weight: .bold))
                .foregroundStyle(color)
                .neonGlow(color, intensity: 4)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
    }

    private func tableRow(_ label: String, _ value: String, color: Color) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .font(.firaCodeFixed(size: 9, weight: .semibold))
                .foregroundStyle(SolarTokens.mutedText.opacity(0.65))
                .frame(width: 52, alignment: .leading)
            Text(value)
                .font(.firaCodeFixed(size: 11, weight: .bold))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private func scaleChip(_ level: String) -> some View {
        let digit = level.last.flatMap { Int(String($0)) } ?? 0
        let color: Color = {
            switch digit {
            case 0:  return GalacticPalette.neonCyan
            case 1:  return GalacticPalette.mint
            case 2:  return GalacticPalette.peach
            case 3:  return GalacticPalette.hotPink
            default: return GalacticPalette.neonMagenta
            }
        }()
        return Text(level)
            .font(.firaCodeFixed(size: 9, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(Capsule().stroke(color.opacity(0.7), lineWidth: 0.6))
    }

    private func geomagPill(_ label: String) -> some View {
        let color = solarGeomagColor(label)
        return HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6).neonGlow(color, intensity: 3)
            Text(label.uppercased())
                .font(.firaCodeFixed(size: 9, weight: .bold))
                .tracking(1)
                .foregroundStyle(color)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Capsule().stroke(color.opacity(0.6), lineWidth: 0.6))
    }
}

// MARK: - Large (2×2)

/// Full 2×2 Solar dashboard: medium content up top (big readouts, data
/// table, sun column), plus an HF band-conditions table and a 3-day Kp
/// outlook strip in the lower half.
struct SolarLargeView: View {
    let brief: Brief?
    let referenceDate: Date

    var body: some View {
        let m = SolarMetrics(brief: brief)
        VStack(spacing: 6) {
            headerBar
            Divider().background(GalacticPalette.phosphorGreen.opacity(0.4))

            // Top row — everything the medium widget shows.
            HStack(alignment: .top, spacing: 12) {
                bigColumn(m)
                Divider().background(GalacticPalette.neonCyan.opacity(0.25))
                tableColumn(m)
                Divider().background(GalacticPalette.neonCyan.opacity(0.25))
                sunColumn(m)
            }

            Divider().background(GalacticPalette.phosphorGreen.opacity(0.4))

            // Bottom half — HF band table + 3-day Kp outlook. Only
            // shown when the underlying data is present so the layout
            // doesn't leave a big blank slab.
            HStack(alignment: .top, spacing: 12) {
                bandTable
                Divider().background(GalacticPalette.neonCyan.opacity(0.25))
                kpOutlook
            }

            Divider().background(GalacticPalette.phosphorGreen.opacity(0.4))
            statusFooter(m)
        }
        .padding(4)
        .foregroundStyle(SolarTokens.mutedText)
    }

    private var headerBar: some View {
        HStack {
            Text("SOLAR-TERRESTRIAL")
                .font(.firaCodeFixed(size: 12, weight: .bold))
                .tracking(2.5)
                .foregroundStyle(GalacticPalette.phosphorGreen)
                .neonGlow(GalacticPalette.phosphorGreen, intensity: 4)
            Spacer()
            Text(solarUTCStamp(brief?.space?.observedAt ?? referenceDate))
                .font(.firaCodeFixed(size: 10))
                .foregroundStyle(GalacticPalette.phosphorGreen.opacity(0.75))
        }
    }

    private func bigColumn(_ m: SolarMetrics) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            largeReadout("SFI", value: m.sfiText, color: m.sfiColor, size: 30)
            largeReadout("Kp",  value: m.kpText,  color: m.kpColor,  size: 30)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func tableColumn(_ m: SolarMetrics) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            tableRow("A-IDX",  m.aIdxText,    color: GalacticPalette.peach)
            tableRow("X-RAY",  m.xRayClass,   color: m.xRayColor)
            tableRow("24H PK", m.xRayPeak,    color: m.xRayPeakColor)
            tableRow("PROTON", m.protonText,  color: m.protonColor)
            tableRow("AURORA", m.auroraText,  color: GalacticPalette.hotPink)
            tableRow("M-FLR",  m.mFlareText,  color: GalacticPalette.neonMagenta)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sunColumn(_ m: SolarMetrics) -> some View {
        VStack(spacing: 5) {
            Image(systemName: "sun.max.fill")
                .resizable().aspectRatio(contentMode: .fit)
                .frame(width: 50, height: 50)
                .foregroundStyle(GalacticPalette.sunsetOrange)
                .neonGlow(GalacticPalette.sunsetOrange, intensity: 7)
            HStack(spacing: 4) {
                scaleChip(m.rScale)
                scaleChip(m.sScale)
                scaleChip(m.gScale)
            }
            if let sn = m.sunspotNumber {
                Text("SN \(sn)")
                    .font(.firaCodeFixed(size: 10, weight: .bold))
                    .foregroundStyle(GalacticPalette.mint)
            }
            Spacer(minLength: 0)
        }
        .frame(width: 84)
    }

    @ViewBuilder
    private var bandTable: some View {
        let bands = brief?.bandConditions ?? []
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 0) {
                Text("HF BAND")
                    .frame(width: 52, alignment: .leading)
                Text("DAY")
                    .frame(width: 56, alignment: .leading)
                Text("NIGHT")
                    .frame(width: 56, alignment: .leading)
            }
            .font(.firaCodeFixed(size: 9, weight: .semibold))
            .foregroundStyle(SolarTokens.mutedText.opacity(0.6))

            if bands.isEmpty {
                Text("HF band data unavailable")
                    .font(.firaCodeFixed(size: 10))
                    .foregroundStyle(SolarTokens.mutedText.opacity(0.55))
            } else {
                ForEach(bands.prefix(6)) { band in
                    HStack(spacing: 0) {
                        Text(band.band)
                            .font(.firaCodeFixed(size: 11, weight: .bold))
                            .foregroundStyle(GalacticPalette.neonCyan)
                            .frame(width: 52, alignment: .leading)
                        Text(band.dayStatus.uppercased())
                            .font(.firaCodeFixed(size: 10, weight: .bold))
                            .foregroundStyle(solarHFColor(band.dayStatus))
                            .frame(width: 56, alignment: .leading)
                        Text(band.nightStatus.uppercased())
                            .font(.firaCodeFixed(size: 10, weight: .bold))
                            .foregroundStyle(solarHFColor(band.nightStatus))
                            .frame(width: 56, alignment: .leading)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var kpOutlook: some View {
        let days = brief?.kpForecast.prefix(3) ?? []
        VStack(alignment: .leading, spacing: 3) {
            Text("KP 3-DAY OUTLOOK")
                .font(.firaCodeFixed(size: 9, weight: .semibold))
                .foregroundStyle(SolarTokens.mutedText.opacity(0.6))
            if days.isEmpty {
                Text("Forecast unavailable")
                    .font(.firaCodeFixed(size: 10))
                    .foregroundStyle(SolarTokens.mutedText.opacity(0.55))
            } else {
                ForEach(Array(days)) { day in
                    HStack(spacing: 6) {
                        Text(solarShortDate(day.date))
                            .font(.firaCodeFixed(size: 10, weight: .semibold))
                            .foregroundStyle(SolarTokens.mutedText.opacity(0.75))
                            .frame(width: 48, alignment: .leading)
                        Text(String(format: "Kp %.1f", day.maxKp))
                            .font(.firaCodeFixed(size: 11, weight: .bold))
                            .foregroundStyle(GalacticPalette.kp(day.maxKp))
                        Spacer(minLength: 0)
                        Text(day.gScale)
                            .font(.firaCodeFixed(size: 10, weight: .bold))
                            .foregroundStyle(SolarTokens.mutedText.opacity(0.9))
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func statusFooter(_ m: SolarMetrics) -> some View {
        HStack(spacing: 8) {
            statusPill(label: "GEOMAG",   value: m.geomag,  color: solarGeomagColor(m.geomag))
            statusPill(label: "HF DAY",   value: m.hfDay,   color: solarHFColor(m.hfDay))
            statusPill(label: "HF NIGHT", value: m.hfNight, color: solarHFColor(m.hfNight))
            Spacer(minLength: 0)
        }
    }

    // MARK: - Row helpers (duplicated w/ SolarMediumView so each layout
    // can size type independently; the sizes in .large are a hair
    // bigger so the extra area is used.)

    private func largeReadout(_ label: String, value: String, color: Color, size: CGFloat) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label)
                .font(.firaCodeFixed(size: 11, weight: .semibold))
                .foregroundStyle(SolarTokens.mutedText.opacity(0.7))
                .frame(width: 32, alignment: .leading)
            Text(value)
                .font(.firaCodeFixed(size: size, weight: .bold))
                .foregroundStyle(color)
                .neonGlow(color, intensity: 5)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
    }

    private func tableRow(_ label: String, _ value: String, color: Color) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .font(.firaCodeFixed(size: 9, weight: .semibold))
                .foregroundStyle(SolarTokens.mutedText.opacity(0.65))
                .frame(width: 56, alignment: .leading)
            Text(value)
                .font(.firaCodeFixed(size: 11, weight: .bold))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private func scaleChip(_ level: String) -> some View {
        let digit = level.last.flatMap { Int(String($0)) } ?? 0
        let color: Color = {
            switch digit {
            case 0:  return GalacticPalette.neonCyan
            case 1:  return GalacticPalette.mint
            case 2:  return GalacticPalette.peach
            case 3:  return GalacticPalette.hotPink
            default: return GalacticPalette.neonMagenta
            }
        }()
        return Text(level)
            .font(.firaCodeFixed(size: 10, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(Capsule().stroke(color.opacity(0.7), lineWidth: 0.6))
    }

    private func statusPill(label: String, value: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Text(label)
                .font(.firaCodeFixed(size: 8, weight: .semibold))
                .foregroundStyle(SolarTokens.mutedText.opacity(0.6))
            Text(value.uppercased())
                .font(.firaCodeFixed(size: 9, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(color)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Capsule().stroke(color.opacity(0.55), lineWidth: 0.5))
    }
}

// MARK: - Metrics derivation

struct SolarMetrics {
    let sfiText: String
    let sfiColor: Color
    let kpText: String
    let kpColor: Color
    let aIdxText: String
    let xRayClass: String
    let xRayColor: Color
    let xRayPeak: String
    let xRayPeakColor: Color
    let protonText: String
    let protonColor: Color
    let auroraText: String
    let mFlareText: String
    let rScale: String
    let sScale: String
    let gScale: String
    let geomag: String
    let hfDay: String
    let hfNight: String
    let sunspotNumber: Int?

    init(brief: Brief?) {
        let sfi = brief?.space?.solarFlux
        sfiText = sfi.map { String(Int($0.rounded())) } ?? "—"
        sfiColor = sfi.map(SolarTokens.sfiColor) ?? SolarTokens.mutedText

        let kp = brief?.space?.kpIndex
        kpText = kp.map { String(format: "%.1f", $0) } ?? "—"
        kpColor = kp.map(GalacticPalette.kp) ?? SolarTokens.mutedText

        // A-index: prefer today's outlook, fall back to WWV bulletin.
        let aIdx = brief?.solarOutlook.first?.aIndex ?? brief?.wwvBulletin?.aIndex
        aIdxText = aIdx.map(String.init) ?? "—"

        if let xr = brief?.xRay {
            xRayClass = xr.currentClass
            xRayColor = SolarTokens.xRayColor(xr.currentClass)
            xRayPeak = xr.peakClass24h
            xRayPeakColor = SolarTokens.xRayColor(xr.peakClass24h)
            rScale = xr.rScale
        } else {
            xRayClass = "—"; xRayColor = SolarTokens.mutedText
            xRayPeak = "—";  xRayPeakColor = SolarTokens.mutedText
            rScale = "R0"
        }

        if let p = brief?.proton {
            protonText = String(format: "%.1e", p.fluxPfu)
            sScale = p.sScale
            protonColor = (p.sScale == "S0") ? GalacticPalette.mint : GalacticPalette.hotPink
        } else {
            protonText = "—"; sScale = "S0"; protonColor = SolarTokens.mutedText
        }

        if let a = brief?.aurora {
            auroraText = "\(a.localProbabilityPct)% / \(a.globalMaxPct)%"
        } else {
            auroraText = "—"
        }

        if let fp = brief?.flareProbability {
            mFlareText = "M \(fp.mClassPct)% X \(fp.xClassPct)%"
        } else {
            mFlareText = "—"
        }

        gScale = Self.gScale(forKp: kp)
        geomag = Self.geomagLabel(forKp: kp)

        // Day/night HF: coarse single-word readout off the synthesized bands.
        let bands = brief?.bandConditions ?? []
        hfDay = Self.summarizeHF(bands.map(\.dayStatus))
        hfNight = Self.summarizeHF(bands.map(\.nightStatus))

        sunspotNumber = brief?.solarCycle.last
            .map { Int($0.sunspotNumber.rounded()) }
    }

    static func gScale(forKp kp: Double?) -> String {
        guard let kp else { return "G0" }
        switch kp {
        case ..<5: return "G0"
        case ..<6: return "G1"
        case ..<7: return "G2"
        case ..<8: return "G3"
        case ..<9: return "G4"
        default:   return "G5"
        }
    }

    static func geomagLabel(forKp kp: Double?) -> String {
        guard let kp else { return "—" }
        switch kp {
        case ..<2: return "Quiet"
        case ..<3: return "Unsett"
        case ..<4: return "Active"
        case ..<5: return "Minor"
        case ..<6: return "Mod"
        case ..<7: return "Strong"
        case ..<8: return "Severe"
        default:   return "Extreme"
        }
    }

    static func summarizeHF(_ statuses: [String]) -> String {
        guard !statuses.isEmpty else { return "—" }
        if statuses.contains(where: { $0.caseInsensitiveCompare("Open") == .orderedSame }) { return "Good" }
        if statuses.contains(where: { $0.caseInsensitiveCompare("Fair") == .orderedSame }) { return "Fair" }
        if statuses.contains(where: { $0.caseInsensitiveCompare("Poor") == .orderedSame }) { return "Poor" }
        return "Closed"
    }
}

// MARK: - Helpers

fileprivate func solarZuluTime(_ date: Date) -> String {
    let f = DateFormatter()
    f.timeZone = TimeZone(identifier: "UTC")
    f.dateFormat = "HHmm'Z'"
    return f.string(from: date)
}

fileprivate func solarUTCStamp(_ date: Date) -> String {
    let f = DateFormatter()
    f.timeZone = TimeZone(identifier: "UTC")
    f.dateFormat = "yyyy MMM dd HHmm 'UTC'"
    return f.string(from: date).uppercased()
}

fileprivate func solarShortDate(_ date: Date) -> String {
    let f = DateFormatter()
    f.timeZone = TimeZone(identifier: "UTC")
    f.dateFormat = "EEE d"
    return f.string(from: date).uppercased()
}

fileprivate func solarGeomagColor(_ label: String) -> Color {
    switch label.lowercased() {
    case "quiet":   return GalacticPalette.neonCyan
    case "unsett":  return GalacticPalette.mint
    case "active":  return GalacticPalette.peach
    case "minor":   return GalacticPalette.hotPink
    case "mod":     return GalacticPalette.hotPink
    case "strong":  return GalacticPalette.neonMagenta
    case "severe":  return GalacticPalette.neonMagenta
    case "extreme": return GalacticPalette.neonMagenta
    default:        return SolarTokens.mutedText
    }
}

fileprivate func solarHFColor(_ label: String) -> Color {
    switch label.lowercased() {
    case "good":   return GalacticPalette.mint
    case "fair":   return GalacticPalette.peach
    case "poor":   return GalacticPalette.hotPink
    case "closed": return GalacticPalette.neonMagenta
    default:       return SolarTokens.mutedText
    }
}
