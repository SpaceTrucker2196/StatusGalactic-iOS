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
}
