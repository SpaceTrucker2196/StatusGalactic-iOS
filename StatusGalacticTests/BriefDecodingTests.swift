import XCTest
@testable import StatusGalactic

final class ModelStructTests: XCTestCase {

    func testBriefRoundTripsThroughJSON() throws {
        let original = Brief(
            when: Date(timeIntervalSince1970: 1747656000),
            lat: 43.8,
            lng: -91.2,
            timezone: "America/Chicago",
            locationName: "La Crosse, WI",
            earth: EarthWeather(
                locationName: "La Crosse, WI",
                periods: [
                    WeatherPeriod(
                        name: "Today",
                        shortForecast: "Rain showers",
                        temperature: 60,
                        temperatureUnit: "F",
                        isDaytime: true,
                        wind: "15 mph NW",
                        detailedForecast: nil
                    )
                ]
            ),
            marine: nil,
            space: SpaceWeather(
                solarFlux: 105,
                kpIndex: 4.0,
                kpStatus: "unsettled",
                auroraLikely: false,
                hfSummary: "Fair to good",
                observedAt: nil
            ),
            sun: nil,
            moon: Moon(phaseName: "Waxing Crescent", phaseAngleDeg: 40, illuminationPct: 12),
            planets: [Planet(body: "Sun", sign: "Taurus", degree: 28.3, retrograde: false)],
            launches: [],
            errors: [:]
        )

        let data = try JSONEncoder().encode(original)
        let round = try JSONDecoder().decode(Brief.self, from: data)

        XCTAssertEqual(round.locationName, original.locationName)
        XCTAssertEqual(round.earth?.periods.first?.temperature, 60)
        XCTAssertEqual(round.space?.kpStatus, "unsettled")
        XCTAssertEqual(round.moon?.phaseName, "Waxing Crescent")
        XCTAssertEqual(round.planets.first?.body, "Sun")
    }

    /// Once we add a new field we want it to ride through JSON without
    /// silently dropping. Anything that fails this test is one missing
    /// CodingKey entry away from data loss.
    func testBriefRoundTripsHFAndActivityFields() throws {
        let original = Brief(
            when: Date(timeIntervalSince1970: 1747656000),
            lat: 43.8,
            lng: -91.2,
            timezone: "UTC",
            locationName: nil,
            earth: nil,
            marine: nil,
            space: nil,
            sun: nil,
            moon: nil,
            planets: [],
            launches: [],
            activeRegions: [
                ActiveRegion(
                    region: 4443, location: "S16E23",
                    latitude: -16, longitude: 23,
                    area: 250, numberOfSpots: 6,
                    magClass: "Beta-Gamma", spotClass: "Cao",
                    observedAt: nil
                )
            ],
            flareProbability: FlareProbability(
                issuedAt: nil, cClassPct: 60, mClassPct: 25, xClassPct: 5, protonEventPct: 5
            ),
            kpForecast: [KpForecastDay(date: Date(), maxKp: 4, gScale: "G0")],
            solarWind: SolarWind(
                observedAt: Date(), speedKmS: 450, densityP: 4.2,
                temperatureK: 100_000, bzNT: -3.0, btNT: 5.0
            ),
            wwvBulletin: WWVBulletin(
                issuedAt: nil, solarFlux: 114, aIndex: 5, kIndex: 2,
                geomagSummary: "quiet", propagationSummary: "no storms",
                rawText: "..."
            ),
            cmes: [],
            solarOutlook: [],
            xRay: XRayState(
                currentFlux: 5e-7, currentClass: "B5.0",
                peakFlux24h: 1.2e-5, peakClass24h: "M1.2",
                rScale: "R1", observedAt: Date()
            ),
            proton: ProtonState(fluxPfu: 0.5, sScale: "S0", observedAt: Date()),
            ionosondes: [],
            aurora: AuroraForecast(
                observedAt: Date(), forecastFor: Date(),
                localProbabilityPct: 24, globalMaxPct: 60
            ),
            bandConditions: [
                BandCondition(band: "20m", centerMHz: 14.2,
                              dayStatus: "Good", nightStatus: "Fair", reason: nil)
            ],
            potaSpots: [],
            sotaSpots: [],
            dxSpots: [],
            solarCycle: [],
            weatherAlerts: [
                WeatherAlert(
                    alertId: "urn:oid:1", event: "Tornado Warning",
                    severity: "Extreme", certainty: "Observed", urgency: "Immediate",
                    headline: "tornado!", description: nil, instruction: "take cover",
                    areaDesc: "La Crosse", onsetAt: nil, expiresAt: nil,
                    senderName: "NWS La Crosse"
                )
            ],
            magneticDeclination: MagneticDeclination(
                latitude: 43.8, longitude: -91.2,
                declinationDeg: 1.85, inclinationDeg: 70.2, totalFieldNT: 53_500,
                modelDate: 2026.5, model: "WMM-2025",
                observedAt: Date(timeIntervalSince1970: 1747656000)
            ),
            errors: [:]
        )

        let data = try JSONEncoder().encode(original)
        let round = try JSONDecoder().decode(Brief.self, from: data)

        XCTAssertEqual(round.activeRegions.first?.magClass, "Beta-Gamma")
        XCTAssertEqual(round.flareProbability?.xClassPct, 5)
        XCTAssertEqual(round.kpForecast.first?.gScale, "G0")
        XCTAssertEqual(round.solarWind?.bzNT, -3.0)
        XCTAssertEqual(round.wwvBulletin?.solarFlux, 114)
        XCTAssertEqual(round.xRay?.rScale, "R1")
        XCTAssertEqual(round.proton?.sScale, "S0")
        XCTAssertEqual(round.aurora?.localProbabilityPct, 24)
        XCTAssertEqual(round.bandConditions.first?.band, "20m")
        XCTAssertEqual(round.weatherAlerts.first?.severity, "Extreme")
        XCTAssertEqual(round.magneticDeclination?.declinationDeg, 1.85)
        XCTAssertEqual(round.magneticDeclination?.formatted, "1.9°E")
    }
}
