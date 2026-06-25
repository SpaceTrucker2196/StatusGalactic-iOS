import SwiftUI

struct BriefDetailView: View {
    let brief: Brief
    let fetchedAt: Date
    let isStale: Bool

    @Environment(ClientConfig.self) private var config
    @State private var editMode: EditMode = .inactive

    init(brief: Brief, fetchedAt: Date, isStale: Bool = false) {
        self.brief = brief
        self.fetchedAt = fetchedAt
        self.isStale = isStale
    }

    var body: some View {
        Group {
            if editMode.isEditing {
                managementList
            } else {
                listBody
            }
        }
        .opacity(isStale ? 0.55 : 1)
        .grayscale(isStale ? 0.85 : 0)
        .animation(.easeInOut(duration: 0.4), value: isStale)
        .environment(\.editMode, $editMode)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation { editMode = editMode.isEditing ? .inactive : .active }
                } label: {
                    Text(editMode.isEditing ? "Done" : "Manage")
                        .font(.firaCode(.caption, weight: .semibold))
                }
                .accessibilityLabel(editMode.isEditing
                                    ? "Stop managing brief sections"
                                    : "Manage brief sections")
            }
        }
        .overlay(alignment: .top) {
            if isStale {
                staleBanner
            } else if isOfflineLike {
                offlineBanner
            }
        }
    }

    /// The pure-compute fields (planets, sun, moon, ephemeris) always
    /// populate, so we judge "offline" by whether every network-sourced
    /// field came back empty.
    private var isOfflineLike: Bool {
        brief.earth == nil &&
        brief.space == nil &&
        brief.weatherAlerts.isEmpty &&
        brief.activeRegions.isEmpty &&
        brief.launches.isEmpty &&
        brief.crewed.isEmpty &&
        brief.earthquakes.isEmpty
    }

    private var offlineBanner: some View {
        HStack(spacing: 6) {
            Image(systemName: "wifi.exclamationmark")
            Text("No data — check your network")
                .font(.firaCode(.caption2, weight: .semibold))
        }
        .foregroundStyle(GalacticPalette.peach)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial, in: Capsule())
        .padding(.top, 6)
    }

    private var staleBanner: some View {
        HStack(spacing: 6) {
            ProgressView()
                .controlSize(.small)
                .tint(.secondary)
            Text("Showing cached data · refreshing")
                .font(.firaCode(.caption2, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial, in: Capsule())
        .padding(.top, 6)
    }

    /// "Manage sections" list shown while EditMode is .active. Every
    /// known section is listed regardless of whether it currently has
    /// content — this is the only way to unhide one that the user
    /// previously dismissed, and the only way to reorder a section
    /// whose data isn't loaded right now.
    private var managementList: some View {
        List {
            Section {
                ForEach(config.briefSectionOrder) { kind in
                    SectionManagementRow(
                        kind: kind,
                        isHidden: config.hiddenBriefSections.contains(kind),
                        hasContent: hasContent(for: kind),
                        toggle: { toggleHidden(kind) }
                    )
                }
                .onMove { source, destination in
                    config.briefSectionOrder = BriefSection.moveInFullOrder(
                        order: config.briefSectionOrder,
                        visible: config.briefSectionOrder,
                        from: source,
                        to: destination
                    )
                }
            } header: {
                Text("Manage sections").phosphorHeader()
            } footer: {
                Text("Drag to reorder · tap the eye to hide or unhide. Hidden sections stay in the order so they reappear in the same place.")
                    .font(.firaCode(.caption2))
            }

            Section {
                Button(role: .destructive) {
                    config.briefSectionOrder = BriefSection.defaultOrder
                    config.hiddenBriefSections = []
                } label: {
                    HStack {
                        Image(systemName: "arrow.uturn.backward")
                        Text("Reset to defaults")
                            .font(.firaCode(.callout, weight: .semibold))
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(briefBackground.ignoresSafeArea())
    }

    private func toggleHidden(_ kind: BriefSection) {
        var next = config.hiddenBriefSections
        if next.contains(kind) {
            next.remove(kind)
        } else {
            next.insert(kind)
        }
        config.hiddenBriefSections = next
    }

    private var listBody: some View {
        List {
            // POTA, SOTA, DX cluster, and nearby repeaters live in the
            // RF tab. See RFView.rfBriefSections.
            //
            // Section ordering is driven by config.briefSectionOrder so
            // a user can drag rows around in Reorder mode. We iterate
            // only over sections that actually have content — SwiftUI's
            // SectionAccumulator crashes if a ForEach iteration in a
            // List produces zero Sections (see the formIndex(after:)
            // trap we hit while developing this). The full persisted
            // order is preserved across data states by translating the
            // visible-index move back into the underlying order.
            ForEach(visibleSections) { kind in
                section(for: kind)
            }
            .onMove(perform: moveVisibleSections)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(briefBackground.ignoresSafeArea())
    }

    /// Sections in the user's persisted order, filtered to only those
    /// that would actually render content for the current brief AND
    /// haven't been hidden via the manage-sections list.
    private var visibleSections: [BriefSection] {
        BriefSection.visible(
            in: config.briefSectionOrder,
            hidden: config.hiddenBriefSections,
            hasContent: hasContent(for:)
        )
    }

    /// Mirrors the `if let …` / `!isEmpty` guards used by each section's
    /// @ViewBuilder. Keep this in sync when adding sections or guards.
    private func hasContent(for kind: BriefSection) -> Bool {
        switch kind {
        case .weatherAlerts:    return !brief.weatherAlerts.isEmpty
        case .animatedSun:      return true
        case .stormScale:       return true
        case .sun:              return brief.sun != nil
        case .locationHeader:   return true
        case .earthWeather:     return (brief.earth?.periods.first) != nil
        case .riverStage:       return brief.river != nil
        case .marineWeather:
            return (brief.marine?.periods.isEmpty == false)
        case .tides:            return brief.tides != nil
        case .spaceWeather:     return brief.space != nil
        case .sunImagery:       return true
        case .auroraForecast:   return true
        case .moon:             return brief.moon != nil
        case .planets:          return !brief.planets.isEmpty
        case .crewedLaunches:   return !brief.crewedLaunches.isEmpty
        case .launches:         return !brief.launches.isEmpty
        case .crewed:           return !brief.crewed.isEmpty
        case .constellations:   return !brief.constellations.isEmpty
        case .apod:             return brief.apod != nil
        case .mars:             return brief.mars != nil
        case .neos:             return !brief.neos.isEmpty
        case .interstellar:     return !brief.interstellar.isEmpty
        case .solarSeismic:
            return !brief.earthquakes.isEmpty
                && brief.seismicSolarCorrelation != nil
        case .earthquakes:      return !brief.earthquakes.isEmpty
        case .siderealFooter:   return true
        case .errors:           return !brief.errors.isEmpty
        }
    }

    /// Persists a visible-list reorder back into the full order. The
    /// pure transformation lives on `BriefSection` so it can be unit
    /// tested without a SwiftUI view.
    private func moveVisibleSections(from source: IndexSet, to destination: Int) {
        config.briefSectionOrder = BriefSection.moveInFullOrder(
            order: config.briefSectionOrder,
            visible: visibleSections,
            from: source,
            to: destination
        )
    }

    // MARK: - Section dispatch

    @ViewBuilder
    private func section(for kind: BriefSection) -> some View {
        switch kind {
        case .weatherAlerts:    weatherAlertsSection
        case .animatedSun:      animatedSunSection
        case .stormScale:       stormScaleSection
        case .sun:              sunSection
        case .locationHeader:   locationHeaderSection
        case .earthWeather:     earthWeatherSection
        case .riverStage:       riverStageSection
        case .marineWeather:    marineWeatherSection
        case .tides:            tidesSection
        case .spaceWeather:     spaceWeatherSection
        case .sunImagery:       sunImagerySection
        case .auroraForecast:   auroraForecastSection
        case .moon:             moonSection
        case .planets:          planetsSection
        case .crewedLaunches:   crewedLaunchesSection
        case .launches:         launchesSection
        case .crewed:           crewedSection
        case .constellations:   constellationsSection
        case .apod:             apodSection
        case .mars:             marsSection
        case .neos:             neosSection
        case .interstellar:     interstellarSection
        case .solarSeismic:     solarSeismicSection
        case .earthquakes:      earthquakesSection
        case .siderealFooter:   siderealFooterSection
        case .errors:           errorsSection
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var weatherAlertsSection: some View {
        if !brief.weatherAlerts.isEmpty {
            Section {
                ForEach(brief.weatherAlerts) { alert in
                    WeatherAlertCard(alert: alert)
                        .padding(.vertical, 4)
                }
            } header: {
                Text("Active Alerts").phosphorHeader()
            } footer: {
                Text("NWS · CAP feed for your coordinates.")
                    .font(.firaCode(.caption2))
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
        }
    }

    private var animatedSunSection: some View {
        Section {
            AnimatedSunPanel()
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
    }

    private var stormScaleSection: some View {
        Section {
            StormScaleRow(brief: brief)
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 4, trailing: 16))
    }

    @ViewBuilder
    private var sunSection: some View {
        if let sun = brief.sun {
            PhosphorSection("Sun") {
                SunStrip(sun: sun, now: fetchedAt)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                SunSectionView(sun: sun)
            }
        }
    }

    private var locationHeaderSection: some View {
        Section {
            LocationHeader(brief: brief, fetchedAt: fetchedAt)
        }
        .listRowBackground(Color.clear)
    }

    @ViewBuilder
    private var earthWeatherSection: some View {
        if let earth = brief.earth, let summary = earth.periods.first {
            PhosphorSection("Earth Weather") {
                NavigationLink {
                    WeatherAlmanacView(earth: earth, timezoneName: brief.timezone)
                } label: {
                    WeatherSummaryView(period: summary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var riverStageSection: some View {
        if let river = brief.river {
            PhosphorSection("River Stage") {
                NavigationLink {
                    RiverStageAlmanacView(
                        gauge: river,
                        viewerLat: brief.lat,
                        viewerLng: brief.lng
                    )
                } label: {
                    RiverGaugeCard(gauge: river)
                        .padding(.vertical, 4)
                }
            }
        }
    }

    @ViewBuilder
    private var marineWeatherSection: some View {
        if let marine = brief.marine, !marine.periods.isEmpty {
            PhosphorSection("Marine Weather \(marine.zoneId)") {
                ForEach(marine.periods) { period in
                    WeatherPeriodRow(period: period, isMarine: true)
                }
            }
        }
    }

    @ViewBuilder
    private var tidesSection: some View {
        if let tides = brief.tides {
            PhosphorSection("Tides") {
                TidesCard(tides: tides, timezoneName: brief.timezone)
                    .padding(.vertical, 4)
            }
        }
    }

    @ViewBuilder
    private var spaceWeatherSection: some View {
        if let space = brief.space {
            PhosphorSection("Space Weather") {
                NavigationLink {
                    SolarAlmanacView(brief: brief)
                } label: {
                    SpaceWeatherView(space: space)
                }
            }
        }
    }

    private var sunImagerySection: some View {
        Section {
            SunImageryView()
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                .listRowBackground(Color.clear)
        } header: {
            Text("Sun Imagery").phosphorHeader()
        } footer: {
            Text("Latest frames from NASA SDO, NOAA SWPC GOES SUVI, and SOHO LASCO. Tap any image to zoom.")
        }
    }

    private var auroraForecastSection: some View {
        Section {
            AuroraImageryView()
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                .listRowBackground(Color.clear)
        } header: {
            Text("Aurora Forecast").phosphorHeader()
        } footer: {
            Text("NOAA SWPC OVATION 30-min forecast, both hemispheres.")
        }
    }

    @ViewBuilder
    private var moonSection: some View {
        if let moon = brief.moon {
            PhosphorSection("Moon") {
                MoonImageHero(moon: moon)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .listRowBackground(Color.clear)
                MoonSectionView(moon: moon)
            }
        }
    }

    @ViewBuilder
    private var planetsSection: some View {
        if !brief.planets.isEmpty {
            PhosphorSection("Planetary Positions") {
                ForEach(brief.planets) { planet in
                    PlanetRow(planet: planet, timezone: brief.timezone)
                }
            }
        }
    }

    @ViewBuilder
    private var crewedLaunchesSection: some View {
        if !brief.crewedLaunches.isEmpty {
            Section {
                ForEach(brief.crewedLaunches) { launch in
                    CrewedLaunchRow(launch: launch)
                }
            } header: {
                Text("Upcoming Crewed Launches").phosphorHeader()
            } footer: {
                Text("Human-spaceflight missions only · Launch Library 2.")
                    .font(.firaCode(.caption2))
            }
        }
    }

    @ViewBuilder
    private var launchesSection: some View {
        if !brief.launches.isEmpty {
            PhosphorSection("Upcoming Launches") {
                ForEach(brief.launches) { launch in
                    LaunchRow(launch: launch)
                }
            }
        }
    }

    @ViewBuilder
    private var crewedSection: some View {
        if !brief.crewed.isEmpty {
            Section {
                ForEach(brief.crewed) { obj in
                    ISSCard(iss: obj, observerLat: brief.lat, observerLng: brief.lng)
                        .padding(.vertical, 4)
                }
            } header: {
                Text("International Space Station").phosphorHeader()
            } footer: {
                Text("Live position from wheretheiss.at.")
                    .font(.firaCode(.caption2))
            }
        }
    }

    @ViewBuilder
    private var constellationsSection: some View {
        if !brief.constellations.isEmpty {
            Section {
                ForEach(brief.constellations) { c in
                    ConstellationRow(summary: c)
                        .padding(.vertical, 2)
                }
            } header: {
                Text("Satellite Constellations").phosphorHeader()
            } footer: {
                Text("Object counts from Celestrak GP element sets.")
                    .font(.firaCode(.caption2))
            }
        }
    }

    @ViewBuilder
    private var apodSection: some View {
        if let apod = brief.apod {
            PhosphorSection("Astronomy Picture of the Day") {
                APODCard(apod: apod)
                    .padding(.vertical, 4)
            }
        }
    }

    @ViewBuilder
    private var marsSection: some View {
        if let mars = brief.mars {
            Section {
                NavigationLink {
                    MarsAlmanacView(mars: mars, when: brief.when)
                } label: {
                    MarsWeatherCard(mars: mars)
                        .padding(.vertical, 4)
                }
            } header: {
                Text("Mars Weather").phosphorHeader()
            } footer: {
                Text("Perseverance MEDA + Curiosity REMS via mars.nasa.gov; freshest source wins.")
                    .font(.firaCode(.caption2))
            }
        }
    }

    @ViewBuilder
    private var neosSection: some View {
        if !brief.neos.isEmpty {
            Section {
                ForEach(brief.neos) { neo in
                    NEORow(neo: neo)
                }
            } header: {
                Text("Near-Earth Objects").phosphorHeader()
            } footer: {
                Text("Close approaches in the next week · NASA NEO.")
                    .font(.firaCode(.caption2))
            }
        }
    }

    @ViewBuilder
    private var interstellarSection: some View {
        if !brief.interstellar.isEmpty {
            Section {
                ForEach(brief.interstellar) { obj in
                    InterstellarRow(obj: obj)
                }
            } header: {
                Text("Interstellar Visitors").phosphorHeader()
            } footer: {
                Text("Confirmed hyperbolic trajectory · curated.")
                    .font(.firaCode(.caption2))
            }
        }
    }

    @ViewBuilder
    private var solarSeismicSection: some View {
        if !brief.earthquakes.isEmpty, brief.seismicSolarCorrelation != nil {
            Section {
                SeismicSolarCorrelationChart(
                    data: brief.seismicSolarCorrelation
                )
            } header: {
                Text("Solar ↔ Seismic").phosphorHeader()
            } footer: {
                Text("Independently scaled — world M4.5+ quakes (USGS) vs Earth-directed DONKI flares (±45° of central meridian) over the last 90 days. Bars colored by the day's strongest quake.")
                    .font(.firaCode(.caption2))
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 4, leading: 16,
                                      bottom: 4, trailing: 16))
        }
    }

    @ViewBuilder
    private var earthquakesSection: some View {
        if !brief.earthquakes.isEmpty {
            Section {
                EarthquakeTimelineChart(quakes: brief.earthquakes)
                ForEach(brief.earthquakes) { q in
                    NavigationLink {
                        EarthquakeDetailView(
                            quake: q,
                            allQuakes: brief.earthquakes,
                            correlation: brief.seismicSolarCorrelation
                        )
                    } label: {
                        EarthquakeRow(quake: q)
                    }
                }
            } header: {
                Text("Recent Earthquakes").phosphorHeader()
            } footer: {
                Text("USGS · global significant + nearby past 7 days.")
                    .font(.firaCode(.caption2))
            }
        }
    }

    private var siderealFooterSection: some View {
        Section {
            SiderealFooter(
                when: brief.when,
                longitudeEastDeg: brief.lng,
                magnetic: brief.magneticDeclination
            )
                .padding(.vertical, 4)
        }
        .listRowBackground(GalacticPalette.deepPurple.opacity(0.35))
    }

    @ViewBuilder
    private var errorsSection: some View {
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
                Text("Source errors").phosphorHeader()
            }
        }
    }

    @ViewBuilder
    private var briefBackground: some View {
        if config.useAPODBackground,
           let apod = brief.apod,
           let url = apod.displayImageURL {
            ZStack {
                Color.black
                CachedAsyncImage(
                    url: url,
                    placeholder: { Color.black },
                    failure: { Color.black }
                )
                .aspectRatio(contentMode: .fill)
                .opacity(0.35)
                .blur(radius: 6)
                GalacticPalette.cosmicSky.opacity(0.65)
            }
        } else {
            GalacticPalette.cosmicSky
        }
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
    let timezone: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
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
            ephemerisLine
        }
    }

    @ViewBuilder
    private var ephemerisLine: some View {
        if let state = planet.circumpolarState {
            Text(state == "always_up" ? "Always above horizon"
                                      : "Below horizon all day")
                .font(.firaCode(.caption2))
                .foregroundStyle(.secondary)
        } else if planet.riseAt != nil || planet.setAt != nil || planet.altitudeDeg != nil {
            HStack(spacing: 10) {
                if let alt = planet.altitudeDeg {
                    let glyph = alt >= 0 ? "↑" : "↓"
                    Text(String(format: "%@ %.0f°", glyph, abs(alt)))
                        .font(.firaCode(.caption2, weight: .semibold))
                        .foregroundStyle(alt >= 0
                            ? GalacticPalette.neonCyan
                            : GalacticPalette.peach.opacity(0.7))
                }
                if let rise = planet.riseAt {
                    Text("R \(rise.formatted(.dateTime.hour().minute().timeZone()))")
                        .font(.firaCode(.caption2))
                        .foregroundStyle(.secondary)
                }
                if let set = planet.setAt {
                    Text("S \(set.formatted(.dateTime.hour().minute().timeZone()))")
                        .font(.firaCode(.caption2))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .environment(\.timeZone, TimeZone(identifier: timezone) ?? .current)
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

/// One row in the "Manage sections" list. Shows the section's display
/// name, a "no data" hint when the section is currently empty, and an
/// eye toggle that flips the hidden state.
private struct SectionManagementRow: View {
    let kind: BriefSection
    let isHidden: Bool
    let hasContent: Bool
    let toggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(kind.displayName)
                    .font(.firaCode(.subheadline, weight: .semibold))
                    .foregroundStyle(isHidden ? Color.secondary : GalacticPalette.neonCyan)
                if !hasContent {
                    Text("No data this load")
                        .font(.firaCode(.caption2))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button(action: toggle) {
                Image(systemName: isHidden ? "eye.slash.fill" : "eye.fill")
                    .foregroundStyle(isHidden ? Color.secondary : GalacticPalette.mint)
                    .neonGlow(isHidden ? Color.clear : GalacticPalette.mint,
                              intensity: isHidden ? 0 : 4)
                    .font(.body)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(isHidden
                                ? "Show \(kind.displayName)"
                                : "Hide \(kind.displayName)")
        }
        .padding(.vertical, 2)
    }
}
