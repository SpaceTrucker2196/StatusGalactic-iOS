import Foundation

/// Moon phase from Meeus's "Astronomical Algorithms" (chapter 47), keeping the
/// largest periodic terms in moon longitude. Sun longitude uses Meeus 25 with
/// the equation-of-center correction.
///
/// Accuracy: phase angle within ~0.5° (good to the minute for phase events
/// and well within the labels' tolerances).
enum MoonPhase {

    static func compute(when: Date) -> Moon {
        let jd = JulianDate.from(when)
        let T = JulianDate.centuriesFromJ2000(jd)

        let sunLon = sunEclipticLongitude(T: T)
        let moonLon = moonEclipticLongitude(T: T)

        let phaseAngle = (moonLon - sunLon).normalizedDegrees
        let illumination = (1 - cos(phaseAngle.toRadians)) / 2 * 100

        return Moon(
            phaseName: phaseName(phaseAngle: phaseAngle),
            phaseAngleDeg: phaseAngle,
            illuminationPct: illumination
        )
    }

    /// Sun's geocentric ecliptic longitude at a given Julian time-in-centuries.
    static func sunEclipticLongitude(T: Double) -> Double {
        let L0 = 280.46646 + 36000.76983 * T + 0.0003032 * T * T
        let MDeg = 357.52911 + 35999.05029 * T - 0.0001537 * T * T
        let M = MDeg.toRadians

        let c1 = (1.914602 - 0.004817 * T - 0.000014 * T * T) * sin(M)
        let c2 = (0.019993 - 0.000101 * T) * sin(2 * M)
        let c3 = 0.000289 * sin(3 * M)
        let C = c1 + c2 + c3

        return (L0 + C).normalizedDegrees
    }

    /// Moon's geocentric ecliptic longitude. Major periodic terms only.
    static func moonEclipticLongitude(T: Double) -> Double {
        let Lp = 218.3164477 + 481267.88123421 * T - 0.0015786 * T * T
        let D = (297.8501921 + 445267.1114034 * T - 0.0018819 * T * T).toRadians
        let M = (357.5291092 + 35999.0502909 * T - 0.0001536 * T * T).toRadians
        let Mp = (134.9633964 + 477198.8675055 * T + 0.0087414 * T * T).toRadians
        let F = (93.2720950 + 483202.0175233 * T - 0.0036539 * T * T).toRadians

        // Periodic-term contributions in degrees, grouped to keep the type
        // checker happy.
        var dLon: Double = 0
        dLon += 6.288774 * sin(Mp)
        dLon += 1.274027 * sin(2 * D - Mp)
        dLon += 0.658314 * sin(2 * D)
        dLon += 0.213618 * sin(2 * Mp)
        dLon -= 0.185116 * sin(M)
        dLon -= 0.114332 * sin(2 * F)
        dLon += 0.058793 * sin(2 * D - 2 * Mp)
        dLon += 0.057066 * sin(2 * D - M - Mp)
        dLon += 0.053322 * sin(2 * D + Mp)
        dLon += 0.045758 * sin(2 * D - M)
        dLon -= 0.040923 * sin(M - Mp)
        dLon -= 0.034720 * sin(D)
        dLon -= 0.030383 * sin(M + Mp)

        return (Lp + dLon).normalizedDegrees
    }

    private static func phaseName(phaseAngle: Double) -> String {
        switch phaseAngle {
        case ..<5, 355...:    return "New Moon"
        case 5..<85:          return "Waxing Crescent"
        case 85..<95:         return "First Quarter"
        case 95..<175:        return "Waxing Gibbous"
        case 175..<185:       return "Full Moon"
        case 185..<265:       return "Waning Gibbous"
        case 265..<275:       return "Last Quarter"
        case 275..<355:       return "Waning Crescent"
        default:              return "Unknown"
        }
    }
}
