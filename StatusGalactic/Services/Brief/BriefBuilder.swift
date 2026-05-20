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

        async let earthTask: EarthWeather? = try? nws.fetchEarthWeather(lat: lat, lng: lng)
        async let spaceTask: SpaceWeather? = try? swpc.fetchSpaceWeather()
        async let launchTask: [Launch] = (try? await launches.fetchUpcomingLaunches()) ?? []
        async let apodTask: APOD? = try? apodClient.fetchToday()
        async let marsTask: MarsWeather? = try? marsClient.fetchLatest()
        async let issTask: ISSPosition? = try? issClient.fetchPosition()

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

        let space = await spaceTask
        if space == nil { errors["swpc"] = "Space weather unavailable" }

        let launchList = await launchTask
        let apod = await apodTask
        let mars = await marsTask
        let iss = await issTask
        if apod == nil { errors["apod"] = "APOD unavailable (NASA API)" }
        if mars == nil { errors["mars"] = "Mars weather unavailable (MAAS2)" }
        if iss == nil { errors["iss"] = "ISS position unavailable" }

        let sun = SunEvents.compute(
            when: when,
            latitude: lat,
            longitude: lng,
            timezoneName: tz
        )
        let moon = MoonPhase.compute(when: when)
        let planets = Planets.compute(when: when)

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
            apod: apod,
            mars: mars,
            iss: iss,
            errors: errors
        )
    }
}
