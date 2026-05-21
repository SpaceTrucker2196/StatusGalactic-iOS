import Foundation

/// Geocentric ecliptic longitudes for Sun, Moon, and the eight planets plus
/// Pluto, computed from mean orbital elements with first-order equation-of-
/// center correction.
///
/// Accuracy bounds:
///   Sun:    < 0.01°
///   Moon:   < 0.5°  (Meeus major periodic terms)
///   Mercury, Venus: ~1-2° geocentric due to mean-element simplification
///   Mars:   ~1-3°
///   Jupiter-Pluto: ~0.5-2°
///
/// Adequate for "Mercury 4.47° Gemini" -style display. Sign assignment
/// is correct except near boundaries; the audit covers this trade-off.
enum Planets {

    static let bodyOrder = [
        "Sun", "Moon", "Mercury", "Venus", "Mars",
        "Jupiter", "Saturn", "Uranus", "Neptune", "Pluto"
    ]

    private struct Element {
        let a: Double          // semi-major axis (AU)
        let e: Double          // eccentricity
        let L0: Double         // mean longitude at J2000 (degrees)
        let rate: Double       // rate (degrees per century)
        let omegaBar: Double   // longitude of perihelion (degrees)
    }

    // Mean orbital elements, J2000 epoch. Heliocentric ecliptic.
    // (Standard values from NASA JPL / Meeus, simplified.)
    private static let elements: [String: Element] = [
        "Mercury": Element(a: 0.387098, e: 0.205635, L0: 252.250906, rate: 149474.072249, omegaBar: 77.45645),
        "Venus":   Element(a: 0.723330, e: 0.006773, L0: 181.979801, rate: 58519.213030,  omegaBar: 131.56371),
        "Earth":   Element(a: 1.000000, e: 0.016709, L0: 100.466449, rate: 35999.372852,  omegaBar: 102.93735),
        "Mars":    Element(a: 1.523688, e: 0.093405, L0: 355.433275, rate: 19140.299314,  omegaBar: 336.04084),
        "Jupiter": Element(a: 5.202561, e: 0.048498, L0:  34.351484, rate:  3034.905675,  omegaBar:  14.33121),
        "Saturn":  Element(a: 9.554747, e: 0.055546, L0:  50.077471, rate:  1222.113794,  omegaBar:  93.05678),
        "Uranus":  Element(a: 19.21814, e: 0.046381, L0: 314.055005, rate:   428.466998,  omegaBar: 173.00529),
        "Neptune": Element(a: 30.10957, e: 0.009456, L0: 304.348665, rate:   218.486200,  omegaBar:  48.12027),
        "Pluto":   Element(a: 39.48169, e: 0.248808, L0: 238.929038, rate:   145.207805,  omegaBar: 224.06676),
    ]

    /// Compute the zodiac sign / degree table for every body. No rise/set
    /// information — call `computeWithEphemeris(when:lat:lng:)` for that.
    static func compute(when: Date) -> [Planet] {
        computeInternal(when: when, lat: nil, lng: nil)
    }

    /// Same as `compute` but additionally fills in apparent RA/Dec, current
    /// altitude/azimuth, and the day's rise/transit/set events for the given
    /// observer. Pure compute — no I/O.
    static func computeWithEphemeris(when: Date, lat: Double, lng: Double) -> [Planet] {
        computeInternal(when: when, lat: lat, lng: lng)
    }

    private static func computeInternal(when: Date, lat: Double?, lng: Double?) -> [Planet] {
        let jd = JulianDate.from(when)
        let T = JulianDate.centuriesFromJ2000(jd)

        // Earth's heliocentric position drives geocentric conversion.
        let earth = elements["Earth"]!
        let (earthLon, earthR) = trueLonAndRadius(elem: earth, T: T)
        let earthX = earthR * cos(earthLon.toRadians)
        let earthY = earthR * sin(earthLon.toRadians)

        var out: [Planet] = []

        // Sun: geocentric longitude = Earth's heliocentric longitude + 180°.
        let sunGeoLon = (earthLon + 180.0).normalizedDegrees
        out.append(enrich("Sun", lon: sunGeoLon, when: when, lat: lat, lng: lng))

        // Moon: use the Meeus periodic-term series in MoonPhase.
        let moonLon = MoonPhase.moonEclipticLongitude(T: T)
        out.append(enrich("Moon", lon: moonLon, when: when, lat: lat, lng: lng))

        for name in ["Mercury", "Venus", "Mars", "Jupiter", "Saturn", "Uranus", "Neptune", "Pluto"] {
            guard let elem = elements[name] else { continue }
            let (lon, r) = trueLonAndRadius(elem: elem, T: T)
            let x = r * cos(lon.toRadians) - earthX
            let y = r * sin(lon.toRadians) - earthY
            let geoLon = atan2(y, x).toDegrees.normalizedDegrees
            out.append(enrich(name, lon: geoLon, when: when, lat: lat, lng: lng))
        }

        return out
    }

    /// Mean obliquity of the ecliptic at J2000 (degrees). Adequate for the
    /// "where is Jupiter going to be tonight" use-case — drift is ~46″/century.
    private static let obliquityDeg: Double = 23.4392911

