import SwiftUI

struct BriefDetailView: View {
    let brief: Brief
    let fetchedAt: Date

    var body: some View {
        List {
            Section {
                LocationHeader(brief: brief, fetchedAt: fetchedAt)
            }
            .listRowBackground(Color.clear)
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
            Section {
                AuroraImageryView()
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .listRowBackground(Color.clear)
            } header: {
                Text("Aurora Forecast")
            } footer: {
                Text("NOAA SWPC OVATION 30-min forecast, both hemispheres.")
            }
            Section {
                DeepSkyImageryView()
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .listRowBackground(Color.clear)
            } header: {
                Text("Deep Sky")
            } footer: {
                Text("Curated stills from Hubble + JWST press releases. New APOD picks may appear under Astronomy Picture of the Day below.")
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
            if let iss = brief.iss {
                Section {
                    ISSCard(iss: iss, observerLat: brief.lat, observerLng: brief.lng)
                        .padding(.vertical, 4)
                } header: {
                    Text("International Space Station")
                } footer: {
                    Text("Live position from wheretheiss.at.")
                        .font(.firaCode(.caption2))
                }
            }
            if let apod = brief.apod {
                Section("Astronomy Picture of the Day") {
                    APODCard(apod: apod)
                        .padding(.vertical, 4)
                }
            }
            if let mars = brief.mars {
                Section {
                    MarsWeatherCard(mars: mars)
                        .padding(.vertical, 4)
                } header: {
                    Text("Mars Weather")
                } footer: {
                    Text("Curiosity REMS via MAAS2 (community proxy).")
                        .font(.firaCode(.caption2))
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
        .scrollContentBackground(.hidden)
        .background(GalacticPalette.cosmicSky.ignoresSafeArea())
    }
}

private struct LocationHeader: View {
    let brief: Brief
    let fetchedAt: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(brief.locationName ?? "\(String(format: "%.4f", brief.lat)), \(String(format: "%.4f", brief.lng))")
                    .font(.firaCode(.title3, weight: .bold))
                    .foregroundStyle(GalacticPalette.neonCyan)
                    .neonGlow(GalacticPalette.neonCyan, intensity: 8)
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
                .font(.firaCode(.caption))
                .foregroundStyle(GalacticPalette.peach.opacity(0.7))
            HStack {
                if brief.timezone != "UTC" {
                    Label(brief.timezone, systemImage: "clock")
                        .font(.firaCode(.caption2))
                        .foregroundStyle(GalacticPalette.hotPink.opacity(0.85))
                }
                Spacer()
                Text("Updated \(fetchedAt, style: .relative) ago")
                    .font(.firaCode(.caption2))
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
            HStack(spacing: 8) {
                Image(systemName: GalacticSymbols.weatherSymbol(
                    for: period.shortForecast,
                    isDaytime: period.isDaytime
                ))
                .font(.title3)
                .foregroundStyle(period.isDaytime
                                 ? GalacticPalette.sun
                                 : GalacticPalette.electricBlue)
                .symbolRenderingMode(.hierarchical)

                Text(period.name)
                    .font(.firaCode(.subheadline, weight: .semibold))
                Spacer()
                if let temp = period.temperature {
                    Text("\(temp)°\(period.temperatureUnit)")
                        .font(.firaCode(.subheadline, weight: .semibold))
                        .foregroundStyle(GalacticPalette.temperature(temp))
                        .neonGlow(GalacticPalette.temperature(temp), intensity: 4)
                }
            }
            Text(period.shortForecast)
                .font(.firaCode(.subheadline))
                .foregroundStyle(.primary)
            if let wind = period.wind, !isMarine {
                Label(wind, systemImage: "wind")
                    .font(.firaCode(.caption))
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
            LabeledContent {
                Text("\(Int(flux))")
                    .font(.firaCode(.body, weight: .semibold))
                    .foregroundStyle(GalacticPalette.solarFlux(flux))
                    .neonGlow(GalacticPalette.solarFlux(flux))
            } label: {
                Label("Solar flux", systemImage: GalacticSymbols.solarFlux)
                    .font(.firaCode(.subheadline))
            }
        }
        if let kp = space.kpIndex {
            LabeledContent {
                HStack(spacing: 4) {
                    Text(String(format: "%.1f", kp))
                        .font(.firaCode(.body, weight: .semibold))
                        .foregroundStyle(GalacticPalette.kp(kp))
                        .neonGlow(GalacticPalette.kp(kp))
                    if let status = space.kpStatus {
                        Text("(\(status))")
                            .font(.firaCode(.caption))
                            .foregroundStyle(.secondary)
                    }
                }
            } label: {
                Label("Kp index", systemImage: GalacticSymbols.kpIndex)
                    .font(.firaCode(.subheadline))
            }
        }
        if let hf = space.hfSummary {
            LabeledContent("HF") {
                Text(hf)
                    .font(.firaCode(.caption))
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(.secondary)
            }
        }
        LabeledContent {
            Text(space.auroraLikely ? "Likely at mid-latitudes" : "Unlikely")
                .font(.firaCode(.subheadline))
                .foregroundStyle(space.auroraLikely
                                 ? GalacticPalette.mint
                                 : Color.secondary)
                .neonGlow(GalacticPalette.mint, intensity: space.auroraLikely ? 5 : 0)
        } label: {
            Label("Aurora", systemImage: GalacticSymbols.aurora)
                .font(.firaCode(.subheadline))
        }
    }
}

private struct SunSectionView: View {
    let sun: SolarEvents

    var body: some View {
        if let sunrise = sun.sunriseUtc {
            sunRow("Sunrise", icon: GalacticSymbols.sunrise, time: sunrise, color: GalacticPalette.sun)
        }
        if let sunset = sun.sunsetUtc {
            sunRow("Sunset", icon: GalacticSymbols.sunset, time: sunset, color: GalacticPalette.sunsetOrange)
        }
        if let start = sun.goldenMorningStartUtc, let end = sun.goldenMorningEndUtc {
            sunRange("Golden hour (morning)", icon: GalacticSymbols.goldenHour, start: start, end: end, color: GalacticPalette.peach)
        }
        if let start = sun.goldenEveningStartUtc, let end = sun.goldenEveningEndUtc {
            sunRange("Golden hour (evening)", icon: GalacticSymbols.goldenHour, start: start, end: end, color: GalacticPalette.hotPink)
        }
        TwilightTriple(label: "Civil", dawn: sun.civilDawnUtc, dusk: sun.civilDuskUtc, tz: sun.timezone, color: GalacticPalette.dustyRose)
        TwilightTriple(label: "Nautical", dawn: sun.nauticalDawnUtc, dusk: sun.nauticalDuskUtc, tz: sun.timezone, color: GalacticPalette.electricBlue)
        TwilightTriple(label: "Astronomical", dawn: sun.astronomicalDawnUtc, dusk: sun.astronomicalDuskUtc, tz: sun.timezone, color: GalacticPalette.neonPurple)
    }

    private func sunRow(_ label: String, icon: String, time: Date, color: Color) -> some View {
        LabeledContent {
            Text(local(time))
                .font(.firaCode(.subheadline, weight: .semibold))
                .foregroundStyle(color)
                .neonGlow(color, intensity: 4)
        } label: {
            Label(label, systemImage: icon)
                .font(.firaCode(.subheadline))
        }
    }

    private func sunRange(_ label: String, icon: String, start: Date, end: Date, color: Color) -> some View {
        LabeledContent {
            Text("\(local(start)) – \(local(end))")
                .font(.firaCode(.caption))
                .foregroundStyle(color)
        } label: {
            Label(label, systemImage: icon)
                .font(.firaCode(.subheadline))
        }
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
    let color: Color

    var body: some View {
        if dawn != nil || dusk != nil {
            LabeledContent {
                Text("\(fmt(dawn)) / \(fmt(dusk))")
                    .font(.firaCode(.caption, weight: .medium))
                    .foregroundStyle(color)
            } label: {
                Label("\(label) twilight", systemImage: GalacticSymbols.civilTwilight)
                    .font(.firaCode(.subheadline))
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
        LabeledContent {
            HStack(spacing: 6) {
                Image(systemName: GalacticSymbols.moonPhaseSymbol(for: moon.phaseName))
                    .foregroundStyle(GalacticPalette.moonIllumination(moon.illuminationPct))
                    .neonGlow(GalacticPalette.moonIllumination(moon.illuminationPct), intensity: 5)
                Text(moon.phaseName)
                    .font(.firaCode(.subheadline, weight: .semibold))
            }
        } label: {
            Text("Phase").font(.firaCode(.subheadline))
        }
        LabeledContent {
            Text("\(Int(moon.illuminationPct.rounded()))%")
                .font(.firaCode(.subheadline, weight: .semibold))
                .foregroundStyle(GalacticPalette.moon)
        } label: {
            Text("Illumination").font(.firaCode(.subheadline))
        }
        LabeledContent {
            Text(String(format: "%.1f°", moon.phaseAngleDeg))
                .font(.firaCode(.caption))
                .foregroundStyle(.secondary)
        } label: {
            Text("Phase angle").font(.firaCode(.subheadline))
        }
    }
}

private struct PlanetRow: View {
    let planet: Planet

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: GalacticSymbols.bodySymbol(for: planet.body))
                .font(.caption)
                .foregroundStyle(GalacticSymbols.bodyColor(for: planet.body))
                .neonGlow(GalacticSymbols.bodyColor(for: planet.body), intensity: 3)
            Text(planet.body)
                .font(.firaCode(.subheadline, weight: .semibold))
            Spacer()
            Text(String(format: "%.2f° %@", planet.degree, planet.sign))
                .font(.firaCode(.subheadline))
                .foregroundStyle(GalacticSymbols.bodyColor(for: planet.body).opacity(0.85))
        }
    }
}

private struct LaunchRow: View {
    let launch: Launch

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "paperplane.circle.fill")
                    .foregroundStyle(GalacticPalette.neonCyan)
                    .neonGlow(GalacticPalette.neonCyan, intensity: 3)
                Text(launch.name)
                    .font(.firaCode(.subheadline, weight: .semibold))
                    .lineLimit(2)
            }
            HStack {
                Text(launch.whenUtc, style: .date)
                Text(launch.whenUtc, style: .time)
                if let status = launch.status {
                    Spacer()
                    Text(status)
                        .font(.firaCode(.caption2))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule().fill(GalacticPalette.neonPurple.opacity(0.25))
                        )
                        .overlay(
                            Capsule().stroke(GalacticPalette.neonPurple, lineWidth: 0.5)
                        )
                        .foregroundStyle(GalacticPalette.neonCyan)
                }
            }
            .font(.firaCode(.caption))
            .foregroundStyle(.secondary)
            if let provider = launch.provider {
                Text(provider)
                    .font(.firaCode(.caption2))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
