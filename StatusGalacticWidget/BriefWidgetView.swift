import SwiftUI
import WidgetKit

struct BriefWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: BriefWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallView(entry: entry)
        case .systemMedium:
            MediumView(entry: entry)
        default:
            SmallView(entry: entry)
        }
    }
}

// MARK: - Small

private struct SmallView: View {
    let entry: BriefWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let brief = entry.brief {
                Text(brief.locationName ?? coordsLabel(brief))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if let temp = currentTemp(brief) {
                    Text("\(temp)°")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .monospacedDigit()
                } else {
                    Text("—")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                }

                if let cond = currentCondition(brief) {
                    Text(cond)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                if let next = nextSunEvent(brief, now: entry.date) {
                    HStack(spacing: 4) {
                        Image(systemName: next.icon)
                            .font(.caption2)
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

    @ViewBuilder
    private var placeholder: some View {
        VStack(alignment: .leading) {
            Image(systemName: "globe.americas").font(.title2)
            Text("Status Galactic").font(.caption.weight(.semibold))
            if let err = entry.errorMessage {
                Text(err).font(.caption2).foregroundStyle(.secondary).lineLimit(3)
            } else {
                Text("No data").font(.caption2).foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Medium

private struct MediumView: View {
    let entry: BriefWidgetEntry

    var body: some View {
        if let brief = entry.brief {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(brief.locationName ?? coordsLabel(brief))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    if let temp = currentTemp(brief) {
                        Text("\(temp)°")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .monospacedDigit()
                    }
                    if let cond = currentCondition(brief) {
                        Text(cond)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    Spacer(minLength: 0)
                    if let kp = brief.space?.kpIndex {
                        HStack(spacing: 4) {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .font(.caption2)
                            Text("Kp \(String(format: "%.1f", kp))")
                                .font(.caption2)
                                .monospacedDigit()
                            if let status = brief.space?.kpStatus {
                                Text("(\(status))").font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
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
                    if let next = nextSunEvent(brief, now: entry.date) {
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
                            Image(systemName: moonIcon(for: moon))
                                .font(.caption2)
                            Text("\(Int(moon.illuminationPct))% \(moon.phaseName)")
                                .font(.caption2)
                                .lineLimit(1)
                        }
                        .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            SmallView(entry: entry)
        }
    }

    private func sunRow(icon: String, label: String, date: Date, tz: String?, highlight: Bool = false) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.caption2)
            Text(label).font(.caption2)
            Spacer()
            Text(formatTime(date, tz: tz))
                .font(.caption2.monospacedDigit())
                .foregroundStyle(highlight ? .orange : .primary)
        }
    }

    private func formatTime(_ date: Date, tz: String?) -> String {
        let f = DateFormatter()
        f.timeZone = TimeZone(identifier: tz ?? "UTC") ?? .current
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }

    private func moonIcon(for moon: Moon) -> String {
        switch moon.phaseName.lowercased() {
        case let s where s.contains("new"): return "moonphase.new.moon"
        case let s where s.contains("waxing crescent"): return "moonphase.waxing.crescent"
        case let s where s.contains("first quarter"): return "moonphase.first.quarter"
        case let s where s.contains("waxing gibbous"): return "moonphase.waxing.gibbous"
        case let s where s.contains("full"): return "moonphase.full.moon"
        case let s where s.contains("waning gibbous"): return "moonphase.waning.gibbous"
        case let s where s.contains("last quarter"): return "moonphase.last.quarter"
        case let s where s.contains("waning crescent"): return "moonphase.waning.crescent"
        default: return "moon"
        }
    }
}

// MARK: - Shared helpers

private func coordsLabel(_ brief: Brief) -> String {
    String(format: "%.2f, %.2f", brief.lat, brief.lng)
}

private func currentTemp(_ brief: Brief) -> Int? {
    brief.earth?.periods.first?.temperature
}

private func currentCondition(_ brief: Brief) -> String? {
    brief.earth?.periods.first?.shortForecast
}

private struct NextSunEvent {
    let label: String
    let date: Date
    let icon: String
}

private func nextSunEvent(_ brief: Brief, now: Date) -> NextSunEvent? {
    guard let sun = brief.sun else { return nil }

    let candidates: [(String, Date?, String)] = [
        ("Golden hour", sun.goldenEveningStartUtc, "sun.haze.fill"),
        ("Sunset", sun.sunsetUtc, "sunset.fill"),
        ("Astro dusk", sun.astronomicalDuskUtc, "moon.stars.fill"),
        ("Sunrise", sun.sunriseUtc, "sunrise.fill"),
    ]
    for (label, date, icon) in candidates {
        if let date, date > now {
            return NextSunEvent(label: label, date: date, icon: icon)
        }
    }
    return nil
}
