import SwiftUI

/// Shared brief panel — used by the `BriefWidget` and by the iPad
/// `PanelGrid`. Factored out of `StatusGalacticWidget/BriefWidgetView.swift`
/// so both hosts render the same pixels.
///
/// Renderer accepts `brief` + `referenceDate` — no App-Group defaults, no
/// WidgetKit types. Widget shell passes the entry's brief/date; iPad host
/// passes its own state.
///
/// Initial slice: `.tall` and `.large` fall through to `.small` / `.wide`.
/// Bespoke layouts for the new sizes land per-panel as design iterates.
struct BriefPanel: View {
    let size: PanelSize
    let brief: Brief?
    let errorMessage: String?
    let referenceDate: Date

    init(
        size: PanelSize,
        brief: Brief?,
        referenceDate: Date = Date(),
        errorMessage: String? = nil
    ) {
        self.size = size
        self.brief = brief
        self.errorMessage = errorMessage
        self.referenceDate = referenceDate
    }

    var body: some View {
        switch size {
        case .small: BriefSmallView(brief: brief, errorMessage: errorMessage, referenceDate: referenceDate)
        case .wide:  BriefMediumView(brief: brief, errorMessage: errorMessage, referenceDate: referenceDate)
        case .tall:  BriefTallView(brief: brief, errorMessage: errorMessage, referenceDate: referenceDate)
        case .large: BriefLargeView(brief: brief, errorMessage: errorMessage, referenceDate: referenceDate)
        }
    }
}

// MARK: - Small

