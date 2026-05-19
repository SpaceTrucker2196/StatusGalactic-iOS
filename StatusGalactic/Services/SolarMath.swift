import Foundation

/// Pure-Swift sunrise/sunset computation using NOAA's standard solar position
/// approximation (Spencer 1971 / NOAA Solar Calculator). Accurate to about
/// one minute for mid-latitudes — plenty for scheduling notifications.
///
/// The authoritative sunrise/sunset times for *display* come from the backend
/// (Skyfield + JPL DE421). This module exists only so the iOS app can plan
/// up to two weeks of golden-hour alerts without daily backend round-trips.
enum SolarMath {

    /// Returns sunrise and sunset UTC datetimes for the given local calendar
    /// day at the given coordinates. nil if the sun never rises or sets that
    /// day (polar conditions).
    static func sunriseSunset(
        on day: Date,
        latitude: Double,
        longitude: Double,
        timezone: TimeZone = .current
    ) -> (sunrise: Date?, sunset: Date?) {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timezone
        let comps = cal.dateComponents([.year, .month, .day], from: day)
        guard let year = comps.year, let month = comps.month, let dayOfMonth = comps.day else {
            return (nil, nil)
        }

        let dayOfYear = dayOfYear(year: year, month: month, day: dayOfMonth)
        let result = solarTimes(
            dayOfYear: dayOfYear,
            year: year,
            latitude: latitude,
            longitude: longitude
        )

        // Build UTC dates from the local-calendar-day midnight in UTC.
        var utcCal = Calendar(identifier: .gregorian)
        utcCal.timeZone = TimeZone(identifier: "UTC")!
        guard let midnightUTC = utcCal.date(from: DateComponents(
            year: year, month: month, day: dayOfMonth, hour: 0, minute: 0
        )) else {
            return (nil, nil)
        }

        let sunrise = result.sunriseMinutes.map { midnightUTC.addingTimeInterval($0 * 60) }
        let sunset = result.sunsetMinutes.map { midnightUTC.addingTimeInterval($0 * 60) }
        return (sunrise, sunset)
    }

    private static func dayOfYear(year: Int, month: Int, day: Int) -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let date = cal.date(from: DateComponents(year: year, month: month, day: day))!
        return cal.ordinality(of: .day, in: .year, for: date) ?? 1
    }

    private struct SolarResult {
        let sunriseMinutes: Double?
        let sunsetMinutes: Double?
    }

    private static func solarTimes(
        dayOfYear: Int,
        year: Int,
        latitude: Double,
        longitude: Double
    ) -> SolarResult {
        // Fractional year in radians (Spencer 1971).
        let n = Double(dayOfYear)
        let daysInYear = isLeapYear(year) ? 366.0 : 365.0
        let gamma = 2.0 * .pi / daysInYear * (n - 1.0)

        // Equation of time in minutes.
        let eqtime = 229.18 * (
            0.000075
                + 0.001868 * cos(gamma)
                - 0.032077 * sin(gamma)
                - 0.014615 * cos(2 * gamma)
                - 0.040849 * sin(2 * gamma)
        )

        // Solar declination in radians.
        let decl =
            0.006918
            - 0.399912 * cos(gamma)
            + 0.070257 * sin(gamma)
            - 0.006758 * cos(2 * gamma)
            + 0.000907 * sin(2 * gamma)
            - 0.002697 * cos(3 * gamma)
            + 0.001480 * sin(3 * gamma)

        // Hour angle for the sun at 90.833° zenith (includes refraction + solar disc).
        let latRad = latitude * .pi / 180.0
        let zenith = 90.833 * .pi / 180.0
        let cosH =
            (cos(zenith) - sin(latRad) * sin(decl))
            / (cos(latRad) * cos(decl))

        if cosH > 1.0 {
            return SolarResult(sunriseMinutes: nil, sunsetMinutes: nil) // sun never rises
        }
        if cosH < -1.0 {
            return SolarResult(sunriseMinutes: nil, sunsetMinutes: nil) // sun never sets
        }

        let haRad = acos(cosH)
        let haDeg = haRad * 180.0 / .pi

        // Sunrise/sunset in UTC minutes-from-midnight.
        let sunrise = 720.0 - 4.0 * (longitude + haDeg) - eqtime
        let sunset  = 720.0 - 4.0 * (longitude - haDeg) - eqtime

        return SolarResult(sunriseMinutes: sunrise, sunsetMinutes: sunset)
    }

    private static func isLeapYear(_ year: Int) -> Bool {
        (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
    }
}
