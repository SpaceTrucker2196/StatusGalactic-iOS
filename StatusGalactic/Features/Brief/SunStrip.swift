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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        var parts: [String] = ["Sun day strip."]
        let tz = TimeZone(identifier: sun.timezone) ?? .current
        let f = DateFormatter()
        f.timeZone = tz
        f.timeStyle = .short
        if let sr = sun.sunriseUtc { parts.append("Sunrise \(f.string(from: sr)).") }
        if let ss = sun.sunsetUtc { parts.append("Sunset \(f.string(from: ss)).") }
        parts.append("Currently \(currentPhaseLabel).")
        return parts.joined(separator: " ")
    }

    private var currentPhaseLabel: String {
        if let sr = sun.sunriseUtc, let ss = sun.sunsetUtc, now >= sr && now < ss {
            return "daylight"
        }
        if let civilDawn = sun.civilDawnUtc, let sr = sun.sunriseUtc, now >= civilDawn && now < sr {
            return "civil twilight before sunrise"
        }
        if let ss = sun.sunsetUtc, let civilDusk = sun.civilDuskUtc, now >= ss && now < civilDusk {
            return "civil twilight after sunset"
        }
        if let nauticalDawn = sun.nauticalDawnUtc, let civilDawn = sun.civilDawnUtc, now >= nauticalDawn && now < civilDawn {
            return "nautical twilight before dawn"
        }
        if let civilDusk = sun.civilDuskUtc, let nauticalDusk = sun.nauticalDuskUtc, now >= civilDusk && now < nauticalDusk {
            return "nautical twilight after dusk"
        }
        return "darkness"
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
            .fill(GalacticPalette.neonCyan)
            .frame(width: 2, height: size.height)
            .offset(x: x - 1)
            .shadow(color: GalacticPalette.neonCyan.opacity(0.9), radius: 4)
            .shadow(color: GalacticPalette.neonCyan.opacity(0.5), radius: 10)
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
            (sun.astronomicalDawnUtc, GalacticPalette.astronomicalTwilight),
            (sun.nauticalDawnUtc,     GalacticPalette.nauticalTwilight),
            (sun.civilDawnUtc,        GalacticPalette.civilTwilight),
            (sun.sunriseUtc,          GalacticPalette.daylight),
            (sun.sunsetUtc,           GalacticPalette.civilTwilight),
            (sun.civilDuskUtc,        GalacticPalette.nauticalTwilight),
            (sun.nauticalDuskUtc,     GalacticPalette.astronomicalTwilight),
            (sun.astronomicalDuskUtc, GalacticPalette.astronomicalDark),
        ]

        let dayStart = startOfLocalDay()
        let dayEnd = dayStart.addingTimeInterval(86400)
        let dayLength: TimeInterval = 86400

        // Starting color is whatever phase contains "dayStart" — assume astronomical dark
        // unless we determine otherwise from event ordering.
        var current = GalacticPalette.astronomicalDark
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
