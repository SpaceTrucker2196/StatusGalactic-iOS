import Foundation

/// Fans out to every data source in parallel and assembles a Brief locally.
/// Mirrors what the (now-retired) weathergalactic backend used to do.
struct BriefBuilder {
    let config: ClientConfig
    let session: URLSession

    init(config: ClientConfig, session: URLSession = .shared) {
        self.config = config
        self.session = session
    }

    /// Build a brief for the given coordinates. `call` is only used to populate
    /// `Brief.locationName`-like context; coordinate resolution should happen
    /// upstream via `APRSClient.locate`.
    func build(
        lat: Double,
        lng: Double,
        marineZone: String?,
        timezone: String?
    ) async -> Brief {
        let when = Date()
        let tz = timezone ?? TimeZone.current.identifier

        let nws = NWSClient(session: session, userAgent: config.userAgent)
        let swpc = SWPCClient(session: session, userAgent: config.userAgent)
        let launches = LaunchesClient(session: session, userAgent: config.userAgent)
        let marine = MarineClient(session: session, userAgent: config.userAgent)
        let apodClient = APODClient(
            session: session,
            userAgent: config.userAgent,
            apiKey: config.nasaAPIKey
        )
        let marsClient = MarsWeatherClient(session: session, userAgent: config.userAgent)
        let issClient = ISSClient(session: session, userAgent: config.userAgent)
        let repeaterClient = RepeaterBookClient(session: session, userAgent: config.userAgent)
        let tidesClient = TidesClient(session: session, userAgent: config.userAgent)
        let riverClient = RiverGaugeClient(session: session, userAgent: config.userAgent)
        let neoClient = NEOClient(
            session: session, userAgent: config.userAgent, apiKey: config.nasaAPIKey
        )
        let constellationsClient = ConstellationsClient(
            session: session, userAgent: config.userAgent
        )
        let quakeClient = EarthquakeClient(
            session: session, userAgent: config.userAgent
        )
        let activeRegionsClient = ActiveRegionsClient(
            session: session, userAgent: config.userAgent
        )
        let forecastClient = SpaceWeatherForecastClient(
            session: session, userAgent: config.userAgent
        )
        let solarWindClient = SolarWindClient(
            session: session, userAgent: config.userAgent
        )
        let wwvClient = WWVClient(
            session: session, userAgent: config.userAgent
        )
        let donkiClient = DONKIClient(
            session: session, userAgent: config.userAgent, apiKey: config.nasaAPIKey
        )
        let outlookClient = SolarOutlookClient(
            session: session, userAgent: config.userAgent
        )
        let goesClient = GOESParticleClient(
            session: session, userAgent: config.userAgent
        )
        let ionosondeClient = IonosondeClient(
            session: session, userAgent: config.userAgent
        )
        let ovationClient = OVATIONClient(
            session: session, userAgent: config.userAgent
        )
        let potaClient = POTAClient(
            session: session, userAgent: config.userAgent
        )
        let sotaClient = SOTAClient(
            session: session, userAgent: config.userAgent
        )
        let dxClient = DXClusterClient(
            session: session, userAgent: config.userAgent
        )
        let alertsClient = WeatherAlertsClient(
            session: session, userAgent: config.userAgent
        )
        let magClient = MagneticDeclinationClient(
            session: session, userAgent: config.userAgent
        )
        let solarCycleClient = SolarCycleClient(
            session: session, userAgent: config.userAgent
        )
        let correlationClient = SeismicSolarCorrelationClient(
            session: session,
            userAgent: config.userAgent,
            apiKey: config.nasaAPIKey
        )
        let priyomClient = PriyomClient(
            session: session, userAgent: config.userAgent
        )

        // 48-hour window: NWS periods are 12 hours each, so 4 covers today,
        // tonight, tomorrow, and tomorrow night. We render the first one as
        // the headline summary and keep the rest available in the model for
        // future expansion.
        async let earthTask: EarthWeather? = try? nws.fetchEarthWeather(lat: lat, lng: lng, periods: 4)
        async let spaceTask: SpaceWeather? = try? swpc.fetchSpaceWeather()
        async let launchTask: [Launch] = (try? await launches.fetchUpcomingLaunches()) ?? []
        async let crewedLaunchTask: [CrewedLaunch] = (try? await launches.fetchUpcomingCrewedLaunches()) ?? []
        async let apodTask: APOD? = try? apodClient.fetchToday()
        async let marsTask: MarsWeather? = try? marsClient.fetchLatest()
        async let crewedTask: [CrewedObject] = issClient.fetchAllCrewedObjects()
        async let tidesTask: Tides? = try? tidesClient.fetchNearestTides(lat: lat, lng: lng)
        async let riverTask: RiverGauge? = try? riverClient.fetchNearestGauge(lat: lat, lng: lng)
        async let neosTask: [NearEarthObject] = (try? await neoClient.fetchUpcoming()) ?? []
        async let constellationsTask: [ConstellationSummary] = constellationsClient.fetchAll()
        async let quakesTask: [Earthquake] = quakeClient.fetchRecent(
            viewerLat: lat, viewerLng: lng
        )
        async let activeRegionsTask: [ActiveRegion] = (try? await activeRegionsClient.fetchActive()) ?? []
        async let forecastTask: SpaceWeatherForecastClient.Result? = try? await forecastClient.fetch()
        async let solarWindTask: SolarWind? = solarWindClient.fetch()
        async let wwvTask: WWVBulletin? = try? await wwvClient.fetch()
        async let cmesTask: [CMEEvent] = (try? await donkiClient.fetchRecent()) ?? []
        async let outlookTask: [SolarOutlookDay] = (try? await outlookClient.fetch()) ?? []
        async let xRayTask: XRayState? = try? await goesClient.fetchXRay()
        async let protonTask: ProtonState? = try? await goesClient.fetchProton()
        async let ionosondesTask: [IonosondeStation] = (try? await ionosondeClient.fetchNearest(
            lat: lat, lng: lng
        )) ?? []
        async let auroraTask: AuroraForecast? = try? await ovationClient.fetch(lat: lat, lng: lng)
        async let potaTask: [POTASpot] = (try? await potaClient.fetchRecent(
            viewerLat: lat, viewerLng: lng
        )) ?? []
        async let sotaTask: [SOTASpot] = (try? await sotaClient.fetchRecent()) ?? []
        async let dxTask: [DXSpot] = (try? await dxClient.fetchRecent()) ?? []
        async let alertsTask: [WeatherAlert] = (try? await alertsClient.fetchActive(
            lat: lat, lng: lng
        )) ?? []
        async let magTask: MagneticDeclination? = magClient.fetch(lat: lat, lng: lng)
        async let solarCycleTask: [SolarCyclePoint] = (try? await solarCycleClient.fetchObserved()) ?? []
        async let correlationTask: SeismicSolarCorrelation? = await correlationClient.fetch()
        async let priyomTask: [PriyomBroadcast] = (try? await priyomClient.fetchUpcoming()) ?? []
        let n2yoKey = config.n2yoAPIKey
        async let passesTask: [ISSPass] = n2yoKey.isEmpty
            ? []
            : ((try? await issClient.fetchVisualPasses(
                lat: lat, lng: lng, apiKey: n2yoKey
              )) ?? [])

        var marineResult: MarineWeather?
        var errors: [String: String] = [:]
        if let zone = marineZone, !zone.isEmpty {
            do {
                marineResult = try await marine.fetchMarineForecast(zoneId: zone)
            } catch {
                errors["marine"] = (error as? LocalizedError)?.errorDescription
                    ?? error.localizedDescription
            }
        }

        let earth = await earthTask
        if earth == nil { errors["nws"] = "Earth weather unavailable" }

        // Repeaters need the city + state we just got from NWS.
        var repeaters: [Repeater] = []
        if let city = earth?.city, let state = earth?.state, !city.isEmpty, !state.isEmpty {
            repeaters = (try? await repeaterClient.fetchRepeaters(
                city: city,
                stateAbbreviation: state
            )) ?? []
        }

        let space = await spaceTask
        if space == nil { errors["swpc"] = "Space weather unavailable" }

        let launchList = await launchTask
        let crewedLaunchList = await crewedLaunchTask
        let apod = await apodTask
        let mars = await marsTask
        var crewed = await crewedTask
        let passes = await passesTask
        let tides = await tidesTask
        let river = await riverTask
        let neos = await neosTask
        let interstellar = InterstellarObjectCatalog.all
        let constellations = await constellationsTask
        if constellations.isEmpty { errors["constellations"] = "Celestrak unavailable" }
        let quakes = await quakesTask
        let activeRegions = await activeRegionsTask
        let forecast = await forecastTask
        let solarWind = await solarWindTask
        let wwv = await wwvTask
        let cmes = await cmesTask
        let outlook = await outlookTask
        let xRay = await xRayTask
        let proton = await protonTask
        let ionosondes = await ionosondesTask
        let aurora = await auroraTask
        let potaSpots = await potaTask
        let sotaSpots = await sotaTask
        let dxSpots = await dxTask
        let weatherAlerts = await alertsTask
        let magneticDeclination = await magTask
        let solarCycle = await solarCycleTask
        let seismicSolarCorrelation = await correlationTask
        let priyomBroadcasts = await priyomTask
        let bandConditions = BandConditions.evaluate(
            sfi: space?.solarFlux,
            kp: space?.kpIndex,
            rScale: xRay?.rScale,
            mufMHz: ionosondes.first?.mufMHz
        )
        // Visual passes are only meaningful for the ISS (N2YO endpoint we use
        // is ISS-specific). Attach to the ISS entry if present.
        if let issIdx = crewed.firstIndex(where: { $0.noradId == CrewedSpacecraftCatalog.iss.noradId }) {
            crewed[issIdx].passes = passes
        }
        if apod == nil { errors["apod"] = "APOD unavailable (NASA API)" }
        if mars == nil { errors["mars"] = "Mars weather unavailable (MAAS2)" }
        if crewed.isEmpty { errors["crewed"] = "No crewed-spacecraft positions available" }

        let sun = SunEvents.compute(
            when: when,
            latitude: lat,
            longitude: lng,
            timezoneName: tz
        )
        let moon = MoonPhase.compute(when: when)
        let planets = Planets.computeWithEphemeris(when: when, lat: lat, lng: lng)

        return Brief(
            when: when,
            lat: lat,
            lng: lng,
            timezone: tz,
            locationName: earth?.locationName,
            earth: earth,
            marine: marineResult,
            space: space,
            sun: sun,
            moon: moon,
            planets: planets,
            launches: launchList,
            crewedLaunches: crewedLaunchList,
            apod: apod,
            mars: mars,
            crewed: crewed,
            repeaters: repeaters,
            tides: tides,
            river: river,
            neos: neos,
            interstellar: interstellar,
            constellations: constellations,
            earthquakes: quakes,
            activeRegions: activeRegions,
            flareProbability: forecast?.flares,
            kpForecast: forecast?.kpDays ?? [],
            solarWind: solarWind,
            wwvBulletin: wwv,
            cmes: cmes,
            solarOutlook: outlook,
            xRay: xRay,
            proton: proton,
            ionosondes: ionosondes,
            aurora: aurora,
            bandConditions: bandConditions,
            potaSpots: potaSpots,
            sotaSpots: sotaSpots,
            dxSpots: dxSpots,
            solarCycle: solarCycle,
            weatherAlerts: weatherAlerts,
            magneticDeclination: magneticDeclination,
            priyomBroadcasts: priyomBroadcasts,
            seismicSolarCorrelation: seismicSolarCorrelation,
            errors: errors
        )
    }
}
