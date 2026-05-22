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
    let crewedLaunches: [CrewedLaunch]
    let apod: APOD?
    let mars: MarsWeather?
    let crewed: [CrewedObject]
    let repeaters: [Repeater]
    let tides: Tides?
    let river: RiverGauge?
    let neos: [NearEarthObject]
    let interstellar: [InterstellarObject]
    let constellations: [ConstellationSummary]
    let earthquakes: [Earthquake]
    let activeRegions: [ActiveRegion]
    let flareProbability: FlareProbability?
    let kpForecast: [KpForecastDay]
    let solarWind: SolarWind?
    let wwvBulletin: WWVBulletin?
    let cmes: [CMEEvent]
    let solarOutlook: [SolarOutlookDay]
    let xRay: XRayState?
    let proton: ProtonState?
    let ionosondes: [IonosondeStation]
    let aurora: AuroraForecast?
    let bandConditions: [BandCondition]
    let potaSpots: [POTASpot]
    let sotaSpots: [SOTASpot]
    let dxSpots: [DXSpot]
    let solarCycle: [SolarCyclePoint]
    let weatherAlerts: [WeatherAlert]
    let magneticDeclination: MagneticDeclination?
    let errors: [String: String]

    enum CodingKeys: String, CodingKey {
        case when, lat, lng, timezone
        case locationName = "location_name"
        case earth, marine, space, sun, moon, planets, launches, apod, mars, crewed
        case crewedLaunches = "crewed_launches"
        case repeaters, tides, river, neos, interstellar, constellations, earthquakes
        case activeRegions = "active_regions"
        case flareProbability = "flare_probability"
        case kpForecast = "kp_forecast"
        case solarWind = "solar_wind"
        case wwvBulletin = "wwv_bulletin"
        case cmes
        case solarOutlook = "solar_outlook"
        case xRay = "x_ray"
        case proton, ionosondes, aurora
        case bandConditions = "band_conditions"
        case potaSpots = "pota_spots"
        case sotaSpots = "sota_spots"
        case dxSpots = "dx_spots"
        case solarCycle = "solar_cycle"
        case weatherAlerts = "weather_alerts"
        case magneticDeclination = "magnetic_declination"
        case errors
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
        crewedLaunches: [CrewedLaunch] = [],
        apod: APOD? = nil,
        mars: MarsWeather? = nil,
        crewed: [CrewedObject] = [],
        repeaters: [Repeater] = [],
        tides: Tides? = nil,
        river: RiverGauge? = nil,
        neos: [NearEarthObject] = [],
        interstellar: [InterstellarObject] = [],
        constellations: [ConstellationSummary] = [],
        earthquakes: [Earthquake] = [],
        activeRegions: [ActiveRegion] = [],
        flareProbability: FlareProbability? = nil,
        kpForecast: [KpForecastDay] = [],
        solarWind: SolarWind? = nil,
        wwvBulletin: WWVBulletin? = nil,
        cmes: [CMEEvent] = [],
        solarOutlook: [SolarOutlookDay] = [],
        xRay: XRayState? = nil,
        proton: ProtonState? = nil,
        ionosondes: [IonosondeStation] = [],
        aurora: AuroraForecast? = nil,
        bandConditions: [BandCondition] = [],
        potaSpots: [POTASpot] = [],
        sotaSpots: [SOTASpot] = [],
        dxSpots: [DXSpot] = [],
        solarCycle: [SolarCyclePoint] = [],
        weatherAlerts: [WeatherAlert] = [],
        magneticDeclination: MagneticDeclination? = nil,
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
        self.crewedLaunches = crewedLaunches
        self.apod = apod
        self.mars = mars
        self.crewed = crewed
        self.repeaters = repeaters
        self.tides = tides
        self.river = river
        self.neos = neos
        self.interstellar = interstellar
        self.constellations = constellations
        self.earthquakes = earthquakes
        self.activeRegions = activeRegions
        self.flareProbability = flareProbability
        self.kpForecast = kpForecast
        self.solarWind = solarWind
        self.wwvBulletin = wwvBulletin
        self.cmes = cmes
        self.solarOutlook = solarOutlook
        self.xRay = xRay
        self.proton = proton
        self.ionosondes = ionosondes
        self.aurora = aurora
        self.bandConditions = bandConditions
        self.potaSpots = potaSpots
        self.sotaSpots = sotaSpots
        self.dxSpots = dxSpots
        self.solarCycle = solarCycle
        self.weatherAlerts = weatherAlerts
        self.magneticDeclination = magneticDeclination
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

/// One numbered NOAA sunspot active region, current at the latest SRS issue.
struct ActiveRegion: Codable, Identifiable, Hashable {
    var id: Int { region }
    let region: Int                 // e.g. 4443
    let location: String            // heliographic coords, "S16E23"
    let latitude: Int?
    let longitude: Int?
    let area: Int?                  // millionths of solar disk
    let numberOfSpots: Int?
    let magClass: String?           // Mt Wilson class: "Alpha", "Beta", "Beta-Gamma", ...
    let spotClass: String?          // McIntosh class, e.g. "Cao"
    let observedAt: Date?

    enum CodingKeys: String, CodingKey {
        case region, location, latitude, longitude, area
        case numberOfSpots = "number_spots"
        case magClass = "mag_class"
        case spotClass = "spot_class"
        case observedAt = "observed_at"
    }
}

/// 24-hour flare and proton-event probability forecast (percent, 0..100).
/// Issued daily by NOAA SWPC alongside the geomagnetic forecast.
struct FlareProbability: Codable, Hashable {
    let issuedAt: Date?
    let cClassPct: Int      // ≥C-class flare next 24h
    let mClassPct: Int
    let xClassPct: Int
    let protonEventPct: Int

    enum CodingKeys: String, CodingKey {
        case issuedAt = "issued_at"
        case cClassPct = "c_class_pct"
        case mClassPct = "m_class_pct"
        case xClassPct = "x_class_pct"
        case protonEventPct = "proton_event_pct"
    }
}

/// One day in the SWPC 3-day geomagnetic forecast: peak expected Kp plus
/// the human-readable G-scale (G0..G5) derived from that peak.
struct KpForecastDay: Codable, Identifiable, Hashable {
    var id: Date { date }
    let date: Date
    let maxKp: Double
    let gScale: String      // "G0", "G1", ...

    enum CodingKeys: String, CodingKey {
        case date
        case maxKp = "max_kp"
        case gScale = "g_scale"
    }
}

/// Real-time L1 solar wind snapshot from DSCOVR/ACE via NOAA SWPC.
struct SolarWind: Codable, Hashable {
    let observedAt: Date
    let speedKmS: Double?       // bulk speed, km/s
    let densityP: Double?       // proton density, p/cm³
    let temperatureK: Double?   // plasma temperature, K
    let bzNT: Double?           // IMF Bz GSM, nT (negative = southward, aurora-friendly)
    let btNT: Double?           // total field magnitude, nT

    enum CodingKeys: String, CodingKey {
        case observedAt = "observed_at"
        case speedKmS = "speed_km_s"
        case densityP = "density_p"
        case temperatureK = "temperature_k"
        case bzNT = "bz_nt"
        case btNT = "bt_nt"
    }
}

/// NOAA WMM magnetic declination at the viewer's coordinates. Hams and
/// astrophotographers both want this: it's the offset between true north
/// (where you really need to point a Yagi / polar-align a mount) and the
/// magnetic compass bearing.
struct MagneticDeclination: Codable, Hashable {
    let latitude: Double
    let longitude: Double
    let declinationDeg: Double         // east-positive
    let inclinationDeg: Double?        // dip angle
    let totalFieldNT: Double?          // |B|, nT
    let modelDate: Double?             // decimal year used for evaluation
    let model: String?                 // e.g. "WMM-2025"
    let observedAt: Date

    /// "2.3°E" / "1.1°W" / "0.0°"
    var formatted: String {
        if abs(declinationDeg) < 0.05 { return "0.0°" }
        let suffix = declinationDeg >= 0 ? "E" : "W"
        return String(format: "%.1f°%@", abs(declinationDeg), suffix)
    }

    enum CodingKeys: String, CodingKey {
        case latitude, longitude, model
        case declinationDeg = "declination_deg"
        case inclinationDeg = "inclination_deg"
        case totalFieldNT = "total_field_nt"
        case modelDate = "model_date"
        case observedAt = "observed_at"
    }
}

/// One active NWS alert (warning / watch / advisory) intersecting the
/// viewer's location. Severity is the CAP severity ordinal, so we can
/// rank and color reliably even when the event string varies.
struct WeatherAlert: Codable, Identifiable, Hashable {
    var id: String { alertId }
    let alertId: String
    let event: String                // "Tornado Warning", "Flood Advisory"
    let severity: String             // "Extreme" | "Severe" | "Moderate" | "Minor" | "Unknown"
    let certainty: String?
    let urgency: String?
    let headline: String?
    let description: String?
    let instruction: String?
    let areaDesc: String?
    let onsetAt: Date?
    let expiresAt: Date?
    let senderName: String?

    enum CodingKeys: String, CodingKey {
        case alertId = "alert_id"
        case event, severity, certainty, urgency, headline, description, instruction
        case areaDesc = "area_desc"
        case onsetAt = "onset_at"
        case expiresAt = "expires_at"
        case senderName = "sender_name"
    }

    /// 0..4 numeric rank for sorting and palette mapping.
    var severityLevel: Int {
        switch severity {
        case "Extreme":  return 4
        case "Severe":   return 3
        case "Moderate": return 2
        case "Minor":    return 1
        default:         return 0
        }
    }
}

/// One live Summits On The Air spot. Same shape as POTASpot but the
/// reference is a summit code (e.g. `W4V/CT-001`) and the program puts
/// the elevation in the details string.
struct SOTASpot: Codable, Identifiable, Hashable {
    var id: Int { spotId }
    let spotId: Int
    let activator: String
    let summitCode: String
    let summitDetails: String          // "Mount Mitchell, 2037m"
    let frequencyKHz: Double
    let mode: String
    let spotTime: Date
    let comments: String?
}

/// One DX cluster spot — short-lived sighting of a distant station broadcast
/// by another operator. dxsummit.fi serves them as JSON.
struct DXSpot: Codable, Identifiable, Hashable {
    var id: String { spotter + dxCallsign + spotTime.ISO8601Format() }
    let dxCallsign: String        // the rare/DX station being spotted
    let spotter: String           // who spotted them
    let frequencyKHz: Double
    let info: String?             // free-form remark
    let spotTime: Date
}

/// One live Parks On The Air spot. POTA's API publishes spots roughly
/// every minute; we re-rank by distance to the viewer.
struct POTASpot: Codable, Identifiable, Hashable {
    var id: String { String(spotId) }
    let spotId: Int
    let activator: String
    let parkRef: String           // "K-1234", "VE-0123"
    let parkName: String
    let frequencyKHz: Double
    let mode: String              // "CW", "SSB", "FT8", ...
    let spotTime: Date
    let latitude: Double?
    let longitude: Double?
    let locationDesc: String?     // "US-WI"
    let comments: String?
    var distanceKm: Double?
}

/// One month in the long-running NOAA observed solar-cycle indices table.
/// Smoothed values may be nil for the trailing 6 months (the smoothing
/// window hasn't caught up yet).
struct SolarCyclePoint: Codable, Identifiable, Hashable {
    var id: Date { month }
    let month: Date
    let sunspotNumber: Double
    let smoothedSunspotNumber: Double?
    let radioFlux: Double
    let smoothedRadioFlux: Double?

    enum CodingKeys: String, CodingKey {
        case month
        case sunspotNumber = "sunspot_number"
        case smoothedSunspotNumber = "smoothed_sunspot_number"
        case radioFlux = "radio_flux"
        case smoothedRadioFlux = "smoothed_radio_flux"
    }
}

/// OVATION 30-minute aurora forecast sampled at the observer's location.
/// `localProbabilityPct` is 0..100; the global maximum is included so we
/// can show "the oval is currently up to 60% at its peak" alongside.
struct AuroraForecast: Codable, Hashable {
    let observedAt: Date?
    let forecastFor: Date?
    let localProbabilityPct: Int
    let globalMaxPct: Int
}

/// Synthesized HF band condition (open/fair/poor/closed) plus the dominant
/// reason driving that label.
struct BandCondition: Codable, Identifiable, Hashable {
    var id: String { band }
    let band: String              // "80m", "40m", "20m", "17m", "15m", "12m", "10m", "6m"
    let centerMHz: Double         // nominal frequency for the band
    let dayStatus: String         // "Open", "Fair", "Poor", "Closed"
    let nightStatus: String
    let reason: String?           // dominant limiting factor, e.g. "G2 storm", "MUF 9 MHz"
}

/// Current + 24h-peak GOES soft X-ray state and the derived NOAA R-scale
/// (radio blackout) badge. Long-wave channel (1-8Å) is the canonical one.
struct XRayState: Codable, Hashable {
    let currentFlux: Double         // W/m², 1-8Å
    let currentClass: String        // e.g. "B5.2", "M1.0", "X1.4"
    let peakFlux24h: Double
    let peakClass24h: String
    let rScale: String              // "R0".."R5"
    let observedAt: Date
}

/// Current GOES integral proton flux (≥10 MeV) and derived S-scale.
struct ProtonState: Codable, Hashable {
    let fluxPfu: Double             // particle flux units
    let sScale: String              // "S0".."S5"
    let observedAt: Date
}

/// One digisonde station from prop.kc2g.com — the community ionosonde
/// network used by ham operators for HF propagation planning.
struct IonosondeStation: Codable, Identifiable, Hashable {
    var id: String { name }
    let name: String                // 5-char IUWDS code, e.g. "WP937"
    let latitude: Double
    let longitude: Double
    let fof2MHz: Double?            // critical frequency, F2 layer
    let mufMHz: Double?             // MUF(3000)F2 — long-haul HF ceiling
    let observedAt: Date?
    var distanceKm: Double?         // from viewer
}

/// One CME event from NASA DONKI. Speed/direction come from the most
/// accurate `cmeAnalyses` entry when available; halo CMEs (Earth-directed)
/// are flagged so the brief can highlight them.
struct CMEEvent: Codable, Identifiable, Hashable {
    var id: String { activityID }
    let activityID: String
    let startTime: Date
    let sourceLocation: String?     // heliographic, e.g. "N15W23"
    let speedKmS: Double?
    let halfAngleDeg: Double?
    let isHalo: Bool
    let arrivalEstimateUtc: Date?
    let note: String?
    let linkURL: String?

    enum CodingKeys: String, CodingKey {
        case activityID = "activity_id"
        case startTime = "start_time"
        case sourceLocation = "source_location"
        case speedKmS = "speed_km_s"
        case halfAngleDeg = "half_angle_deg"
        case isHalo = "is_halo"
        case arrivalEstimateUtc = "arrival_estimate_utc"
        case note
        case linkURL = "link_url"
    }
}

/// One day in the NOAA SWPC 27-day Space Weather Outlook table.
struct SolarOutlookDay: Codable, Identifiable, Hashable {
    var id: Date { date }
    let date: Date
    let radioFlux: Int           // F10.7 cm, sfu
    let aIndex: Int              // Planetary A-index
    let largestKp: Int           // Largest expected Kp that day

    enum CodingKeys: String, CodingKey {
        case date
        case radioFlux = "radio_flux"
        case aIndex = "a_index"
        case largestKp = "largest_kp"
    }
}

/// Parsed NOAA WWV "Geophysical Alert Message" bulletin (5/15-minute audio
/// transcript). Carries the daily solar/geomag summary in operator-friendly
/// language.
struct WWVBulletin: Codable, Hashable {
    let issuedAt: Date?
    let solarFlux: Int?
    let aIndex: Int?
    let kIndex: Int?
    let geomagSummary: String?    // e.g. "The geomagnetic field has been quiet to unsettled."
    let propagationSummary: String?
    let rawText: String

    enum CodingKeys: String, CodingKey {
        case issuedAt = "issued_at"
        case solarFlux = "solar_flux"
        case aIndex = "a_index"
        case kIndex = "k_index"
        case geomagSummary = "geomag_summary"
        case propagationSummary = "propagation_summary"
        case rawText = "raw_text"
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

    // Optional ephemeris populated when the brief has observer coordinates.
    // Decoders that don't supply these fields fall back to `nil`.
    var rightAscensionHours: Double?
    var declinationDeg: Double?
    var altitudeDeg: Double?           // current apparent altitude
    var azimuthDeg: Double?            // current apparent azimuth (N=0, E=90)
    var riseAt: Date?
    var transitAt: Date?
    var setAt: Date?
    var circumpolarState: String?      // "always_up" / "always_down" / nil

    enum CodingKeys: String, CodingKey {
        case body, sign, degree, retrograde
        case rightAscensionHours = "right_ascension_hours"
        case declinationDeg = "declination_deg"
        case altitudeDeg = "altitude_deg"
        case azimuthDeg = "azimuth_deg"
        case riseAt = "rise_at"
        case transitAt = "transit_at"
        case setAt = "set_at"
        case circumpolarState = "circumpolar_state"
    }
}

/// Upcoming launch that's carrying humans — Soyuz crew rotations, Crew
/// Dragon flights, Shenzhou, Starliner missions, etc. Same shape as
/// `Launch` but enriched with rocket + destination so the crewed card
/// can render the full "Falcon 9 → Crew-12 → ISS" story.
struct CrewedLaunch: Codable, Identifiable, Hashable {
    var id: String { name + whenUtc.ISO8601Format() }
    let name: String
    let whenUtc: Date
    let pad: String?
    let provider: String?
    let status: String?
    let missionName: String?
    let missionDescription: String?
    let rocketName: String?
    let destination: String?   // orbit / destination ("LEO", "ISS", "Moon")

    enum CodingKeys: String, CodingKey {
        case name
        case whenUtc = "when_utc"
        case pad, provider, status
        case missionName = "mission_name"
        case missionDescription = "mission_description"
        case rocketName = "rocket_name"
        case destination
    }
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
    /// Mission the reading came from — "Perseverance" or "Curiosity".
    /// Default Perseverance for backward compatibility with older payloads.
    let source: String

    enum CodingKeys: String, CodingKey {
        case sol, season
        case terrestrialDate = "terrestrial_date"
        case minTempC = "min_temp_c"
        case maxTempC = "max_temp_c"
        case pressurePa = "pressure_pa"
        case atmoOpacity = "atmo_opacity"
        case sunrise, sunset, source
    }

    init(sol: Int, season: String?, terrestrialDate: String?,
         minTempC: Double?, maxTempC: Double?, pressurePa: Double?,
         atmoOpacity: String?, sunrise: String?, sunset: String?,
         source: String = "Perseverance") {
        self.sol = sol
        self.season = season
        self.terrestrialDate = terrestrialDate
        self.minTempC = minTempC
        self.maxTempC = maxTempC
        self.pressurePa = pressurePa
        self.atmoOpacity = atmoOpacity
        self.sunrise = sunrise
        self.sunset = sunset
        self.source = source
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        sol = try c.decode(Int.self, forKey: .sol)
        season = try c.decodeIfPresent(String.self, forKey: .season)
        terrestrialDate = try c.decodeIfPresent(String.self, forKey: .terrestrialDate)
        minTempC = try c.decodeIfPresent(Double.self, forKey: .minTempC)
        maxTempC = try c.decodeIfPresent(Double.self, forKey: .maxTempC)
        pressurePa = try c.decodeIfPresent(Double.self, forKey: .pressurePa)
        atmoOpacity = try c.decodeIfPresent(String.self, forKey: .atmoOpacity)
        sunrise = try c.decodeIfPresent(String.self, forKey: .sunrise)
        sunset = try c.decodeIfPresent(String.self, forKey: .sunset)
        source = try c.decodeIfPresent(String.self, forKey: .source) ?? "Perseverance"
    }

    /// Number of days between the terrestrial date the reading was taken
    /// and `now`. NASA's MEDA / REMS feeds typically lag by days to weeks
    /// because the data has to be downlinked, calibrated, and published.
    func ageDays(now: Date = Date()) -> Int? {
        guard let t = terrestrialDate else { return nil }
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        f.locale = Locale(identifier: "en_US_POSIX")
        guard let date = f.date(from: t) else { return nil }
        return Calendar(identifier: .gregorian)
            .dateComponents([.day], from: date, to: now).day
    }
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

/// Single USGS earthquake event. Distance is populated only when the
/// brief has a viewer coordinate to anchor against.
struct Earthquake: Codable, Identifiable, Hashable {
    let id: String                 // USGS event id (e.g. "us7000abcd")
    let magnitude: Double
    let place: String              // "12km NW of Foo, CA"
    let time: Date
    let latitude: Double
    let longitude: Double
    let depthKm: Double
    let usgsURL: String?
    let isSignificant: Bool
    var distanceKm: Double?        // from viewer; nil if not computable
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
