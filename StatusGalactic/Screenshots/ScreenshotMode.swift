import Foundation
import CoreLocation

/// Drives the App Store screenshot pipeline. The UITest target launches the
/// app with `-UITEST_SCREENSHOT_MODE` and the launch path here seeds an
/// in-memory brief + APRS + callsign state so every tab renders curated,
/// network-independent content. Nothing in this file runs in production —
/// `isActive` is false unless the launch argument is present.
enum ScreenshotMode {

    /// Keep in sync with `StatusGalacticUITests/ScreenshotTests.swift`.
    static let launchArgument = "-UITEST_SCREENSHOT_MODE"

    static var isActive: Bool {
        ProcessInfo.processInfo.arguments.contains(launchArgument)
    }

    /// Seed every observable the app reads from on launch so the tabs render
    /// real-looking content without any network or location-permission flow.
    @MainActor
    static func applyIfActive(
        config: ClientConfig,
        location: LocationManager,
        brief: BriefViewModel,
        callsigns: CallsignStore,
        aprsMessages: APRSMessageStore
    ) {
        guard isActive else { return }

        config.myCallsign = "K8RVR"
        config.aprsAPIKey = "demo-key-screenshot-mode"
        config.defaultMarineZone = "GMZ033"

        // Bozeman, MT — a poleward-ish read so the Kp / aurora story is
        // visually interesting, with NWS forecast coverage so the Earth
        // weather card looks populated.
        location.lastLocation = CLLocation(latitude: 45.68, longitude: -111.04)

        let now = Date()
        brief.marineZone = config.defaultMarineZone
        brief.state = .loaded(heroBrief(now: now), fetchedAt: now, isStale: false)

        seedCallsigns(callsigns)
        seedAPRSMessages(aprsMessages, now: now)
    }

    private static func seedCallsigns(_ store: CallsignStore) {
        guard store.callsigns.isEmpty else { return }
        store.add("W1AW",  label: "ARRL HQ",      notes: "")
        store.add("VE3XYZ", label: "Toronto sked", notes: "")
        store.add("KC1HBI", label: "Friend, NH",   notes: "")
        store.add("N0CALL", label: "Test fixture", notes: "")
    }

    private static func seedAPRSMessages(_ store: APRSMessageStore, now: Date) {
        guard store.messages.isEmpty else { return }
        let bulletin = APRSMessage(
            messageID: "B-001",
            from: "WX1BOX",
            to: "BLNWX",
            text: "Severe T-storm watch until 02Z. Hail to 1\". Stay tuned to NWR.",
            sentAt: now.addingTimeInterval(-12 * 60),
            direction: .incoming,
            acknowledged: false
        )
        let inboundFromFriend = APRSMessage(
            messageID: "M-118",
            from: "VE3XYZ",
            to: "K8RVR",
            text: "Working POTA K-1234 on 20m, 14.252. Heard you on 17m earlier.",
            sentAt: now.addingTimeInterval(-32 * 60),
            direction: .incoming,
            acknowledged: true
        )
        let inboundFromARRL = APRSMessage(
            messageID: "M-119",
            from: "W1AW",
            to: "K8RVR",
            text: "73 — code practice tonight 0100Z, 18 wpm.",
            sentAt: now.addingTimeInterval(-3 * 3600),
            direction: .incoming,
            acknowledged: true
        )
        store.upsert(many: [bulletin, inboundFromFriend, inboundFromARRL])
    }

    // MARK: - Hero Brief

