import SwiftUI

struct WatchBriefView: View {
    let brief: Brief
    let fetchedAt: Date

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                header
                if let earth = brief.earth, let period = earth.periods.first {
                    earthCard(period: period)
                }
                if let space = brief.space {
                    spaceCard(space: space)
                }
                if let sun = brief.sun {
                    sunCard(sun: sun)
                }
                if let moon = brief.moon {
                    moonCard(moon: moon)
                }
                Text("Updated \(fetchedAt, style: .relative) ago")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 4)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(brief.locationName ?? String(format: "%.2f, %.2f", brief.lat, brief.lng))
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .foregroundStyle(.secondary)
        }
    }

    private func earthCard(period: WeatherPeriod) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline) {
                if let temp = period.temperature {
                    Text("\(temp)°")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }
                Spacer()
                Text(period.name)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Text(period.shortForecast)
                .font(.caption2)
                .lineLimit(2)
                .foregroundStyle(.primary)
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 10).fill(.fill.secondary))
    }

    private func spaceCard(space: SpaceWeather) -> some View {
        HStack {
            if let kp = space.kpIndex {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Kp \(String(format: "%.1f", kp))")
                        .font(.caption.weight(.semibold))
                        .monospacedDigit()
                    if let status = space.kpStatus {
                        Text(status).font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
            if let flux = space.solarFlux {
                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(Int(flux))")
                        .font(.caption.weight(.semibold))
                        .monospacedDigit()
                    Text("flux").font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 10).fill(.fill.secondary))
    }

    private func sunCard(sun: SolarEvents) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            if let next = nextSunEvent(sun: sun, now: fetchedAt) {
                HStack {
                    Image(systemName: next.icon)
                    Text(next.label)
                        .font(.caption.weight(.semibold))
                    Spacer()
                    Text(next.date, style: .relative)
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            HStack {
                if let sunrise = sun.sunriseUtc {
                    Label(formatTime(sunrise, tz: sun.timezone), systemImage: "sunrise.fill")
                        .font(.caption2)
                }
                Spacer()
                if let sunset = sun.sunsetUtc {
                    Label(formatTime(sunset, tz: sun.timezone), systemImage: "sunset.fill")
                        .font(.caption2)
                }
            }
            .foregroundStyle(.secondary)
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 10).fill(.fill.secondary))
    }

    private func moonCard(moon: Moon) -> some View {
        HStack {
            Image(systemName: moonIcon(for: moon))
            Text("\(Int(moon.illuminationPct))% \(moon.phaseName)")
                .font(.caption.weight(.semibold))
                .lineLimit(1)
            Spacer()
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 10).fill(.fill.secondary))
    }

    // MARK: helpers

    private struct NextSunEvent {
        let label: String
        let date: Date
        let icon: String
    }

    private func nextSunEvent(sun: SolarEvents, now: Date) -> NextSunEvent? {
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

    private func formatTime(_ date: Date, tz: String) -> String {
        let f = DateFormatter()
        f.timeZone = TimeZone(identifier: tz) ?? .current
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