struct BriefSmallView: View {
    let brief: Brief?
    let errorMessage: String?
    let referenceDate: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let brief {
                Text(brief.locationName ?? briefCoordsLabel(brief))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if let temp = briefCurrentTemp(brief) {
                    Text("\(temp)°")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .monospacedDigit()
                } else {
                    Text("—")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                }

                if let cond = briefCurrentCondition(brief) {
                    Text(cond)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                if let alert = brief.weatherAlerts.first {
                    alertChip(alert)
                } else if let next = briefNextSunEvent(brief, now: referenceDate) {
                    HStack(spacing: 4) {
                        Image(systemName: next.icon).font(.caption2)
                        Text("\(next.label) \(next.date, style: .relative)")
                            .font(.caption2)
                            .monospacedDigit()
                    }
                    .foregroundStyle(.orange)
                }
            } else {
                placeholder
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func alertChip(_ alert: WeatherAlert) -> some View {
        let color: Color = {
            switch alert.severityLevel {
            case 4: return .red
            case 3: return .orange
            case 2: return .yellow
            default: return .secondary
            }
        }()
        return HStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill").font(.caption2)
            Text(alert.event)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Capsule().fill(color.opacity(0.18)))
        .overlay(Capsule().stroke(color, lineWidth: 0.5))
    }

    @ViewBuilder
    private var placeholder: some View {
        VStack(alignment: .leading) {
            Image(systemName: "globe.americas").font(.title2)
            Text("Spacetrucker Galactic").font(.caption.weight(.semibold))
            if let err = errorMessage {
                Text(err).font(.caption2).foregroundStyle(.secondary).lineLimit(3)
            } else {
                Text("No data").font(.caption2).foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Medium

struct BriefMediumView: View {
    let brief: Brief?
    let errorMessage: String?
    let referenceDate: Date

    var body: some View {
        if let brief {
            VStack(spacing: 4) {
                if let alert = brief.weatherAlerts.first {
                    alertBanner(alert, more: brief.weatherAlerts.count - 1)
                }
                HStack(alignment: .top, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(brief.locationName ?? briefCoordsLabel(brief))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        if let temp = briefCurrentTemp(brief) {
                            Text("\(temp)°")
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .monospacedDigit()
                        }
                        if let cond = briefCurrentCondition(brief) {
                            Text(cond)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        Spacer(minLength: 0)
                        stormScaleRow(brief)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Divider()

                    VStack(alignment: .leading, spacing: 6) {
                        if let sunrise = brief.sun?.sunriseUtc {
                            sunRow(icon: "sunrise.fill", label: "Sunrise", date: sunrise, tz: brief.sun?.timezone)
                        }
                        if let sunset = brief.sun?.sunsetUtc {
                            sunRow(icon: "sunset.fill", label: "Sunset", date: sunset, tz: brief.sun?.timezone)
                        }
                        if let next = briefNextSunEvent(brief, now: referenceDate) {
                            sunRow(
                                icon: next.icon,
                                label: next.label,
                                date: next.date,
                                tz: brief.sun?.timezone,
                                highlight: true
                            )
                        }
                        if let moon = brief.moon {
                            HStack(spacing: 4) {
                                Image(systemName: moonIcon(for: moon)).font(.caption2)
                                Text("\(Int(moon.illuminationPct))% \(moon.phaseName)")
                                    .font(.caption2)
                                    .lineLimit(1)
                            }
                            .foregroundStyle(.secondary)
                        }
                        if let aurora = brief.aurora, aurora.localProbabilityPct >= 10 {
                            HStack(spacing: 4) {
                                Image(systemName: "aqi.medium").font(.caption2)
                                Text("Aurora \(aurora.localProbabilityPct)%")
                                    .font(.caption2.weight(.semibold))
                            }
                            .foregroundStyle(.purple)
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        } else {
            BriefSmallView(brief: nil, errorMessage: errorMessage, referenceDate: referenceDate)
        }
    }

    private func alertBanner(_ alert: WeatherAlert, more: Int) -> some View {
        briefAlertBanner(alert, more: more)
    }

    private func stormScaleRow(_ brief: Brief) -> some View {
        HStack(spacing: 4) {
            briefScalePill(brief.xRay?.rScale ?? "R0")
            briefScalePill(brief.proton?.sScale ?? "S0")
            briefScalePill(briefGScale(forKp: brief.space?.kpIndex))
        }
    }

    private func sunRow(icon: String, label: String, date: Date, tz: String?, highlight: Bool = false) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.caption2)
            Text(label).font(.caption2)
            Spacer()
            Text(briefFormatTime(date, tz: tz))
                .font(.caption2.monospacedDigit())
                .foregroundStyle(highlight ? .orange : .primary)
        }
    }

    private func moonIcon(for moon: Moon) -> String {
        briefMoonIcon(for: moon)
    }
}

// MARK: - Tall (1×2)

/// Portrait Brief tile: header + temp + condition up top, then a stacked
/// forecast of sunrise / sunset / next sun event / moon / aurora / alert
/// running down the panel. The extra vertical height buys us the full
/// sun schedule that the .small tile has to drop.
struct BriefTallView: View {
    let brief: Brief?
    let errorMessage: String?
    let referenceDate: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let brief {
                Text(brief.locationName ?? briefCoordsLabel(brief))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    if let temp = briefCurrentTemp(brief) {
                        Text("\(temp)°")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .monospacedDigit()
                    } else {
                        Text("—")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                    }
                    Spacer(minLength: 0)
                    briefTallStormRow(brief)
                }

                if let cond = briefCurrentCondition(brief) {
                    Text(cond)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                if let alert = brief.weatherAlerts.first {
                    briefTallAlertChip(alert)
                }

                Divider().background(GalacticPalette.phosphorGreen.opacity(0.35))

                VStack(alignment: .leading, spacing: 5) {
                    if let sunrise = brief.sun?.sunriseUtc {
                        briefTallSunRow(icon: "sunrise.fill", label: "Sunrise", date: sunrise, tz: brief.sun?.timezone)
                    }
                    if let sunset = brief.sun?.sunsetUtc {
                        briefTallSunRow(icon: "sunset.fill", label: "Sunset", date: sunset, tz: brief.sun?.timezone)
                    }
                    if let next = briefNextSunEvent(brief, now: referenceDate) {
                        briefTallSunRow(icon: next.icon, label: next.label, date: next.date, tz: brief.sun?.timezone, highlight: true)
                    }
                    if let moon = brief.moon {
                        HStack(spacing: 4) {
                            Image(systemName: briefMoonIcon(for: moon)).font(.caption2)
                            Text("\(Int(moon.illuminationPct))% \(moon.phaseName)")
                                .font(.caption2)
                                .lineLimit(1)
                        }
                        .foregroundStyle(.secondary)
                    }
                    if let aurora = brief.aurora, aurora.localProbabilityPct >= 10 {
                        HStack(spacing: 4) {
                            Image(systemName: "aqi.medium").font(.caption2)
                            Text("Aurora \(aurora.localProbabilityPct)%")
                                .font(.caption2.weight(.semibold))
                        }
                        .foregroundStyle(.purple)
                    }
                }

                Spacer(minLength: 0)
            } else {
                BriefSmallView(brief: nil, errorMessage: errorMessage, referenceDate: referenceDate)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func briefTallStormRow(_ brief: Brief) -> some View {
        HStack(spacing: 4) {
            briefScalePill(brief.xRay?.rScale ?? "R0")
            briefScalePill(brief.proton?.sScale ?? "S0")
            briefScalePill(briefGScale(forKp: brief.space?.kpIndex))
        }
    }

    private func briefTallAlertChip(_ alert: WeatherAlert) -> some View {
        let color: Color = briefAlertColor(alert)
        return HStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill").font(.caption2)
            Text(alert.event)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Capsule().fill(color.opacity(0.18)))
        .overlay(Capsule().stroke(color, lineWidth: 0.5))
    }

    private func briefTallSunRow(icon: String, label: String, date: Date, tz: String?, highlight: Bool = false) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.caption2)
            Text(label).font(.caption2)
            Spacer()
            Text(briefFormatTime(date, tz: tz))
                .font(.caption2.monospacedDigit())
                .foregroundStyle(highlight ? .orange : .primary)
        }
    }
}

// MARK: - Large (2×2)

/// Full 2×2 Brief dashboard: medium content up top (temp/condition/storm
/// on the left, sun schedule + moon + aurora on the right), plus a lower
/// half showing the current period's detailed NWS forecast and up to
/// three upcoming periods so the extra area actually earns its keep.
struct BriefLargeView: View {
    let brief: Brief?
    let errorMessage: String?
    let referenceDate: Date

    var body: some View {
        if let brief {
            VStack(spacing: 8) {
                if let alert = brief.weatherAlerts.first {
                    briefLargeAlertBanner(alert, more: brief.weatherAlerts.count - 1)
                }

                HStack(alignment: .top, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(brief.locationName ?? briefCoordsLabel(brief))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        if let temp = briefCurrentTemp(brief) {
                            Text("\(temp)°")
                                .font(.system(size: 50, weight: .bold, design: .rounded))
                                .monospacedDigit()
                        }
                        if let cond = briefCurrentCondition(brief) {
                            Text(cond)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        Spacer(minLength: 0)
                        briefLargeStormRow(brief)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Divider()

                    VStack(alignment: .leading, spacing: 6) {
                        if let sunrise = brief.sun?.sunriseUtc {
                            briefLargeSunRow(icon: "sunrise.fill", label: "Sunrise", date: sunrise, tz: brief.sun?.timezone)
                        }
                        if let sunset = brief.sun?.sunsetUtc {
                            briefLargeSunRow(icon: "sunset.fill", label: "Sunset", date: sunset, tz: brief.sun?.timezone)
                        }
                        if let next = briefNextSunEvent(brief, now: referenceDate) {
                            briefLargeSunRow(icon: next.icon, label: next.label, date: next.date, tz: brief.sun?.timezone, highlight: true)
                        }
                        if let moon = brief.moon {
                            HStack(spacing: 4) {
                                Image(systemName: briefMoonIcon(for: moon)).font(.caption2)
                                Text("\(Int(moon.illuminationPct))% \(moon.phaseName)")
                                    .font(.caption2)
                                    .lineLimit(1)
                            }
                            .foregroundStyle(.secondary)
                        }
                        if let aurora = brief.aurora, aurora.localProbabilityPct >= 10 {
                            HStack(spacing: 4) {
                                Image(systemName: "aqi.medium").font(.caption2)
                                Text("Aurora \(aurora.localProbabilityPct)%")
                                    .font(.caption2.weight(.semibold))
                            }
                            .foregroundStyle(.purple)
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Divider().background(GalacticPalette.phosphorGreen.opacity(0.35))

                briefLargeForecast(brief)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        } else {
            BriefSmallView(brief: nil, errorMessage: errorMessage, referenceDate: referenceDate)
        }
    }

    @ViewBuilder
    private func briefLargeForecast(_ brief: Brief) -> some View {
        let periods = brief.earth?.periods ?? []
        if periods.isEmpty {
            Text("Forecast unavailable")
                .font(.caption2)
                .foregroundStyle(.secondary)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                if let first = periods.first, let detailed = first.detailedForecast, !detailed.isEmpty {
                    Text(first.name.uppercased())
                        .font(.firaCodeFixed(size: 9, weight: .bold))
                        .tracking(1.2)
                        .foregroundStyle(GalacticPalette.phosphorGreen)
                    Text(detailed)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(4)
                }
                if periods.count > 1 {
                    Divider().background(GalacticPalette.neonCyan.opacity(0.25))
                    ForEach(Array(periods.dropFirst().prefix(3)), id: \.name) { period in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(period.name)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(GalacticPalette.peach)
                                .frame(width: 96, alignment: .leading)
                            if let t = period.temperature {
                                Text("\(t)°")
                                    .font(.caption.weight(.bold))
                                    .monospacedDigit()
                                    .foregroundStyle(GalacticPalette.temperature(t))
                                    .frame(width: 44, alignment: .leading)
                            }
                            Text(period.shortForecast)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            Spacer(minLength: 0)
                        }
                    }
                }
            }
        }
    }

    private func briefLargeStormRow(_ brief: Brief) -> some View {
        HStack(spacing: 4) {
            briefScalePill(brief.xRay?.rScale ?? "R0")
            briefScalePill(brief.proton?.sScale ?? "S0")
            briefScalePill(briefGScale(forKp: brief.space?.kpIndex))
        }
    }

    private func briefLargeSunRow(icon: String, label: String, date: Date, tz: String?, highlight: Bool = false) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.caption2)
            Text(label).font(.caption2)
            Spacer()
            Text(briefFormatTime(date, tz: tz))
                .font(.caption2.monospacedDigit())
                .foregroundStyle(highlight ? .orange : .primary)
        }
    }

    private func briefLargeAlertBanner(_ alert: WeatherAlert, more: Int) -> some View {
        let color = briefAlertColor(alert)
        return HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption2)
                .foregroundStyle(color)
            Text(alert.event)
                .font(.caption2.weight(.bold))
                .foregroundStyle(color)
                .lineLimit(1)
            if more > 0 {
                Text("+\(more)")
                    .font(.caption2)
                    .foregroundStyle(color.opacity(0.8))
            }
            Spacer()
            if let area = alert.areaDesc {
                Text(area)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(RoundedRectangle(cornerRadius: 6).fill(color.opacity(0.15)))
    }
}

// MARK: - Shared helpers (file-private with `brief` prefix so they don't
// collide with identically-named helpers in other panel files.)

// Palette / formatting helpers shared by every Brief*View in this file.

func briefAlertColor(_ alert: WeatherAlert) -> Color {
    switch alert.severityLevel {
    case 4: return .red
    case 3: return .orange
    case 2: return .yellow
    default: return .secondary
    }
}

func briefGScale(forKp kp: Double?) -> String {
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

func briefScalePill(_ level: String) -> some View {
    let digit = level.last.flatMap { Int(String($0)) } ?? 0
    let color: Color = {
        switch digit {
        case 0: return .green
        case 1: return .yellow
        case 2: return .orange
        case 3: return .red
        default: return .pink
        }
    }()
    return Text(level)
        .font(.caption2.weight(.bold))
        .foregroundStyle(color)
        .padding(.horizontal, 5)
        .padding(.vertical, 1)
        .background(Capsule().fill(color.opacity(0.18)))
        .overlay(Capsule().stroke(color.opacity(0.7), lineWidth: 0.5))
}

func briefFormatTime(_ date: Date, tz: String?) -> String {
    let f = DateFormatter()
    f.timeZone = TimeZone(identifier: tz ?? "UTC") ?? .current
    f.dateFormat = "h:mm a"
    return f.string(from: date)
}

func briefMoonIcon(for moon: Moon) -> String {
    switch moon.phaseName.lowercased() {
    case let s where s.contains("new"):              return "moonphase.new.moon"
    case let s where s.contains("waxing crescent"):  return "moonphase.waxing.crescent"
    case let s where s.contains("first quarter"):    return "moonphase.first.quarter"
    case let s where s.contains("waxing gibbous"):   return "moonphase.waxing.gibbous"
    case let s where s.contains("full"):             return "moonphase.full.moon"
    case let s where s.contains("waning gibbous"):   return "moonphase.waning.gibbous"
    case let s where s.contains("last quarter"):     return "moonphase.last.quarter"
    case let s where s.contains("waning crescent"):  return "moonphase.waning.crescent"
    default:                                         return "moon"
    }
}

func briefAlertBanner(_ alert: WeatherAlert, more: Int) -> some View {
    let color = briefAlertColor(alert)
    return HStack(spacing: 6) {
        Image(systemName: "exclamationmark.triangle.fill")
            .font(.caption2)
            .foregroundStyle(color)
        Text(alert.event)
            .font(.caption2.weight(.bold))
            .foregroundStyle(color)
            .lineLimit(1)
        if more > 0 {
            Text("+\(more)")
                .font(.caption2)
                .foregroundStyle(color.opacity(0.8))
        }
        Spacer()
        if let area = alert.areaDesc {
            Text(area)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
    .padding(.horizontal, 6)
    .padding(.vertical, 3)
    .background(RoundedRectangle(cornerRadius: 6).fill(color.opacity(0.15)))
}

func briefCoordsLabel(_ brief: Brief) -> String {
    String(format: "%.2f, %.2f", brief.lat, brief.lng)
}

func briefCurrentTemp(_ brief: Brief) -> Int? {
    brief.earth?.periods.first?.temperature
}

func briefCurrentCondition(_ brief: Brief) -> String? {
    brief.earth?.periods.first?.shortForecast
}

struct BriefNextSunEvent {
    let label: String
    let date: Date
    let icon: String
}

func briefNextSunEvent(_ brief: Brief, now: Date) -> BriefNextSunEvent? {
    guard let sun = brief.sun else { return nil }

    let candidates: [(String, Date?, String)] = [
        ("Golden hour", sun.goldenEveningStartUtc, "sun.haze.fill"),
        ("Sunset",      sun.sunsetUtc,             "sunset.fill"),
        ("Astro dusk",  sun.astronomicalDuskUtc,   "moon.stars.fill"),
        ("Sunrise",     sun.sunriseUtc,            "sunrise.fill"),
    ]
    for (label, date, icon) in candidates {
        if let date, date > now {
            return BriefNextSunEvent(label: label, date: date, icon: icon)
        }
    }
    return nil
}