    private static func heroBrief(now: Date) -> Brief {
        Brief(
            when: now,
            lat: 45.68,
            lng: -111.04,
            timezone: "America/Denver",
            locationName: "Bozeman, MT",
            earth: heroEarth(),
            marine: heroMarine(),
            space: heroSpace(now: now),
            sun: heroSun(now: now),
            moon: heroMoon(),
            planets: heroPlanets(),
            launches: heroLaunches(now: now),
            crewedLaunches: heroCrewedLaunches(now: now),
            apod: nil,
            mars: nil,
            crewed: [],
            repeaters: [],
            tides: nil,
            river: nil,
            neos: [],
            interstellar: [],
            constellations: [],
            earthquakes: [],
            activeRegions: [],
            flareProbability: nil,
            kpForecast: heroKpForecast(now: now),
            solarWind: heroSolarWind(now: now),
            wwvBulletin: heroWWV(now: now),
            cmes: [],
            solarOutlook: [],
            xRay: heroXRay(now: now),
            proton: ProtonState(fluxPfu: 0.5, sScale: "S0", observedAt: now),
            ionosondes: heroIonosondes(now: now),
            aurora: AuroraForecast(
                observedAt: now, forecastFor: now,
                localProbabilityPct: 42, globalMaxPct: 78
            ),
            bandConditions: heroBandConditions(),
            potaSpots: heroPOTA(now: now),
            sotaSpots: heroSOTA(now: now),
            dxSpots: heroDX(now: now),
            solarCycle: [],
            weatherAlerts: [],
            magneticDeclination: MagneticDeclination(
                latitude: 45.68, longitude: -111.04,
                declinationDeg: 11.6, inclinationDeg: 67.4,
                totalFieldNT: 53_500, modelDate: 2026.4,
                model: "WMM-2025", observedAt: now
            ),
            errors: [:]
        )
    }

    private static func heroEarth() -> EarthWeather {
        EarthWeather(
            locationName: "Bozeman, MT",
            city: "Bozeman", state: "MT",
            periods: [
                WeatherPeriod(name: "This Afternoon", shortForecast: "Mostly Sunny",
                              temperature: 72, temperatureUnit: "F",
                              isDaytime: true, wind: "NW 8 mph", detailedForecast: nil),
                WeatherPeriod(name: "Tonight", shortForecast: "Clear",
                              temperature: 41, temperatureUnit: "F",
                              isDaytime: false, wind: "W 5 mph", detailedForecast: nil),
                WeatherPeriod(name: "Tomorrow", shortForecast: "Sunny",
                              temperature: 76, temperatureUnit: "F",
                              isDaytime: true, wind: "SW 10 mph", detailedForecast: nil),
                WeatherPeriod(name: "Tomorrow Night", shortForecast: "Partly Cloudy",
                              temperature: 44, temperatureUnit: "F",
                              isDaytime: false, wind: "W 6 mph", detailedForecast: nil),
            ],
            hourly: []
        )
    }

    private static func heroMarine() -> MarineWeather {
        MarineWeather(
            zoneId: "GMZ033",
            periods: [
                WeatherPeriod(name: "Today", shortForecast: "E winds 10 to 15 kt. Seas 2 to 3 ft.",
                              temperature: nil, temperatureUnit: "F",
                              isDaytime: true, wind: "E 10-15 kt", detailedForecast: nil),
                WeatherPeriod(name: "Tonight", shortForecast: "E winds 5 to 10 kt. Seas 2 ft.",
                              temperature: nil, temperatureUnit: "F",
                              isDaytime: false, wind: "E 5-10 kt", detailedForecast: nil),
                WeatherPeriod(name: "Tomorrow", shortForecast: "SE winds 10 kt. Seas 2 to 3 ft.",
                              temperature: nil, temperatureUnit: "F",
                              isDaytime: true, wind: "SE 10 kt", detailedForecast: nil),
            ]
        )
    }

    private static func heroSpace(now: Date) -> SpaceWeather {
        SpaceWeather(
            solarFlux: 168,
            kpIndex: 4.33,
            kpStatus: "active",
            auroraLikely: true,
            hfSummary: "Good on 20-15m; 10m fair; bands above 6m closed.",
            observedAt: now
        )
    }

