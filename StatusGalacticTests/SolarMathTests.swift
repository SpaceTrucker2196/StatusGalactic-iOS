import XCTest
@testable import StatusGalactic

final class SolarMathTests: XCTestCase {

    /// La Crosse, WI on 2026-05-19: backend (skyfield) reports
    /// sunrise 5:35 AM CDT (10:35 UTC), sunset 8:28 PM CDT (01:28 UTC next day).
    /// SolarMath should be within ~2 minutes of those values.
    func testLaCrosseMayDay() throws {
        let tz = TimeZone(identifier: "America/Chicago")!
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        let day = cal.date(from: DateComponents(year: 2026, month: 5, day: 19))!

        let result = SolarMath.sunriseSunset(
            on: day,
            latitude: 43.80,
            longitude: -91.20,
            timezone: tz
        )
        let sunrise = try XCTUnwrap(result.sunrise)
        let sunset = try XCTUnwrap(result.sunset)

        // Expected times (UTC).
        let isoFormatter = ISO8601DateFormatter()
        let expectedSunrise = isoFormatter.date(from: "2026-05-19T10:35:00Z")!
        let expectedSunset = isoFormatter.date(from: "2026-05-20T01:28:00Z")!

        let sunriseDelta = abs(sunrise.timeIntervalSince(expectedSunrise))
        let sunsetDelta = abs(sunset.timeIntervalSince(expectedSunset))

        XCTAssertLessThan(sunriseDelta, 180, "sunrise off by \(sunriseDelta) s")
        XCTAssertLessThan(sunsetDelta, 180, "sunset off by \(sunsetDelta) s")
    }

    /// At the equator the day length should be very close to 12 hours year-round.
    func testEquatorDayLengthRoughly12Hours() throws {
        let tz = TimeZone(identifier: "UTC")!
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        for month in [1, 4, 7, 10] {
            let day = cal.date(from: DateComponents(year: 2026, month: month, day: 15))!
            let result = SolarMath.sunriseSunset(on: day, latitude: 0, longitude: 0, timezone: tz)
            let sr = try XCTUnwrap(result.sunrise)
            let ss = try XCTUnwrap(result.sunset)
            let hours = ss.timeIntervalSince(sr) / 3600
            XCTAssertEqual(hours, 12, accuracy: 0.2, "month \(month) day length \(hours)")
        }
    }

    /// Sunrise must precede sunset in temperate latitudes outside polar conditions.
    func testOrderingHolds() throws {
        let tz = TimeZone(identifier: "America/Chicago")!
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        let day = cal.date(from: DateComponents(year: 2026, month: 12, day: 21))!
        let result = SolarMath.sunriseSunset(on: day, latitude: 43.80, longitude: -91.20, timezone: tz)
        let sr = try XCTUnwrap(result.sunrise)
        let ss = try XCTUnwrap(result.sunset)
        XCTAssertLessThan(sr, ss)
    }
}