    /// Wraps `planet(...)` with optional equatorial coords + rise/set
    /// computations when the observer is known.
    private static func enrich(
        _ body: String, lon eclipticLonDeg: Double,
        when: Date, lat: Double?, lng: Double?
    ) -> Planet {
        var p = planet(body, lon: eclipticLonDeg)

        // Equatorial coords (assumes β = 0 — ignores ecliptic latitude).
        let lambdaR = eclipticLonDeg.toRadians
        let epsR = Self.obliquityDeg.toRadians
        let ra = atan2(sin(lambdaR) * cos(epsR), cos(lambdaR)).toDegrees.normalizedDegrees
        let dec = asin(sin(lambdaR) * sin(epsR)).toDegrees
        p.rightAscensionHours = ra / 15.0
        p.declinationDeg = dec

        guard let lat, let lng else { return p }

        let clock = SiderealClock(when: when, longitudeEastDeg: lng)
        let lst = clock.lstDegrees
        let ha = ((lst - ra + 540).truncatingRemainder(dividingBy: 360)) - 180
        let phiR = lat.toRadians
        let decR = dec.toRadians
        let haR = ha.toRadians

        // Current altitude/azimuth.
        let sinAlt = sin(phiR) * sin(decR) + cos(phiR) * cos(decR) * cos(haR)
        let alt = asin(max(-1, min(1, sinAlt))).toDegrees
        let cosAlt = cos(alt.toRadians)
        let cosAz = cosAlt == 0
            ? 1.0
            : (sin(decR) - sin(alt.toRadians) * sin(phiR)) / (cosAlt * cos(phiR))
        var az = acos(max(-1, min(1, cosAz))).toDegrees
        if sin(haR) > 0 { az = 360 - az }
        p.altitudeDeg = alt
        p.azimuthDeg = az

        // Rise/set: standard altitude for planets ~ -0.5667° (refraction).
        // Moon uses -0.583° + parallax; Sun -0.833°. Close enough at this scale.
        let h0Deg: Double
        switch body {
        case "Sun":  h0Deg = -0.833
        case "Moon": h0Deg = 0.125     // average parallax minus refraction
        default:     h0Deg = -0.5667
        }
        let cosH0 = (sin(h0Deg.toRadians) - sin(phiR) * sin(decR)) / (cos(phiR) * cos(decR))
        if cosH0 > 1 {
            p.circumpolarState = "always_down"
        } else if cosH0 < -1 {
            p.circumpolarState = "always_up"
        } else {
            let H0 = acos(cosH0).toDegrees                  // 0..180°
            // Next transit: hour angle reaches 0 in (360 - HA_now) / siderealRate hours.
            // Sidereal day = 23.9344696 hours ⇒ 15.04108° / hour LST advance.
            let siderealRate = 360.0 / 23.9344696
            let hoursToTransit = ((-ha + 360).truncatingRemainder(dividingBy: 360)) / siderealRate
            let transit = when.addingTimeInterval(hoursToTransit * 3600)
            let half = (H0 / siderealRate) * 3600
            var rise = transit.addingTimeInterval(-half)
            var set  = transit.addingTimeInterval(+half)
            // Push past events forward one sidereal day so we always show the
            // *next* rise/set rather than ones that already happened today.
            let sidDay: TimeInterval = 23.9344696 * 3600
            if rise < when { rise = rise.addingTimeInterval(sidDay) }
            if set  < when { set  = set.addingTimeInterval(sidDay)  }
            p.riseAt = rise
            p.transitAt = transit
            p.setAt = set
        }
        return p
    }

    /// Heliocentric true longitude + heliocentric distance (AU) at the given
    /// time. First-order equation-of-center correction; ignores inclination
    /// for projection onto the ecliptic plane.
    private static func trueLonAndRadius(elem: Element, T: Double) -> (Double, Double) {
        let meanLon = (elem.L0 + elem.rate * T).normalizedDegrees
        let M = (meanLon - elem.omegaBar).normalizedDegrees.toRadians
        let e = elem.e
        // Equation of center to second order in e.
        let C =
            (2 * e - e * e * e / 4) * sin(M)
            + (1.25 * e * e) * sin(2 * M)
            + (13.0 / 12.0 * e * e * e) * sin(3 * M)
        let trueLon = (meanLon + C.toDegrees).normalizedDegrees
        // Heliocentric distance via the orbit equation.
        let v = M + C
        let r = elem.a * (1 - e * e) / (1 + e * cos(v))
        return (trueLon, r)
    }

    private static func planet(_ body: String, lon: Double) -> Planet {
        let (sign, degree) = signAndDegree(lon: lon)
        return Planet(body: body, sign: sign, degree: degree, retrograde: false)
    }

    static let signs = [
        "Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo",
        "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces"
    ]

    static func signAndDegree(lon: Double) -> (String, Double) {
        let n = lon.normalizedDegrees
        let idx = min(11, Int(n / 30))
        return (signs[idx], n - Double(idx) * 30)
    }
}
