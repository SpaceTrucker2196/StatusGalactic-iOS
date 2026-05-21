import Foundation

// MARK: - Brief (matches weathergalactic Brief pydantic model)

struct Brief: Codable {
    let when: Date
    let lat: Double
    let lng: Double
    let timezone: String
    let locationName: String?
    let earth: EarthWeather?
    let marine: MarineWeather?
    let space: SpaceWeather?
    let sun: SolarEvents?
    let moon: Moon?
    let planets: [Planet]
    let launches: [Launch]
    let apod: APOD?
    let mars: MarsWeather?
    let crewed: [CrewedObject]
    let repeaters: [Repeater]
    let tides: Tides?
    let river: RiverGauge?
    let neos: [NearEarthObject]
    let interstellar: [InterstellarObject]
    let constellations: [ConstellationSummary]
    let errors: [String: String]

    enum CodingKeys: String, CodingKey {
        case when, lat, lng, timezone
        case locationName = "location_name"
        case earth, marine, space, sun, moon, planets, launches, apod, mars, crewed
        case repeaters, tides, river, neos, interstellar, constellations, errors
    }

    init(
        when: Date,
        lat: Double,
        lng: Double,
        timezone: String,
        locationName: String?,
        earth: EarthWeather?,
        marine: MarineWeather?,
        space: SpaceWeather?,
        sun: SolarEvents?,
        moon: Moon?,
        planets: [Planet],
        launches: [Launch],
        apod: APOD? = nil,
        mars: MarsWeather? = nil,
        crewed: [CrewedObject] = [],
        repeaters: [Repeater] = [],
        tides: Tides? = nil,
        river: RiverGauge? = nil,
        neos: [NearEarthObject] = [],
        interstellar: [InterstellarObject] = [],
        constellations: [ConstellationSummary] = [],
        errors: [String: String]
    ) {
        self.when = when
        self.lat = lat
        self.lng = lng
        self.timezone = timezone
        self.locationName = locationName
        self.earth = earth
        self.marine = marine
        self.space = space
        self.sun = sun
        self.moon = moon
        self.planets = planets
        self.launches = launches
        self.apod = apod
        self.mars = mars
        self.crewed = crewed
        self.repeaters = repeaters
        self.tides = tides
        self.river = river
        self.neos = neos
        self.interstellar = interstellar
        self.constellations = constellations
        self.errors = errors
    }
}

struct WeatherPeriod: Codable, Identifiable {
    var id: String { name }
    let name: String
    let shortForecast: String
    let temperature: Int?
    let temperatureUnit: String
    let isDaytime: Bool
    let wind: String?
    let detailedForecast: String?

    enum CodingKeys: String, CodingKey {
        case name
        case shortForecast = "short_forecast"
        case temperature
        case temperatureUnit = "temperature_unit"
        case isDaytime = "is_daytime"
        case wind
        case detailedForecast = "detailed_forecast"
    }
}

struct EarthWeather: Codable {
    let locationName: String?
    let city: String?
    let state: String?
    let periods: [WeatherPeriod]
    let hourly: [HourlySample]

    enum CodingKeys: String, CodingKey {
        case locationName = "location_name"
        case city, state, periods, hourly
    }

    init(
        locationName: String?,
        city: String? = nil,
        state: String? = nil,
        periods: [WeatherPeriod],
        hourly: [HourlySample] = []
    ) {
        self.locationName = locationName
        self.city = city
        self.state = state
        self.periods = periods
        self.hourly = hourly
    }
}

/// One hour of NWS hourly forecast. Powers the almanac sparkline view.
struct HourlySample: Codable, Identifiable, Hashable {
    var id: Date { time }
    let time: Date
    let temperatureF: Double?
    let dewpointC: Double?
    let humidityPct: Double?
    let windSpeedMph: Double?
    let windDirection: String?
    let precipChancePct: Double?
    let shortForecast: String?
    let isDaytime: Bool
}

struct MarineWeather: Codable {
    let zoneId: String
    let periods: [WeatherPeriod]

