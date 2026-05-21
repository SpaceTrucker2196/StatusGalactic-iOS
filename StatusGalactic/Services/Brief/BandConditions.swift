import Foundation

/// Pure-compute synthesizer turning the existing space-weather snapshot into
/// per-band HF status labels mirroring the "20m: Good / 10m: Closed" tile
/// hams expect. No I/O. Heuristic — meant for at-a-glance triage, not
/// VOACAP-grade prediction.
enum BandConditions {

    /// Standard HF + 6m bands with a representative MHz for MUF comparison.
    static let table: [(band: String, mhz: Double)] = [
        ("80m", 3.7),
        ("60m", 5.35),
        ("40m", 7.15),
        ("30m", 10.12),
        ("20m", 14.2),
        ("17m", 18.1),
        ("15m", 21.2),
        ("12m", 24.9),
        ("10m", 28.5),
        ("6m",  50.2),
    ]

    static func evaluate(
        sfi: Double?,
        kp: Double?,
        rScale: String?,
        mufMHz: Double?
    ) -> [BandCondition] {
        // Storm-wide degraders short-circuit every band.
        let kpVal = kp ?? 0
        let geomag = kpVal >= 7 ? "G3 storm"
                  : kpVal >= 6 ? "G2 storm"
                  : kpVal >= 5 ? "G1 storm"
                  : nil
        let blackout: String? = {
            switch rScale {
            case "R5", "R4", "R3": return "\(rScale!) radio blackout"
            case "R2": return "R2 partial blackout"
            case "R1": return "R1 minor blackout"
            default:   return nil
            }
        }()
        let sfiVal = sfi ?? 70

        return table.map { entry in
            let (day, night, reason) = status(
                band: entry.band,
                mhz: entry.mhz,
                sfi: sfiVal,
                kp: kpVal,
                muf: mufMHz,
                geomag: geomag,
                blackout: blackout
            )
            return BandCondition(
                band: entry.band,
                centerMHz: entry.mhz,
                dayStatus: day,
                nightStatus: night,
                reason: reason
            )
        }
    }

    private static func status(
        band: String,
        mhz: Double,
        sfi: Double,
        kp: Double,
        muf: Double?,
        geomag: String?,
        blackout: String?
    ) -> (day: String, night: String, reason: String?) {
        // Hard cutoffs first.
        if let blackout, mhz <= 30 {
            // Radio blackouts attenuate HF most below 25 MHz on the sunlit side.
            return ("Poor", "Fair", blackout)
        }
        if let geomag, geomag.contains("G3") {
            return ("Poor", "Poor", geomag)
        }

        // Low bands: night-favored, MUF irrelevant (always below).
        if mhz < 8 {
            var night = "Good"
            var day = "Poor"
            if let geomag {
                night = "Fair"
                day = "Poor"
                return (day, night, geomag)
            }
            if sfi > 120 { day = "Fair" }
            return (day, night, nil)
        }

        // Mid/high bands: gated by SFI + MUF.
        let muf = muf ?? estimatedMUF(sfi: sfi)
        if mhz > muf * 1.05 {
            return ("Closed", "Closed", String(format: "Above MUF (%.0f MHz)", muf))
        }
        if mhz > muf * 0.85 {
            // Marginal — close to ceiling.
            return ("Fair", mhz < 12 ? "Fair" : "Poor", String(format: "Near MUF (%.0f MHz)", muf))
        }

        // SFI gating for higher bands.
        switch mhz {
        case ..<11:                            // 30m, 20m
            return ("Good", mhz < 11 ? "Good" : "Fair", geomag)
        case 11..<19:                           // 17m
            if sfi < 80 { return ("Fair", "Poor", "Low SFI \(Int(sfi))") }
            return ("Good", "Fair", geomag)
        case 19..<26:                           // 15m, 12m
            if sfi < 95 { return ("Fair", "Poor", "Low SFI \(Int(sfi))") }
            return ("Good", "Fair", geomag)
        case 26..<35:                           // 10m
            if sfi < 110 { return ("Fair", "Closed", "Low SFI \(Int(sfi))") }
            return ("Good", "Poor", geomag)
        default:                                // 6m and up — sporadic/event-driven
            if sfi < 150 { return ("Closed", "Closed", "Es-only band") }
            return ("Fair", "Closed", "F2 propagation rare; mostly Es/TEP")
        }
    }

    /// Rough MUF estimate from SFI when no ionosonde reading is available.
    /// Empirical formula tuned to mid-latitude daytime; treat as a floor.
    private static func estimatedMUF(sfi: Double) -> Double {
        // SFI 70 → ~14 MHz, SFI 150 → ~28 MHz, near-linear.
        let muf = 8 + (sfi - 60) * 0.18
        return max(7, min(35, muf))
    }
}
