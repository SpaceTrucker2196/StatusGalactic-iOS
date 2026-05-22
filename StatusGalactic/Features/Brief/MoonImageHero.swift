import SwiftUI

/// Square hero image whose moon glyph matches the current lunar phase.
/// Lives at the top of the Moon section in the brief.
///
/// SF Symbols ships proper `moonphase.*` glyphs that already track the
/// real terminator geometry per phase, so we use them on a cosmic
/// gradient + procedural starfield rather than fetching a remote image
/// (which would force a network call on every brief render and break
/// without internet).
struct MoonImageHero: View {
    let moon: Moon

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [
                    GalacticPalette.twilightPurple,
                    GalacticPalette.cosmicBlack
                ],
                center: .center, startRadius: 20, endRadius: 320
            )
            Starfield()
            Image(systemName: symbolName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(28)
                .foregroundStyle(Color(white: 0.95))
                .shadow(color: .white.opacity(0.35), radius: 12)

            VStack {
                Spacer()
                HStack(spacing: 8) {
                    Text(moon.phaseName.uppercased())
                        .font(.firaCode(.caption, weight: .bold))
                        .foregroundStyle(GalacticPalette.neonCyan)
                        .neonGlow(GalacticPalette.neonCyan, intensity: 4)
                    Spacer()
                    Text("\(Int(moon.illuminationPct.rounded()))% lit")
                        .font(.firaCode(.caption, weight: .semibold))
                        .foregroundStyle(GalacticPalette.peach)
                        .monospacedDigit()
                }
                .padding(10)
                .background(.black.opacity(0.35))
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(GalacticPalette.neonPurple.opacity(0.45), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Moon phase \(moon.phaseName), \(Int(moon.illuminationPct.rounded())) percent illuminated."
        )
    }

    /// Maps our phase-name strings to SF Symbols. The system glyphs match
    /// the real terminator geometry for each phase, so picking by name is
    /// faithful.
    private var symbolName: String {
        let n = moon.phaseName.lowercased()
        if n.contains("new")              { return "moonphase.new.moon" }
        if n.contains("waxing crescent")  { return "moonphase.waxing.crescent" }
        if n.contains("first quarter")    { return "moonphase.first.quarter" }
        if n.contains("waxing gibbous")   { return "moonphase.waxing.gibbous" }
        if n.contains("full")             { return "moonphase.full.moon" }
        if n.contains("waning gibbous")   { return "moonphase.waning.gibbous" }
        if n.contains("last quarter")     { return "moonphase.last.quarter" }
        if n.contains("waning crescent")  { return "moonphase.waning.crescent" }
        return "moon"
    }
}

/// Cheap procedural starfield. Seeds from the day so stars stay stable
/// across re-renders inside a session (they shift slowly day to day,
/// which reads as "real sky" rather than twinkly noise).
private struct Starfield: View {
    var body: some View {
        Canvas { context, size in
            var rng = SeededRNG(seed: UInt64(Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0))
            for _ in 0..<80 {
                let x = CGFloat(rng.nextDouble()) * size.width
                let y = CGFloat(rng.nextDouble()) * size.height
                let r = 0.5 + CGFloat(rng.nextDouble()) * 1.5
                let alpha = 0.25 + rng.nextDouble() * 0.6
                let rect = CGRect(x: x, y: y, width: r, height: r)
                context.fill(Path(ellipseIn: rect),
                             with: .color(.white.opacity(alpha)))
            }
        }
        .allowsHitTesting(false)
    }
}

/// Tiny deterministic PRNG (splitmix64-derived). Avoids `Double.random`
/// to keep the starfield stable per day rather than re-randomized every
/// SwiftUI body() pass.
private struct SeededRNG {
    var state: UInt64
    init(seed: UInt64) {
        state = seed &+ 0x9E3779B97F4A7C15
        if state == 0 { state = 1 }
    }
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
    mutating func nextDouble() -> Double {
        Double(next() >> 11) / Double(1 << 53)
    }
}
