import SwiftUI

struct BriefDetailView: View {
    let brief: Brief
    let fetchedAt: Date

    var body: some View {
        List {
            Section {
                LocationHeader(brief: brief, fetchedAt: fetchedAt)
            }
            if let earth = brief.earth, !earth.periods.isEmpty {
                Section("Earth Weather") {
                    ForEach(earth.periods) { period in
                        WeatherPeriodRow(period: period)
                    }
                }
            }
            if let marine = brief.marine, !marine.periods.isEmpty {
                Section("Marine Weather \(marine.zoneId)") {
                    ForEach(marine.periods) { period in
                        WeatherPeriodRow(period: period, isMarine: true)
                    }
                }
            }
            if let space = brief.space {
                Section("Space Weather") {
                    SpaceWeatherView(space: space)
                }
            }
            Section {
                SunImageryView()
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .listRowBackground(Color.clear)
            } header: {
                Text("Sun Imagery")
            } footer: {
                Text("Latest frames from NASA SDO, NOAA SWPC GOES SUVI, and SOHO LASCO. Tap any image to zoom.")
            }
            if let sun = brief.sun {
                Section("Sun") {
                    SunStrip(sun: sun, now: fetchedAt)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    SunSectionView(sun: sun)
                }
            }
            if let moon = brief.moon {
                Section("Moon") {
                    MoonSectionView(moon: moon)
                }
            }
            if !brief.planets.isEmpty {
                Section("Planetary Positions") {
                    ForEach(brief.planets) { planet in
                        PlanetRow(planet: planet)
                    }
                }
            }
            if !brief.launches.isEmpty {
                Section("Upcoming Launches") {
                    ForEach(brief.launches) { launch in
                        LaunchRow(launch: launch)
                    }
                }
            }
            if !brief.errors.isEmpty {
                Section {
                    ForEach(brief.errors.sorted(by: { $0.key < $1.key }), id: \.key) { key, msg in
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(key).font(.subheadline.weight(.medium))
                                Text(msg).font(.caption).foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                        }
                    }
                } header: {
                    Text("Source errors")
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

private struct LocationHeader: View {
    let brief: Brief
    let fetchedAt: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(brief.locationName ?? "\(String(format: "%.4f", brief.lat)), \(String(format: "%.4f", brief.lng))")
                    .font(.title3.weight(.semibold))
                Spacer()
                Button {
                    MapsLauncher.show(
                        at: .init(latitude: brief.lat, longitude: brief.lng),
                        name: brief.locationName ?? "Brief location"
                    )
                } label: {
                    Image(systemName: "map.fill")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .accessibilityLabel("Open in Maps")
            }
            Text("\(String(format: "%.4f", brief.lat)), \(String(format: "%.4f", brief.lng))")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                if brief.timezone != "UTC" {
                    Label(brief.timezone, systemImage: "clock")
                        .font(.caption2)
                }
                Spacer()
                Text("Updated \(fetchedAt, style: .relative) ago")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct WeatherPeriodRow: View {
    let period: WeatherPeriod
    var isMarine: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(period.name)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                if let temp = period.temperature {
                    Text("\(temp)°\(period.temperatureUnit)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(period.isDaytime ? .orange : .blue)
                }
            }
            Text(period.shortForecast)
                .font(.subheadline)
                .foregroundStyle(.primary)
            if let wind = period.wind, !isMarine {
                Label(wind, systemImage: "wind")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

private struct SpaceWeatherView: View {
    let space: SpaceWeather

    var body: some View {
        if let flux = space.solarFlux {
            LabeledContent("Solar flux (10.7 cm)") {
                Text("\(Int(flux))").monospacedDigit()
            }
        }
        if let kp = space.kpIndex {
            LabeledContent("Kp index") {
                HStack(spacing: 4) {
                    Text(String(format: "%.1f", kp)).monospacedDigit()
                    if let status = space.kpStatus {
                        Text("(\(status))").foregroundStyle(.secondary)
                    }
                }
            }
        }
        if let hf = space.hfSummary {
            LabeledContent("HF") {
                Text(hf).multilineTextAlignment(.trailing).foregroundStyle(.secondary)
            }
        }
        LabeledContent("Aurora") {
            Text(space.auroraLikely ? "Likely at mid-latitudes" : "Unlikely")
                .foregroundStyle(space.auroraLikely ? .green : .secondary)
        }
    }
}

private struct SunSectionView: View {
    let sun: SolarEvents

    var body: some View {
        if let sunrise = sun.sunriseUtc {
            LabeledContent("Sunrise") { Text(local(sunrise)) }
        }
        if let sunset = sun.sunsetUtc {
            LabeledContent("Sunset") { Text(local(sunset)) }
        }
        if let start = sun.goldenMorningStartUtc, let end = sun.goldenMorningEndUtc {
            LabeledContent("Golden hour (morning)") {
                Text("\(local(start)) – \(local(end))")
            }
        }
        if let start = sun.goldenEveningStartUtc, let end = sun.goldenEveningEndUtc {
            LabeledContent("Golden hour (evening)") {
                Text("\(local(start)) – \(local(end))")
            }
        }
        TwilightTriple(
            label: "Civil",
            dawn: sun.civilDawnUtc,
            dusk: sun.civilDuskUtc,
            tz: sun.timezone
        )
        TwilightTriple(
            label: "Nautical",
            dawn: sun.nauticalDawnUtc,
            dusk: sun.nauticalDuskUtc,
            tz: sun.timezone
        )
        TwilightTriple(
            label: "Astronomical",
            dawn: sun.astronomicalDawnUtc,
            dusk: sun.astronomicalDuskUtc,
            tz: sun.timezone
        )
    }

    private func local(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeZone = TimeZone(identifier: sun.timezone) ?? .current
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }
}

private struct TwilightTriple: View {
    let label: String
    let dawn: Date?
    let dusk: Date?
    let tz: String

    var body: some View {
        if dawn != nil || dusk != nil {
            LabeledContent("\(label) twilight") {
                Text("\(fmt(dawn)) / \(fmt(dusk))")
            }
        }
    }

    private func fmt(_ date: Date?) -> String {
        guard let date else { return "n/a" }
        let f = DateFormatter()
        f.timeZone = TimeZone(identifier: tz) ?? .current
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }
}

private struct MoonSectionView: View {
    let moon: Moon

    var body: some View {
        LabeledContent("Phase") { Text(moon.phaseName) }
        LabeledContent("Illumination") {
            Text("\(Int(moon.illuminationPct.rounded()))%")
        }
        LabeledContent("Phase angle") {
            Text(String(format: "%.1f°", moon.phaseAngleDeg))
        }
    }
}

private struct PlanetRow: View {
    let planet: Planet

    var body: some View {
        HStack {
            Text(planet.body).font(.subheadline.weight(.semibold))
            Spacer()
            Text(String(format: "%.2f° %@", planet.degree, planet.sign))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }
}

private struct LaunchRow: View {
    let launch: Launch

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(launch.name)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
            HStack {
                Text(launch.whenUtc, style: .date)
                Text(launch.whenUtc, style: .time)
                if let status = launch.status {
                    Spacer()
                    Text(status)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.secondary.opacity(0.15)))
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            if let provider = launch.provider {
                Text(provider).font(.caption2).foregroundStyle(.secondary)
            }
        }
    }
}