    private static func heroSun(now: Date) -> SolarEvents {
        let cal = Calendar(identifier: .gregorian)
        var c = cal.dateComponents([.year, .month, .day], from: now)
        c.timeZone = TimeZone(identifier: "America/Denver")
        func at(hour: Int, minute: Int) -> Date? {
            c.hour = hour; c.minute = minute
            return cal.date(from: c)
        }
        return SolarEvents(
            timezone: "America/Denver",
            sunriseUtc: at(hour: 12, minute: 8),     // ~06:08 local
            sunsetUtc: at(hour: 2 + 24, minute: 41), // ~20:41 local next-day UTC
            goldenMorningStartUtc: at(hour: 11, minute: 35),
            goldenMorningEndUtc: at(hour: 12, minute: 38),
            goldenEveningStartUtc: at(hour: 2 + 24, minute: 11),
            goldenEveningEndUtc: at(hour: 3 + 24, minute: 14),
            civilDawnUtc: at(hour: 11, minute: 38),
            civilDuskUtc: at(hour: 3 + 24, minute: 11),
            nauticalDawnUtc: at(hour: 11, minute: 4),
            nauticalDuskUtc: at(hour: 3 + 24, minute: 45),
            astronomicalDawnUtc: at(hour: 10, minute: 31),
            astronomicalDuskUtc: at(hour: 4 + 24, minute: 18)
        )
    }

    private static func heroMoon() -> Moon {
        Moon(phaseName: "Waxing Gibbous", phaseAngleDeg: 112, illuminationPct: 71)
    }

    private static func heroPlanets() -> [Planet] {
        [
            Planet(body: "Sun",     sign: "Gemini",      degree: 4.2,  retrograde: false),
            Planet(body: "Moon",    sign: "Virgo",       degree: 22.8, retrograde: false),
            Planet(body: "Mercury", sign: "Gemini",      degree: 11.4, retrograde: false),
            Planet(body: "Venus",   sign: "Taurus",      degree: 27.6, retrograde: false),
            Planet(body: "Mars",    sign: "Cancer",      degree: 8.1,  retrograde: false),
            Planet(body: "Jupiter", sign: "Gemini",      degree: 15.0, retrograde: false),
            Planet(body: "Saturn",  sign: "Pisces",      degree: 19.3, retrograde: true),
            Planet(body: "Uranus",  sign: "Taurus",      degree: 25.7, retrograde: false),
            Planet(body: "Neptune", sign: "Aries",       degree: 1.4,  retrograde: false),
            Planet(body: "Pluto",   sign: "Aquarius",    degree: 3.2,  retrograde: true),
        ]
    }

    private static func heroLaunches(now: Date) -> [Launch] {
        let day: TimeInterval = 86_400
        return [
            Launch(name: "Falcon 9 · Starlink 12-7", whenUtc: now.addingTimeInterval(day * 2 + 3 * 3600),
                   pad: "SLC-40, Cape Canaveral", provider: "SpaceX", status: "Go for launch"),
            Launch(name: "Electron · 'Live and Let Fly'", whenUtc: now.addingTimeInterval(day * 4),
                   pad: "LC-1A, Mahia", provider: "Rocket Lab", status: "Scheduled"),
            Launch(name: "H3 · IGS-Radar 8", whenUtc: now.addingTimeInterval(day * 6),
                   pad: "LP-2, Tanegashima", provider: "JAXA / MHI", status: "Scheduled"),
            Launch(name: "Vulcan · USSF-87", whenUtc: now.addingTimeInterval(day * 9),
                   pad: "SLC-41, Cape Canaveral", provider: "ULA", status: "Scheduled"),
            Launch(name: "Long March 5B · CSS resupply", whenUtc: now.addingTimeInterval(day * 11),
                   pad: "LC-101, Wenchang", provider: "CASC", status: "Scheduled"),
        ]
    }

    private static func heroCrewedLaunches(now: Date) -> [CrewedLaunch] {
        [
            CrewedLaunch(
                name: "Crew-12",
                whenUtc: now.addingTimeInterval(86_400 * 14),
                pad: "LC-39A, KSC", provider: "SpaceX", status: "Go for launch",
                missionName: "Crew-12", missionDescription: "ISS Expedition 75/76 rotation.",
                rocketName: "Falcon 9", destination: "ISS"
            )
        ]
    }

