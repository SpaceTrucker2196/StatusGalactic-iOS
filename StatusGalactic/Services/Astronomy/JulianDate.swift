import Foundation

enum JulianDate {
    static let j2000: Double = 2451545.0

    /// Julian Date for the given Date (TT≈UT for our accuracy bounds).
    static func from(_ date: Date) -> Double {
        2440587.5 + date.timeIntervalSince1970 / 86400.0
    }

    /// Centuries since J2000.0.
    static func centuriesFromJ2000(_ jd: Double) -> Double {
        (jd - j2000) / 36525.0
    }
}

extension Double {
    var toRadians: Double { self * .pi / 180 }
    var toDegrees: Double { self * 180 / .pi }

    /// Normalize an angle in degrees into [0, 360).
    var normalizedDegrees: Double {
        let v = self.truncatingRemainder(dividingBy: 360)
        return v < 0 ? v + 360 : v
    }
}
