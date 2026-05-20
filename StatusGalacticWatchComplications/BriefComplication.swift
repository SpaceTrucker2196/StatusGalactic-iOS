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
        VStack(spacing: 0) {
            if let temp = entry.brief?.earth?.periods.first?.temperature {
                Text("\(temp)°")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .monospacedDigit()
            } else {
                Image(systemName: "globe")
            }
            if let kp = entry.brief?.space?.kpIndex {
                Text("Kp \(String(format: "%.1f", kp))")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct CornerView: View {
    let entry: WatchComplicationEntry

    var body: some View {
        if let temp = entry.brief?.earth?.periods.first?.temperature {
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
        if let brief = entry.brief {
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