    private static func heroKpForecast(now: Date) -> [KpForecastDay] {
        let day: TimeInterval = 86_400
        return [
            KpForecastDay(date: now,                            maxKp: 4.33, gScale: "G0"),
            KpForecastDay(date: now.addingTimeInterval(day),    maxKp: 5.00, gScale: "G1"),
            KpForecastDay(date: now.addingTimeInterval(day * 2), maxKp: 6.00, gScale: "G2"),
        ]
    }

    private static func heroSolarWind(now: Date) -> SolarWind {
        // 30 samples × 2 minutes = trailing hour. Plenty of resolution for
        // the sparkline; bigger windows just slow launch in screenshot mode.
        let history: [SolarWindSample] = (0..<30).map { i in
            let t = now.addingTimeInterval(-Double(i) * 120)
            let speed = 480.0 + sin(Double(i) * .pi / 7) * 32
            let bz = -3.2 + cos(Double(i) * .pi / 5) * 4
            return SolarWindSample(time: t, speedKmS: speed, bzNT: bz)
        }
        return SolarWind(
            observedAt: now, speedKmS: 488, densityP: 6.4,
            temperatureK: 142_000, bzNT: -4.1, btNT: 8.7,
            history: history
        )
    }

    private static func heroWWV(now: Date) -> WWVBulletin {
        WWVBulletin(
            issuedAt: now.addingTimeInterval(-15 * 60),
            solarFlux: 168, aIndex: 22, kIndex: 4,
            geomagSummary: "Geomagnetic field has been at unsettled to active levels.",
            propagationSummary: "Aurora activity is likely at high latitudes. HF signals on polar paths may be degraded.",
            rawText: "WWV 21Z 2026 May 25"
        )
    }

    private static func heroXRay(now: Date) -> XRayState {
        // 72 samples × 20 minutes = trailing 24h. Matches the panel's
        // 24-hour window without paying for thousands of sub-pixel points.
        let history: [XRaySample] = (0..<72).map { i in
            let t = now.addingTimeInterval(-Double(i) * 20 * 60)
            let base = -6.0 + sin(Double(i) * .pi / 24) * 0.7
            return XRaySample(time: t, flux: pow(10.0, base + Double(i % 7) * 0.05))
        }
        return XRayState(
            currentFlux: 1.4e-6, currentClass: "C1.4",
            peakFlux24h: 3.2e-5, peakClass24h: "M3.2",
            rScale: "R1", observedAt: now,
            history: history
        )
    }

    private static func heroIonosondes(now: Date) -> [IonosondeStation] {
        [
            IonosondeStation(name: "BC840", latitude: 40.0, longitude: -105.3,
                             fof2MHz: 8.3, mufMHz: 21.4, observedAt: now,
                             distanceKm: 720),
            IonosondeStation(name: "AL945", latitude: 64.9, longitude: -147.7,
                             fof2MHz: 5.1, mufMHz: 14.6, observedAt: now,
                             distanceKm: 3_180),
            IonosondeStation(name: "PA836", latitude: 34.8, longitude: -120.6,
                             fof2MHz: 9.2, mufMHz: 24.0, observedAt: now,
                             distanceKm: 1_360),
        ]
    }

    private static func heroBandConditions() -> [BandCondition] {
        [
            BandCondition(band: "80m", centerMHz: 3.6,  dayStatus: "Poor",   nightStatus: "Good",   reason: "Daytime D-layer absorption"),
            BandCondition(band: "40m", centerMHz: 7.1,  dayStatus: "Fair",   nightStatus: "Good",   reason: nil),
            BandCondition(band: "20m", centerMHz: 14.2, dayStatus: "Good",   nightStatus: "Fair",   reason: nil),
            BandCondition(band: "17m", centerMHz: 18.1, dayStatus: "Good",   nightStatus: "Fair",   reason: nil),
            BandCondition(band: "15m", centerMHz: 21.2, dayStatus: "Good",   nightStatus: "Poor",   reason: "MUF dropping after sunset"),
            BandCondition(band: "12m", centerMHz: 24.9, dayStatus: "Fair",   nightStatus: "Closed", reason: nil),
            BandCondition(band: "10m", centerMHz: 28.4, dayStatus: "Fair",   nightStatus: "Closed", reason: nil),
            BandCondition(band: "6m",  centerMHz: 50.1, dayStatus: "Closed", nightStatus: "Closed", reason: "No Es"),
        ]
    }

