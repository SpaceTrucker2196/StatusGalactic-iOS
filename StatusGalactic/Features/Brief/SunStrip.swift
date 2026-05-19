import SwiftUI

/// Horizontal 24-hour strip showing today's twilight phases as colored bands,
/// with a vertical "now" indicator and labeled event markers.
struct SunStrip: View {
    let sun: SolarEvents
    let now: Date

    private let height: CGFloat = 44

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                bands(in: geo.size)
                eventLabels(in: geo.size)
                nowIndicator(in: geo.size)
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(.quaternary, lineWidth: 0.5)
        )
    }

    // MARK: - Background bands

    private func bands(in size: CGSize) -> some View {
        let segments = computeSegments()
        return HStack(spacing: 0) {
            ForEach(segments.indices, id: \.self) { i in
                Rectangle()
                    .fill(segments[i].color)
                    .frame(width: max(0, size.width * CGFloat(segments[i].fraction)))
            }
        }
        .frame(height: size.height)
    }

    // MARK: - Event labels

    private func eventLabels(in size: CGSize) -> some View {
        let labels: [(Date?, String)] = [
            (sun.sunriseUtc, "↑"),
            (sun.sunsetUtc, "↓"),
        ]
        return ZStack(alignment: .topLeading) {
            ForEach(labels.indices, id: \.self) { i in
                if let date = labels[i].0 {
                    Text(labels[i].1)
                        .font(.caption2.bold())
                        .foregroundStyle(.primary)
                        .position(
                            x: xPosition(of: date, width: size.width),
                            y: size.height - 8
                        )
                }
            }
        }
    }

    // MARK: - Now indicator

    private func nowIndicator(in size: CGSize) -> some View {
        let x = xPosition(of: now, width: size.width)
        return Rectangle()
            .fill(.primary)
            .frame(width: 1.5, height: size.height)
            .offset(x: x - 0.75)
    }

    // MARK: - Segment math

    private struct Segment {
        let color: Color
        let fraction: Double
    }

    private func computeSegments() -> [Segment] {
        // Boundaries in chronological order within the local day. Missing events
        // are skipped (e.g. polar conditions).
        struct Boundary { let date: Date; let nextColor: Color }

        let phaseOrder: [(Date?, Color)] = [
            (sun.astronomicalDawnUtc, .twilightAstronomical),
            (sun.nauticalDawnUtc,     .twilightNautical),
            (sun.civilDawnUtc,        .twilightCivil),
            (sun.sunriseUtc,          .daylight),
            (sun.sunsetUtc,           .twilightCivil),
            (sun.civilDuskUtc,        .twilightNautical),
            (sun.nauticalDuskUtc,     .twilightAstronomical),
            (sun.astronomicalDuskUtc, .astronomicalDark),
        ]

        let dayStart = startOfLocalDay()
        let dayEnd = dayStart.addingTimeInterval(86400)
        let dayLength: TimeInterval = 86400

        // Starting color is whatever phase contains "dayStart" — assume astronomical dark
        // unless we determine otherwise from event ordering.
        var current = Color.astronomicalDark
        var lastTime: Date = dayStart
        var segments: [Segment] = []

        for (date, nextColor) in phaseOrder {
            guard let date else { continue }
            guard date >= dayStart && date <= dayEnd else { continue }
            let dt = date.timeIntervalSince(lastTime)
            if dt > 0 {
                segments.append(Segment(color: current, fraction: dt / dayLength))
            }
            current = nextColor
            lastTime = date
        }

        let remaining = dayEnd.timeIntervalSince(lastTime)
        if remaining > 0 {
            segments.append(Segment(color: current, fraction: remaining / dayLength))
        }
        return segments
    }

    private func xPosition(of date: Date, width: CGFloat) -> CGFloat {
        let start = startOfLocalDay()
        let elapsed = date.timeIntervalSince(start)
        let frac = max(0, min(1, elapsed / 86400))
        return width * CGFloat(frac)
    }

    private func startOfLocalDay() -> Date {
        var cal = Calendar.current
        cal.timeZone = TimeZone(identifier: sun.timezone) ?? .current
        return cal.startOfDay(for: now)
    }
}

private extension Color {
    static let astronomicalDark      = Color(red: 0.04, green: 0.04, blue: 0.10)
    static let twilightAstronomical  = Color(red: 0.10, green: 0.10, blue: 0.30)
    static let twilightNautical      = Color(red: 0.20, green: 0.30, blue: 0.55)
    static let twilightCivil         = Color(red: 0.50, green: 0.65, blue: 0.85)
    static let daylight              = Color(red: 1.00, green: 0.88, blue: 0.55)
}

#Preview {
    let sun = SolarEvents(
        timezone: "America/Chicago",
        sunriseUtc: ISO8601DateFormatter().date(from: "2026-05-19T10:35:00Z"),
        sunsetUtc:  ISO8601DateFormatter().date(from: "2026-05-20T01:28:00Z"),
        goldenMorningStartUtc: nil, goldenMorningEndUtc: nil,
        goldenEveningStartUtc: nil, goldenEveningEndUtc: nil,
        civilDawnUtc:         ISO8601DateFormatter().date(from: "2026-05-19T10:01:00Z"),
        civilDuskUtc:         ISO8601DateFormatter().date(from: "2026-05-20T02:01:00Z"),
        nauticalDawnUtc:      ISO8601DateFormatter().date(from: "2026-05-19T09:18:00Z"),
        nauticalDuskUtc:      ISO8601DateFormatter().date(from: "2026-05-20T02:44:00Z"),
        astronomicalDawnUtc:  ISO8601DateFormatter().date(from: "2026-05-19T08:28:00Z"),
        astronomicalDuskUtc:  ISO8601DateFormatter().date(from: "2026-05-20T03:35:00Z")
    )
    return SunStrip(sun: sun, now: Date()).padding()
}
