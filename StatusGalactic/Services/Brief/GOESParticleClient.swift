import Foundation

/// GOES soft X-ray + integral proton flux feeds from NOAA SWPC.
///
///   xrays-1-day.json:           one entry per minute per energy band
///                               ("0.05-0.4nm" and "0.1-0.8nm"). Long-wave
///                               (1-8Å, "0.1-0.8nm") is the canonical class.
///   integral-protons-1-day.json: integral flux per energy band (we want
///                                ">=10 MeV").
struct GOESParticleClient {
    let session: URLSession
    let userAgent: String

    init(session: URLSession = .shared, userAgent: String) {
        self.session = session
        self.userAgent = userAgent
    }

    static let xrayURL = URL(string:
        "https://services.swpc.noaa.gov/json/goes/primary/xrays-1-day.json"
    )!
    static let protonURL = URL(string:
        "https://services.swpc.noaa.gov/json/goes/primary/integral-protons-1-day.json"
    )!

    func fetchXRay() async throws -> XRayState? {
        let data = try await session.getData(from: Self.xrayURL, userAgent: userAgent, timeout: 8)
        guard let rows = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return nil
        }
        // Filter to long-wave (1-8Å) only.
        let longWave = rows.filter { ($0["energy"] as? String) == "0.1-0.8nm" }
        guard !longWave.isEmpty else { return nil }
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let f2 = ISO8601DateFormatter()
        f2.formatOptions = [.withInternetDateTime]
        var current: (flux: Double, when: Date)?
        var peak: (flux: Double, when: Date)?
        var samples: [XRaySample] = []
        samples.reserveCapacity(longWave.count)
        for row in longWave {
            guard let flux = row["flux"] as? Double, flux > 0 else { continue }
            let when = (row["time_tag"] as? String).flatMap { f.date(from: $0) ?? f2.date(from: $0) }
            guard let when else { continue }
            samples.append(XRaySample(time: when, flux: flux))
            if current == nil || when > current!.when { current = (flux, when) }
            if peak == nil || flux > peak!.flux { peak = (flux, when) }
        }
        guard let current, let peak else { return nil }
        samples.sort { $0.time < $1.time }
        return XRayState(
            currentFlux: current.flux,
            currentClass: Self.classify(flux: current.flux),
            peakFlux24h: peak.flux,
            peakClass24h: Self.classify(flux: peak.flux),
            rScale: Self.rScale(forPeakFlux: peak.flux),
            observedAt: current.when,
            history: samples
        )
    }

    func fetchProton() async throws -> ProtonState? {
        let data = try await session.getData(from: Self.protonURL, userAgent: userAgent, timeout: 8)
        guard let rows = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return nil
        }
        let filtered = rows.filter { ($0["energy"] as? String)?.contains(">=10") == true }
        guard let last = filtered.last,
              let flux = last["flux"] as? Double
        else { return nil }
        let parser = ISO8601DateFormatter()
        parser.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        let when = (last["time_tag"] as? String).flatMap { parser.date(from: $0) ?? plain.date(from: $0) } ?? Date()
        return ProtonState(
            fluxPfu: flux,
            sScale: Self.sScale(forFlux: flux),
            observedAt: when
        )
    }

    /// Map a 1-8Å X-ray flux (W/m²) to its NOAA letter class. Conventions:
    ///   A < 1e-7, B < 1e-6, C < 1e-5, M < 1e-4, X ≥ 1e-4
    /// The trailing decimal is the leading-digit of the flux in that decade.
    static func classify(flux: Double) -> String {
        let bands: [(threshold: Double, letter: String)] = [
            (1e-4, "X"), (1e-5, "M"), (1e-6, "C"), (1e-7, "B"), (0, "A")
        ]
        for (threshold, letter) in bands {
            if flux >= threshold {
                let digit = threshold > 0 ? flux / threshold : flux / 1e-8
                return String(format: "%@%.1f", letter, digit)
            }
        }
        return "A0.0"
    }

    /// NOAA R-scale (Radio Blackout) from peak 1-8Å flux.
    static func rScale(forPeakFlux flux: Double) -> String {
        switch flux {
        case 2e-3...:  return "R5"
        case 1e-3..<2e-3: return "R4"
        case 1e-4..<1e-3: return "R3"
        case 5e-5..<1e-4: return "R2"
        case 1e-5..<5e-5: return "R1"
        default:          return "R0"
        }
    }

    /// NOAA S-scale (Solar Radiation Storm) from ≥10 MeV proton flux (pfu).
    static func sScale(forFlux pfu: Double) -> String {
        switch pfu {
        case 1e5...:   return "S5"
        case 1e4..<1e5: return "S4"
        case 1e3..<1e4: return "S3"
        case 1e2..<1e3: return "S2"
        case 10..<1e2:  return "S1"
        default:        return "S0"
        }
    }
}
