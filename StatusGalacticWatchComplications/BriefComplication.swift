import SwiftUI
import WidgetKit

struct BriefComplication: Widget {
    let kind: String = "io.river.statusgalactic.watch.briefComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchComplicationProvider()) { entry in
            ComplicationView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Galactic Brief")
        .description("Current temperature, sun status, Kp.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryCorner,
            .accessoryInline,
            .accessoryRectangular,
        ])
    }
}

struct ComplicationView: View {
    @Environment(\.widgetFamily) private var family
    let entry: WatchComplicationEntry

    var body: some View {
        switch family {
        case .accessoryCircular:    CircularView(entry: entry)
        case .accessoryCorner:      CornerView(entry: entry)
        case .accessoryInline:      InlineView(entry: entry)
        case .accessoryRectangular: RectangularView(entry: entry)
        default:                    InlineView(entry: entry)
        }
    }
}

private struct CircularView: View {
    let entry: WatchComplicationEntry

    var body: some View {
        if let alert = entry.brief?.weatherAlerts.first, alert.severityLevel >= 3 {
            VStack(spacing: 0) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.red)
                Text(stormBadge)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.red)
            }
        } else {
            VStack(spacing: 0) {
                if let temp = entry.brief?.earth?.periods.first?.temperature {
                    Text("\(temp)°")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .monospacedDigit()
                } else {
                    Image(systemName: "globe")
                }
                Text(stormBadge)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// Tightest R/S/G summary that fits in a circular complication. Returns
    /// the highest active scale letter+digit, or Kp if everything's quiet.
    private var stormBadge: String {
        let scales: [(letter: String, value: String?)] = [
            ("R", entry.brief?.xRay?.rScale),
            ("S", entry.brief?.proton?.sScale),
            ("G", entry.brief?.space?.kpIndex.map(gScaleString(forKp:))),
        ]
        let active = scales
            .compactMap { (_, val) -> String? in
                guard let val, let d = val.last.flatMap({ Int(String($0)) }), d >= 1 else { return nil }
                return val
            }
            .max(by: { ($0.last.flatMap { Int(String($0)) } ?? 0) < ($1.last.flatMap { Int(String($0)) } ?? 0) })
        if let active { return active }
        if let kp = entry.brief?.space?.kpIndex {
            return String(format: "Kp %.1f", kp)
        }
        return "—"
    }
}

/// Standalone helper for the complication target. Mirrors
/// SpaceWeatherForecastClient.gScaleString without importing the iOS-only
/// service layer.
private func gScaleString(forKp kp: Double) -> String {
    switch kp {
    case ..<5: return "G0"
    case ..<6: return "G1"
    case ..<7: return "G2"
    case ..<8: return "G3"
    case ..<9: return "G4"
    default:   return "G5"
    }
}

private struct CornerView: View {
    let entry: WatchComplicationEntry

    var body: some View {
        if let alert = entry.brief?.weatherAlerts.first, alert.severityLevel >= 3 {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .widgetLabel { Text(alert.event) }
        } else if let temp = entry.brief?.earth?.periods.first?.temperature {
            Text("\(temp)°")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .monospacedDigit()
                .widgetLabel {
                    if let cond = entry.brief?.earth?.periods.first?.shortForecast {
                        Text(cond)
                    }
                }
        } else {
            Image(systemName: "globe")
        }
    }
}

private struct InlineView: View {
    let entry: WatchComplicationEntry

    var body: some View {
        if let alert = entry.brief?.weatherAlerts.first, alert.severityLevel >= 3 {
            Text("⚠ \(alert.event)")
        } else if let brief = entry.brief {
            let temp = brief.earth?.periods.first?.temperature.map { "\($0)°" } ?? "--"
            let cond = brief.earth?.periods.first?.shortForecast ?? ""
            Text("\(temp) \(cond)")
        } else {
            Text("Galactic Brief")
        }
    }
}

private struct RectangularView: View {
    let entry: WatchComplicationEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let brief = entry.brief {
                if let alert = brief.weatherAlerts.first, alert.severityLevel >= 3 {
                    HStack(spacing: 3) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                        Text(alert.event)
                            .font(.caption2.weight(.bold))
                            .lineLimit(1)
                    }
                    .foregroundStyle(.red)
                }
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    if let temp = brief.earth?.periods.first?.temperature {
                        Text("\(temp)°")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .monospacedDigit()
                    }
                    if let cond = brief.earth?.periods.first?.shortForecast {
                        Text(cond)
                            .font(.caption2)
                            .lineLimit(1)
                            .foregroundStyle(.secondary)
                    }
                }
                stormScaleStrip(brief: brief)
                if let next = nextSunEvent(brief: brief, now: entry.date) {
                    HStack(spacing: 3) {
                        Image(systemName: next.icon).font(.caption2)
                        Text(next.label).font(.caption2)
                        Text(next.date, style: .relative)
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Text("Galactic Brief").font(.headline)
                Text("Pending data").font(.caption2).foregroundStyle(.secondary)
            }
        }
    }

    private func stormScaleStrip(brief: Brief) -> some View {
        HStack(spacing: 3) {
            scaleBadge(brief.xRay?.rScale ?? "R0")
            scaleBadge(brief.proton?.sScale ?? "S0")
            scaleBadge(brief.space?.kpIndex.map(gScaleString(forKp:)) ?? "G0")
        }
    }

    private func scaleBadge(_ level: String) -> some View {
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
    }

    private func nextSunEvent(brief: Brief, now: Date) -> (label: String, date: Date, icon: String)? {
        guard let sun = brief.sun else { return nil }
        let order: [(String, Date?, String)] = [
            ("Golden", sun.goldenEveningStartUtc, "sun.haze.fill"),
            ("Sunset", sun.sunsetUtc, "sunset.fill"),
            ("Astro dusk", sun.astronomicalDuskUtc, "moon.stars.fill"),
            ("Sunrise", sun.sunriseUtc, "sunrise.fill"),
        ]
        for (label, date, icon) in order {
            if let date, date > now {
                return (label, date, icon)
            }
        }
        return nil
    }
}
