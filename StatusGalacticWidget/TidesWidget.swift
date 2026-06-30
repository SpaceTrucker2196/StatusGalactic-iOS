import SwiftUI
import WidgetKit
import Charts

/// Tide table widget. Shows the next high/low predictions from the nearest
/// NOAA CO-OPS station, plus a small Catmull-Rom curve through the next ~24h
/// of events on the medium family.
///
/// Off-coast users see a gentle empty state — the widget still installs from
/// the gallery so it doesn't have to be added after travel.
struct TidesWidget: Widget {
    let kind: String = "io.river.statusgalactic.tidesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BriefWidgetProvider()) { entry in
            TidesWidgetView(entry: entry)
                .containerBackground(GalacticPalette.cosmicSky, for: .widget)
        }
        .configurationDisplayName("Tides")
        .description("Next high/low tide predictions from the nearest NOAA station.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - View

struct TidesWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: BriefWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:  TidesSmallView(entry: entry)
        case .systemMedium: TidesMediumView(entry: entry)
        default:            TidesSmallView(entry: entry)
        }
    }
}

// MARK: - Small

struct TidesSmallView: View {
    let entry: BriefWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            header
            Divider().background(GalacticPalette.phosphorGreen.opacity(0.4))

            if let tides = entry.brief?.tides, !tides.events.isEmpty {
                let upcoming = TidesHelpers.upcoming(in: tides, now: entry.date, limit: 2)
                if upcoming.isEmpty {
                    emptyBody("No upcoming predictions")
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(upcoming) { ev in
                            TideEventBlock(event: ev,
                                           now: entry.date,
                                           timezone: entry.brief?.timezone)
                        }
                        Spacer(minLength: 0)
                    }
                }
            } else {
                emptyBody("No tide station nearby")
            }
        }
        .padding(2)
        .foregroundStyle(TidesPalette.mutedText)
    }

    private var header: some View {
        HStack(spacing: 4) {
            Image(systemName: "water.waves")
                .font(.firaCodeFixed(size: 10, weight: .bold))
                .foregroundStyle(GalacticPalette.electricBlue)
                .neonGlow(GalacticPalette.electricBlue, intensity: 3)
            Text("TIDES")
                .font(.firaCodeFixed(size: 11, weight: .bold))
                .tracking(2)
                .foregroundStyle(GalacticPalette.phosphorGreen)
                .neonGlow(GalacticPalette.phosphorGreen, intensity: 3)
            Spacer()
            if let id = entry.brief?.tides?.stationId {
                Text(id)
                    .font(.firaCodeFixed(size: 9))
                    .foregroundStyle(GalacticPalette.phosphorGreen.opacity(0.75))
                    .lineLimit(1)
            }
        }
    }

    private func emptyBody(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Spacer(minLength: 0)
            Image(systemName: "water.waves.slash")
                .font(.system(size: 22))
                .foregroundStyle(TidesPalette.mutedText.opacity(0.5))
            Text(message)
                .font(.firaCodeFixed(size: 10))
                .foregroundStyle(TidesPalette.mutedText.opacity(0.7))
                .lineLimit(2)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Medium

struct TidesMediumView: View {
    let entry: BriefWidgetEntry

    var body: some View {
        VStack(spacing: 4) {
            header
            Divider().background(GalacticPalette.phosphorGreen.opacity(0.4))

            if let tides = entry.brief?.tides, !tides.events.isEmpty {
                let visible = TidesHelpers.visibleWindow(in: tides, now: entry.date, count: 8)
                let upcoming = TidesHelpers.upcoming(in: tides, now: entry.date, limit: 3)

                HStack(alignment: .top, spacing: 10) {
                    TidesCurve(events: visible, now: entry.date)
                        .frame(width: 150)
                    Divider().background(GalacticPalette.neonCyan.opacity(0.25))
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(upcoming) { ev in
                            TideEventBlock(event: ev,
                                           now: entry.date,
                                           timezone: entry.brief?.timezone)
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                emptyBody
            }
        }
        .padding(2)
        .foregroundStyle(TidesPalette.mutedText)
    }

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "water.waves")
                .font(.firaCodeFixed(size: 11, weight: .bold))
                .foregroundStyle(GalacticPalette.electricBlue)
                .neonGlow(GalacticPalette.electricBlue, intensity: 4)
            Text("TIDES")
                .font(.firaCodeFixed(size: 11, weight: .bold))
                .tracking(2.5)
                .foregroundStyle(GalacticPalette.phosphorGreen)
                .neonGlow(GalacticPalette.phosphorGreen, intensity: 4)
            if let tides = entry.brief?.tides {
                Text("·")
                    .foregroundStyle(GalacticPalette.phosphorGreen.opacity(0.4))
                Text(tides.stationName.uppercased())
                    .font(.firaCodeFixed(size: 10, weight: .semibold))
                    .foregroundStyle(GalacticPalette.neonCyan)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            Spacer(minLength: 0)
            if let tides = entry.brief?.tides {
                Text(TidesHelpers.distanceLabel(km: tides.distanceKm))
                    .font(.firaCodeFixed(size: 9))
                    .foregroundStyle(GalacticPalette.phosphorGreen.opacity(0.75))
            }
        }
    }

    private var emptyBody: some View {
        HStack(spacing: 12) {
            Image(systemName: "water.waves.slash")
                .font(.system(size: 32))
                .foregroundStyle(TidesPalette.mutedText.opacity(0.5))
            VStack(alignment: .leading, spacing: 2) {
                Text("No tide station nearby")
                    .font(.firaCodeFixed(size: 12, weight: .bold))
                    .foregroundStyle(TidesPalette.mutedText)
                Text("Move within ~200 km of a NOAA CO-OPS station to see predictions.")
                    .font(.firaCodeFixed(size: 9))
                    .foregroundStyle(TidesPalette.mutedText.opacity(0.7))
                    .lineLimit(3)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Components

private struct TideEventBlock: View {
    let event: TideEvent
    let now: Date
    let timezone: String?

    var body: some View {
        let isHigh = event.kind == .high
        let color: Color = isHigh ? GalacticPalette.hotPink : GalacticPalette.electricBlue
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Image(systemName: isHigh ? "arrow.up" : "arrow.down")
                .font(.firaCodeFixed(size: 10, weight: .bold))
                .foregroundStyle(color)
                .neonGlow(color, intensity: 2)
            Text(isHigh ? "HIGH" : "LOW")
                .font(.firaCodeFixed(size: 10, weight: .bold))
                .tracking(1)
                .foregroundStyle(color)
                .frame(width: 36, alignment: .leading)
            Text(TidesHelpers.shortLocal(event.time, tz: timezone))
                .font(.firaCodeFixed(size: 10, weight: .semibold))
                .foregroundStyle(GalacticPalette.peach)
            Spacer(minLength: 0)
            Text(String(format: "%.1fft", event.heightFt))
                .font(.firaCodeFixed(size: 10, weight: .bold))
                .foregroundStyle(GalacticPalette.neonCyan)
                .neonGlow(GalacticPalette.neonCyan, intensity: 2)
            Text(TidesHelpers.compactDelta(from: now, to: event.time))
                .font(.firaCodeFixed(size: 9))
                .foregroundStyle(TidesPalette.mutedText.opacity(0.6))
                .frame(width: 30, alignment: .trailing)
        }
    }
}

private struct TidesCurve: View {
    let events: [TideEvent]
    let now: Date

    var body: some View {
        let uniqueHeights = Set(events.map { $0.heightFt })
        if events.count >= 2 && uniqueHeights.count >= 2 {
            Chart {
                ForEach(events) { event in
                    LineMark(
                        x: .value("Time", event.time),
                        y: .value("Ft", event.heightFt)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(GalacticPalette.electricBlue)
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                    AreaMark(
                        x: .value("Time", event.time),
                        y: .value("Ft", event.heightFt)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                GalacticPalette.electricBlue.opacity(0.45),
                                GalacticPalette.electricBlue.opacity(0.02)
                            ],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    PointMark(
                        x: .value("Time", event.time),
                        y: .value("Ft", event.heightFt)
                    )
                    .foregroundStyle(event.kind == .high
                                     ? GalacticPalette.hotPink
                                     : GalacticPalette.electricBlue)
                    .symbolSize(18)
                }
                RuleMark(x: .value("Now", now))
                    .lineStyle(StrokeStyle(lineWidth: 0.7, dash: [3, 3]))
                    .foregroundStyle(GalacticPalette.neonCyan.opacity(0.7))
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartPlotStyle { plot in
                plot.background(Color.clear)
            }
        } else {
            VStack(spacing: 2) {
                Image(systemName: "wave.3.right")
                    .font(.system(size: 20))
                    .foregroundStyle(GalacticPalette.electricBlue.opacity(0.6))
                Text("Curve unavailable")
                    .font(.firaCodeFixed(size: 9))
                    .foregroundStyle(TidesPalette.mutedText.opacity(0.6))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Helpers

private enum TidesPalette {
    static let mutedText = Color(red: 0.78, green: 0.82, blue: 0.96)
}

private enum TidesHelpers {

    static func upcoming(in tides: Tides, now: Date, limit: Int) -> [TideEvent] {
        let future = tides.events.filter { $0.time >= now }
        if future.isEmpty {
            return Array(tides.events.suffix(limit))
        }
        return Array(future.prefix(limit))
    }

    /// Curve window: the last event before `now` plus everything ahead, up
    /// to `count`. Anchoring with one past event keeps the curve from
    /// starting at the "now" line on a flat segment.
    static func visibleWindow(in tides: Tides, now: Date, count: Int) -> [TideEvent] {
        let sorted = tides.events.sorted { $0.time < $1.time }
        let firstFutureIdx = sorted.firstIndex { $0.time >= now } ?? sorted.endIndex
        let start = max(0, firstFutureIdx - 1)
        let end = min(sorted.count, start + count)
        return Array(sorted[start..<end])
    }

    static func shortLocal(_ date: Date, tz: String?) -> String {
        let f = DateFormatter()
        f.timeZone = TimeZone(identifier: tz ?? TimeZone.current.identifier) ?? .current
        f.dateFormat = "EEE h:mma"
        return f.string(from: date).replacingOccurrences(of: "AM", with: "a")
            .replacingOccurrences(of: "PM", with: "p")
    }

    static func compactDelta(from now: Date, to future: Date) -> String {
        let secs = future.timeIntervalSince(now)
        let abs = Swift.abs(secs)
        let prefix = secs < 0 ? "-" : ""
        if abs < 3600 {
            return "\(prefix)\(Int(abs / 60))m"
        }
        if abs < 86_400 {
            let h = Int(abs / 3600)
            return "\(prefix)\(h)h"
        }
        let d = Int(abs / 86_400)
        return "\(prefix)\(d)d"
    }

    static func distanceLabel(km: Double) -> String {
        let mi = km * 0.6213711922
        if mi < 10 {
            return String(format: "%.1fmi", mi)
        }
        return String(format: "%.0fmi", mi)
    }
}