    enum CodingKeys: String, CodingKey {
        case zoneId = "zone_id"
        case periods
    }
}

struct SpaceWeather: Codable {
    let solarFlux: Double?
    let kpIndex: Double?
    let kpStatus: String?
    let auroraLikely: Bool
    let hfSummary: String?
    let observedAt: Date?

    enum CodingKeys: String, CodingKey {
        case solarFlux = "solar_flux"
        case kpIndex = "kp_index"
        case kpStatus = "kp_status"
        case auroraLikely = "aurora_likely"
        case hfSummary = "hf_summary"
        case observedAt = "observed_at"
    }
}

struct SolarEvents: Codable {
    let timezone: String
    let sunriseUtc: Date?
    let sunsetUtc: Date?
    let goldenMorningStartUtc: Date?
    let goldenMorningEndUtc: Date?
    let goldenEveningStartUtc: Date?
    let goldenEveningEndUtc: Date?
    let civilDawnUtc: Date?
    let civilDuskUtc: Date?
    let nauticalDawnUtc: Date?
    let nauticalDuskUtc: Date?
    let astronomicalDawnUtc: Date?
    let astronomicalDuskUtc: Date?

    enum CodingKeys: String, CodingKey {
        case timezone
        case sunriseUtc = "sunrise_utc"
        case sunsetUtc = "sunset_utc"
        case goldenMorningStartUtc = "golden_morning_start_utc"
        case goldenMorningEndUtc = "golden_morning_end_utc"
        case goldenEveningStartUtc = "golden_evening_start_utc"
        case goldenEveningEndUtc = "golden_evening_end_utc"
        case civilDawnUtc = "civil_dawn_utc"
        case civilDuskUtc = "civil_dusk_utc"
        case nauticalDawnUtc = "nautical_dawn_utc"
        case nauticalDuskUtc = "nautical_dusk_utc"
        case astronomicalDawnUtc = "astronomical_dawn_utc"
        case astronomicalDuskUtc = "astronomical_dusk_utc"
    }
}

struct Moon: Codable {
    let phaseName: String
    let phaseAngleDeg: Double
    let illuminationPct: Double

    enum CodingKeys: String, CodingKey {
        case phaseName = "phase_name"
        case phaseAngleDeg = "phase_angle_deg"
        case illuminationPct = "illumination_pct"
    }
}

struct Planet: Codable, Identifiable {
    var id: String { body }
    let body: String
    let sign: String
    let degree: Double
    let retrograde: Bool
}

struct Launch: Codable, Identifiable {
    var id: String { name + whenUtc.ISO8601Format() }
    let name: String
    let whenUtc: Date
    let pad: String?
    let provider: String?
    let status: String?

    enum CodingKeys: String, CodingKey {
        case name
        case whenUtc = "when_utc"
        case pad, provider, status
    }
}

// MARK: - Cosmos (APOD + Mars weather)

struct APOD: Codable, Hashable {
    let date: String
    let title: String
    let explanation: String
    let url: String
    let hdurl: String?
    let mediaType: String
    let thumbnailUrl: String?
    let copyright: String?

    enum CodingKeys: String, CodingKey {
        case date, title, explanation, url, hdurl, copyright
        case mediaType = "media_type"
        case thumbnailUrl = "thumbnail_url"
    }

    var displayImageURL: URL? {
        if mediaType == "image" {
            return URL(string: hdurl ?? url)
        }
        if let thumb = thumbnailUrl, let u = URL(string: thumb) {
            return u
        }
        return nil
    }
}

struct MarsWeather: Codable, Hashable {
    let sol: Int
    let season: String?
    let terrestrialDate: String?
    let minTempC: Double?
    let maxTempC: Double?
    let pressurePa: Double?
    let atmoOpacity: String?
    let sunrise: String?
    let sunset: String?
}