    private static func heroPOTA(now: Date) -> [POTASpot] {
        func spot(_ id: Int, _ act: String, _ ref: String, _ name: String,
                  _ freq: Double, _ mode: String, _ ago: TimeInterval,
                  _ loc: String, _ dist: Double?, _ az: Double?) -> POTASpot {
            POTASpot(spotId: id, activator: act, parkRef: ref, parkName: name,
                     frequencyKHz: freq, mode: mode,
                     spotTime: now.addingTimeInterval(-ago),
                     latitude: nil, longitude: nil,
                     locationDesc: loc, comments: nil,
                     distanceKm: dist, azimuthDeg: az)
        }
        return [
            spot(101, "W4ABC", "K-0567", "Great Smoky Mountains NP",     14_252.0, "SSB",  4 * 60,  "US-TN", 2_350, 108),
            spot(102, "VE3DEF", "VE-0123", "Algonquin Provincial Park",  18_158.0, "CW",   8 * 60,  "CA-ON", 2_010,  78),
            spot(103, "K9GHI", "K-0033", "Yellowstone NP",                 7_044.0, "FT8", 11 * 60,  "US-WY",   180, 215),
            spot(104, "N5JKL", "K-2233", "Big Bend NP",                  14_074.0, "FT8", 18 * 60,  "US-TX", 1_780, 168),
            spot(105, "WA7MNO", "K-0044", "Olympic NP",                  21_310.0, "SSB", 26 * 60,  "US-WA",   880, 268),
        ]
    }

    private static func heroSOTA(now: Date) -> [SOTASpot] {
        func spot(_ id: Int, _ act: String, _ code: String, _ details: String,
                  _ freq: Double, _ mode: String, _ ago: TimeInterval) -> SOTASpot {
            SOTASpot(spotId: id, activator: act, summitCode: code,
                     summitDetails: details, frequencyKHz: freq, mode: mode,
                     spotTime: now.addingTimeInterval(-ago), comments: nil)
        }
        return [
            spot(201, "W7PQR", "W7M/BH-001", "Granite Peak, 3901m",     14_062.0, "CW",   6 * 60),
            spot(202, "K6STU", "W6/SS-001",  "Mount Whitney, 4421m",   14_342.0, "SSB", 13 * 60),
            spot(203, "VE6VWX", "VE6/RA-001", "Mount Robson, 3954m",   18_092.0, "CW",  21 * 60),
            spot(204, "W0YZA", "W0M/MN-001", "Mount Massive, 4398m",   21_062.0, "CW",  35 * 60),
        ]
    }

    private static func heroDX(now: Date) -> [DXSpot] {
        func spot(_ dx: String, _ spotter: String, _ freq: Double, _ info: String?, _ ago: TimeInterval) -> DXSpot {
            DXSpot(dxCallsign: dx, spotter: spotter, frequencyKHz: freq,
                   info: info, spotTime: now.addingTimeInterval(-ago))
        }
        return [
            spot("3D2AG", "DL1ABC", 14_023.0, "Fiji on 20m CW, 599",        2 * 60),
            spot("VK9CZ", "K2DEF",  18_075.0, "Cocos-Keeling DX-pedition", 6 * 60),
            spot("TX5S",  "JA3GHI", 21_032.0, "Marquesas, big pile-up",    9 * 60),
            spot("HK0/W4JKL", "EA5MNO", 24_905.0, "San Andres",             14 * 60),
            spot("YJ0VK", "W6PQR", 28_018.0, "Vanuatu — workable West",    18 * 60),
            spot("9N1AA", "OH2STU", 14_212.0, "Nepal, slow QSB",            24 * 60),
            spot("FT8WW", "VE3VWX", 18_109.0, "Crozet — EU window open",   31 * 60),
            spot("PJ2T",  "K1YZA",  21_295.0, "Curaçao multi-multi",        47 * 60),
        ]
    }
}
