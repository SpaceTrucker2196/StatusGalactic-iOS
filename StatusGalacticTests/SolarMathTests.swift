import XCTest
@testable import StatusGalactic

final class SunEventsTests: XCTestCase {

    /// La Crosse 2026-05-19: skyfield/NOAA reference sunrise 10:35 UTC,
    /// sunset 01:28 UTC next day. Our approximation within 3 min.
    func testLaCrosseMayDay() throws {
        let tz = TimeZone(identifier: "America/Chicago")!
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        let day = cal.date(from: DateComponents(year: 2026, month: 5, day: 19))!

        let (sunrise, sunset) = SunEvents.sunriseAndSunset(
            on: day,
            latitude: 43.80,
            longitude: -91.20,
            timezone: tz
        )
        let sr = try XCTUnwrap(sunrise)
        let ss = try XCTUnwrap(sunset)

        let iso = ISO8601DateFormatter()
        let expectedSr = iso.date(from: "2026-05-19T10:35:00Z")!
        let expectedSs = iso.date(from: "2026-05-20T01:28:00Z")!

        XCTAssertLessThan(abs(sr.timeIntervalSince(expectedSr)), 180)
        XCTAssertLessThan(abs(ss.timeIntervalSince(expectedSs)), 180)
    }

    func testTwilightOrdering() throws {
        let tz = TimeZone(identifier: "America/Chicago")!
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        let day = cal.date(from: DateComponents(year: 2026, month: 5, day: 19))!

        let events = SunEvents.compute(
            when: day,
            latitude: 43.80,
            longitude: -91.20,
            timezoneName: "America/Chicago"
        )

        let astroDawn = try XCTUnwrap(events.astronomicalDawnUtc)
        let nauticalDawn = try XCTUnwrap(events.nauticalDawnUtc)
        let civilDawn = try XCTUnwrap(events.civilDawnUtc)
        let sunrise = try XCTUnwrap(events.sunriseUtc)
        let sunset = try XCTUnwrap(events.sunsetUtc)
        let civilDusk = try XCTUnwrap(events.civilDuskUtc)
        let nauticalDusk = try XCTUnwrap(events.nauticalDuskUtc)
        let astroDusk = try XCTUnwrap(events.astronomicalDuskUtc)

        XCTAssertLessThan(astroDawn, nauticalDawn)
        XCTAssertLessThan(nauticalDawn, civilDawn)
        XCTAssertLessThan(civilDawn, sunrise)
        XCTAssertLessThan(sunrise, sunset)
        XCTAssertLessThan(sunset, civilDusk)
        XCTAssertLessThan(civilDusk, nauticalDusk)
        XCTAssertLessThan(nauticalDusk, astroDusk)
    }
}

final class MoonPhaseTests: XCTestCase {

    /// 2026-05-19 ~12 UTC: backend skyfield reports waxing crescent ~12% illum.
    /// Our hand-rolled formulas within ~2%.
    func testMayCrescent() throws {
        let iso = ISO8601DateFormatter()
        let when = iso.date(from: "2026-05-19T12:00:00Z")!
        let moon = MoonPhase.compute(when: when)
        XCTAssertEqual(moon.phaseName, "Waxing Crescent")
        XCTAssertEqual(moon.illuminationPct, 12, accuracy: 3)
    }
}

final class PlanetsTests: XCTestCase {

    /// Sun's geocentric ecliptic longitude on 2026-05-19 is ~28° Taurus per
    /// skyfield. Our mean-element approximation should match within ~1°.
    func testSunPositionMatchesBackend() throws {
        let iso = ISO8601DateFormatter()
        let when = iso.date(from: "2026-05-19T12:00:00Z")!
        let planets = Planets.compute(when: when)
        let sun = planets.first(where: { $0.body == "Sun" })!
        XCTAssertEqual(sun.sign, "Taurus")
        XCTAssertEqual(sun.degree, 28.3, accuracy: 1.5)
    }

    func testAllBodiesPresent() throws {
        let planets = Planets.compute(when: Date())
        XCTAssertEqual(planets.count, 10)
        let bodies = Set(planets.map(\.body))
        XCTAssertTrue(bodies.isSuperset(of: ["Sun", "Moon", "Mercury", "Pluto"]))
    }
}
