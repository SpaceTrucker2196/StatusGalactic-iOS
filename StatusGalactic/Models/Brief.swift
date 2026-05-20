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
    let iss: ISSPosition?
    let errors: [String: String]

    enum CodingKeys: String, CodingKey {
        case when, lat, lng, timezone
        case locationName = "location_name"
        case earth, marine, space, sun, moon, planets, launches, apod, mars, iss, errors
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
        iss: ISSPosition? = nil,
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
        self.iss = iss
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
    let periods: [WeatherPeriod]

    enum CodingKeys: String, CodingKey {
        case locationName = "location_name"
        case periods
    }
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

struct ISSPosition: Codable, Hashable {
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
