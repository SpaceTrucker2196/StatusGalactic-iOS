import Foundation

/// Apparent sidereal time at a given moment and observer longitude.
///
/// Uses Meeus (12.4) for Greenwich Mean Sidereal Time, then adds the
/// observer's east-positive geodetic longitude to get Local Sidereal Time.
/// Equation of equinoxes is omitted — accuracy is sub-arcsecond for our
/// "display the LST on the brief footer" use case.
struct SiderealClock {
    let when: Date
    /// East-positive observer longitude in degrees.
    let longitudeEastDeg: Double

    /// Julian Date at `when`.
    var julianDate: Double { JulianDate.from(when) }

    /// Greenwich Mean Sidereal Time, in degrees, mod 360.
    var gmstDegrees: Double {
        let jd = julianDate
        let T = JulianDate.centuriesFromJ2000(jd)
        let theta = 280.46061837
            + 360.98564736629 * (jd - JulianDate.j2000)
            + 0.000387933 * T * T
            - (T * T * T) / 38_710_000.0
        return theta.normalizedDegrees
    }

    /// Local Apparent Sidereal Time (we treat mean ≈ apparent here), degrees.
    var lstDegrees: Double {
        (gmstDegrees + longitudeEastDeg).normalizedDegrees
    }

    /// LST in decimal hours.
    var lstHours: Double { lstDegrees / 15.0 }

    /// LST formatted as HH:MM:SS.
    var lstFormatted: String {
        let h = lstHours
        let totalSeconds = Int((h * 3600.0).rounded())
        let hh = (totalSeconds / 3600) % 24
        let mm = (totalSeconds % 3600) / 60
        let ss = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hh, mm, ss)
    }

    /// GMST formatted as HH:MM:SS.
    var gmstFormatted: String {
        let totalSeconds = Int(((gmstDegrees / 15.0) * 3600.0).rounded())
        let hh = (totalSeconds / 3600) % 24
        let mm = (totalSeconds % 3600) / 60
        let ss = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hh, mm, ss)
    }
}