/// A live position snapshot for a crewed orbital spacecraft. `passes` is only
/// populated for objects we can predict passes for (today: ISS via N2YO).
struct CrewedObject: Codable, Hashable, Identifiable {
    var id: Int { noradId }
    let noradId: Int
    let name: String
    let latitude: Double
    let longitude: Double
    let altitudeKm: Double
    let velocityKmh: Double
    let visibility: String?
    let footprintKm: Double?
    let observedAt: Date
    var passes: [ISSPass] = []
}

struct ISSPass: Codable, Identifiable, Hashable {
    var id: Date { startUTC }
    let startUTC: Date
    let endUTC: Date
    let maxUTC: Date
    let startAzCompass: String?
    let endAzCompass: String?
    let maxElevation: Double
    let durationSeconds: Int
    let magnitude: Double?
}

struct Repeater: Codable, Identifiable, Hashable {
    var id: String { "\(callsign)-\(frequencyMHz)" }
    let callsign: String
    let frequencyMHz: Double
    let inputFreqMHz: Double?
    let offsetMHz: Double?
    let plTone: String?
    let modes: [String]            // "FM", "DMR", "D-Star", "Fusion", "P25", "NXDN"
    let nearestCity: String?
    let landmark: String?
    let useType: String?           // "OPEN", "CLOSED", "PRIVATE"
    let operationalStatus: String? // "On-air", "Off-air"
}

struct TideEvent: Codable, Identifiable, Hashable {
    var id: Date { time }
    let time: Date           // UTC
    let heightFt: Double
    let kind: Kind

    enum Kind: String, Codable, Hashable {
        case high = "H"
        case low  = "L"
    }
}

struct Tides: Codable, Hashable {
    let stationId: String
    let stationName: String
    let distanceKm: Double
    let events: [TideEvent]
}

/// Aggregate stats for a named satellite constellation, counted via
/// Celestrak's GP element-set listings.
struct ConstellationSummary: Codable, Identifiable, Hashable {
    var id: String { name }
    let name: String              // "Starlink", "GPS Operational"
    let group: String             // Celestrak group slug
    let count: Int                // active objects in the catalog
    let latestEpochAt: Date?      // most recent element-set epoch seen
}

/// Near-Earth Object close-approach record from NASA NEO API.
struct NearEarthObject: Codable, Identifiable, Hashable {
    var id: String { name + approachAt.ISO8601Format() }
    let name: String
    let magnitudeH: Double
    let diameterMinM: Double
    let diameterMaxM: Double
    let isHazardous: Bool
    let approachAt: Date
    let missDistanceKm: Double
    let velocityKps: Double
    let nasaJplURL: String?
}

/// One known interstellar object visiting (or having visited) the solar
/// system. Only a handful are known — small enough that the catalog is
/// hardcoded rather than fetched.
struct InterstellarObject: Codable, Identifiable, Hashable {
    var id: String { designation }
    let designation: String
    let discoveryDate: String
    let perihelionAU: Double?
    let eccentricity: Double?
    let inclinationDeg: Double?
    let status: String
    let notes: String
}

/// NOAA NWPS river gauge with current stage and flood thresholds.
struct RiverGauge: Codable, Hashable {
    let lid: String              // NWS Location ID, e.g. "LCRW3"
    let name: String
    let lat: Double
    let lng: Double
    let distanceKm: Double
    let currentStageFt: Double?
    let observedAt: Date?
    let actionStageFt: Double?
    let minorFloodStageFt: Double?
    let moderateFloodStageFt: Double?
    let majorFloodStageFt: Double?
    let forecastPeakFt: Double?
    let forecastPeakAt: Date?

    var floodStatus: FloodStatus {
        guard let stage = currentStageFt else { return .noData }
        if let major = majorFloodStageFt,    stage >= major { return .major }
        if let mod   = moderateFloodStageFt, stage >= mod   { return .moderate }
        if let minor = minorFloodStageFt,    stage >= minor { return .minor }
        if let act   = actionStageFt,        stage >= act   { return .action }
        return .belowAction
    }
}

enum FloodStatus: String, Codable, Hashable {
    case noData
    case belowAction
    case action
    case minor
    case moderate
    case major
}
