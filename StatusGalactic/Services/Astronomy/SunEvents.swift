import Foundation

/// Sunrise / sunset / twilight / golden-hour computation using NOAA's standard
/// solar position approximation (Spencer 1971 / NOAA Solar Calculator).
///
/// Accuracy: ~1 minute for mid-latitudes for sunrise/sunset; twilight
/// transitions degrade further toward the poles but stay within ~5 minutes
/// for users below 60° latitude. Sufficient for a daily brief.
enum SunEvents {

    /// Compute the full SolarEvents struct for the local day enclosing `when`.
    static func compute(
        when: Date,
        latitude: Double,
        longitude: Double,
        timezoneName: String
    ) -> SolarEvents {
        let tz = TimeZone(identifier: timezoneName) ?? .current

        let sunrise = solarTime(at: when, latitude: latitude, longitude: longitude,
                                tz: tz, zenith: 90.833, ascending: true)
        let sunset = solarTime(at: when, latitude: latitude, longitude: longitude,
                               tz: tz, zenith: 90.833, ascending: false)

        let civilDawn = solarTime(at: when, latitude: latitude, longitude: longitude,
                                  tz: tz, zenith: 96.0, ascending: true)
        let civilDusk = solarTime(at: when, latitude: latitude, longitude: longitude,
                                  tz: tz, zenith: 96.0, ascending: false)
        let nauticalDawn = solarTime(at: when, latitude: latitude, longitude: longitude,
                                     tz: tz, zenith: 102.0, ascending: true)
        let nauticalDusk = solarTime(at: when, latitude: latitude, longitude: longitude,
                                     tz: tz, zenith: 102.0, ascending: false)
        let astroDawn = solarTime(at: when, latitude: latitude, longitude: longitude,
                                  tz: tz, zenith: 108.0, ascending: true)
        let astroDusk = solarTime(at: when, latitude: latitude, longitude: longitude,
                                  tz: tz, zenith: 108.0, ascending: false)

        let goldenMorningStart = sunrise.map { $0.addingTimeInterval(-10 * 60) }
        let goldenMorningEnd = sunrise.map { $0.addingTimeInterval(30 * 60) }
        let goldenEveningStart = sunset.map { $0.addingTimeInterval(-30 * 60) }
        let goldenEveningEnd = sunset.map { $0.addingTimeInterval(10 * 60) }

        return SolarEvents(
            timezone: timezoneName,
            sunriseUtc: sunrise,
            sunsetUtc: sunset,
            goldenMorningStartUtc: goldenMorningStart,
            goldenMorningEndUtc: goldenMorningEnd,
            goldenEveningStartUtc: goldenEveningStart,
            goldenEveningEndUtc: goldenEveningEnd,
            civilDawnUtc: civilDawn,
            civilDuskUtc: civilDusk,
            nauticalDawnUtc: nauticalDawn,
            nauticalDuskUtc: nauticalDusk,
            astronomicalDawnUtc: astroDawn,
            astronomicalDuskUtc: astroDusk
        )
    }

    /// Light-weight (sunrise, sunset) only. Used by the notification scheduler.
    static func sunriseAndSunset(
        on day: Date,
        latitude: Double,
        longitude: Double,
        timezone: TimeZone = .current
    ) -> (sunrise: Date?, sunset: Date?) {
        let rise = solarTime(at: day, latitude: latitude, longitude: longitude,
                             tz: timezone, zenith: 90.833, ascending: true)
        let set = solarTime(at: day, latitude: latitude, longitude: longitude,
                            tz: timezone, zenith: 90.833, ascending: false)
        return (rise, set)
    }

    // MARK: - Core algorithm

    private static func solarTime(
        at day: Date,
        latitude: Double,
        longitude: Double,
        tz: TimeZone,
        zenith: Double,
        ascending: Bool
    ) -> Date? {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        let comps = cal.dateComponents([.year, .month, .day], from: day)
        guard let year = comps.year, let month = comps.month, let dayOfMonth = comps.day else {
            return nil
        }

        let n = dayOfYear(year: year, month: month, day: dayOfMonth)
        let daysInYear = isLeapYear(year) ? 366.0 : 365.0
        let gamma = 2.0 * .pi / daysInYear * (Double(n) - 1.0)

        // Equation of time (minutes).
        let eqtime = 229.18 * (
            0.000075
                + 0.001868 * cos(gamma)
                - 0.032077 * sin(gamma)
                - 0.014615 * cos(2 * gamma)
                - 0.040849 * sin(2 * gamma)
        )

        // Solar declination (radians).
        let decl =
            0.006918
            - 0.399912 * cos(gamma)
            + 0.070257 * sin(gamma)
            - 0.006758 * cos(2 * gamma)
            + 0.000907 * sin(2 * gamma)
            - 0.002697 * cos(3 * gamma)
            + 0.001480 * sin(3 * gamma)

        let latRad = latitude.toRadians
        let zenRad = zenith.toRadians
        let cosH = (cos(zenRad) - sin(latRad) * sin(decl)) / (cos(latRad) * cos(decl))
        if cosH > 1.0 || cosH < -1.0 {
            return nil
        }
        let haDeg = acos(cosH).toDegrees

        let minutesFromMidnightUTC = ascending
            ? 720.0 - 4.0 * (longitude + haDeg) - eqtime
            : 720.0 - 4.0 * (longitude - haDeg) - eqtime

        var utcCal = Calendar(identifier: .gregorian)
        utcCal.timeZone = TimeZone(identifier: "UTC")!
        guard let midnightUTC = utcCal.date(from: DateComponents(
            year: year, month: month, day: dayOfMonth, hour: 0, minute: 0
        )) else { return nil }
        return midnightUTC.addingTimeInterval(minutesFromMidnightUTC * 60)
    }

    private static func dayOfYear(year: Int, month: Int, day: Int) -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        guard let date = cal.date(from: DateComponents(year: year, month: month, day: day)) else {
            return 1
        }
        return cal.ordinality(of: .day, in: .year, for: date) ?? 1
    }

    private static func isLeapYear(_ year: Int) -> Bool {
        (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
    }
}
