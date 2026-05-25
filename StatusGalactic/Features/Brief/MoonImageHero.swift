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
                .overlay(
                    // Procedural maria — the dark basaltic plains that give
                    // the moon its "face." Drawn on top of the SF Symbol
                    // glyph, then masked to the moon disc so they only show
                    // where the symbol is lit. Fades to invisible when the
                    // phase is mostly dark (crescent) so we don't paint
                    // floating dark blobs on the sky.
                    MoonSurface()
                        .padding(28)
                        .opacity(mariaOpacity)
                        .allowsHitTesting(false)
                )

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

    /// Maria are most visible near full / gibbous and fade out toward
    /// new — there's not enough lit moon surface for them to read.
    private var mariaOpacity: Double {
        let lit = max(0, min(1, moon.illuminationPct / 100))
        // Below ~40% illumination, the phase shape is mostly terminator
        // and the dark patches would float on the sky.
        return lit < 0.4 ? 0 : (lit - 0.4) / 0.6 * 0.85
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

/// Procedural lunar maria — the dark patches that make the full moon
/// look like a face. Positions are taken from the real selenographic
/// chart projected to a unit disc; sizes are visually tuned, not exact.
private struct MoonSurface: View {
    /// (offset.x, offset.y, radius) — all in unit-disc coordinates where
    /// (0, 0) is moon center and 1.0 is the limb. Y is positive down to
    /// match SwiftUI's coordinate system; the maria appear on the
    /// near-side face of a full moon roughly as observers see them.
    private let maria: [(CGFloat, CGFloat, CGFloat)] = [
        (-0.28, -0.42, 0.22),   // Mare Imbrium (upper left)
        ( 0.05, -0.28, 0.16),   // Mare Serenitatis
        ( 0.30, -0.10, 0.18),   // Mare Tranquillitatis
        ( 0.58, -0.18, 0.10),   // Mare Crisium
        ( 0.38,  0.12, 0.13),   // Mare Fecunditatis
        ( 0.22,  0.30, 0.10),   // Mare Nectaris
        (-0.46,  0.04, 0.22),   // Oceanus Procellarum (large, left)
        (-0.30,  0.38, 0.12),   // Mare Humorum
        ( 0.02,  0.42, 0.10),   // Mare Nubium
    ]

    /// Bright impact rays from Tycho — small bright crater near the
    /// south pole. Rendered as a tiny highlight so the lower half
    /// doesn't read as featureless.
    private let highlights: [(CGFloat, CGFloat, CGFloat)] = [
        ( 0.00,  0.55, 0.05),   // Tycho crater
        (-0.10, -0.05, 0.04),   // Copernicus
    ]

    var body: some View {
        GeometryReader { geo in
            let r = min(geo.size.width, geo.size.height) / 2
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            ZStack {
                ForEach(0..<maria.count, id: \.self) { i in
                    let m = maria[i]
                    Circle()
                        .fill(Color(white: 0.35).opacity(0.55))
                        .frame(width: m.2 * r * 2, height: m.2 * r * 2)
                        .blur(radius: 1.5)
                        .position(
                            x: center.x + m.0 * r,
                            y: center.y + m.1 * r
                        )
                }
                ForEach(0..<highlights.count, id: \.self) { i in
                    let h = highlights[i]
                    Circle()
                        .fill(Color(white: 1.0).opacity(0.45))
                        .frame(width: h.2 * r * 2, height: h.2 * r * 2)
                        .blur(radius: 0.8)
                        .position(
                            x: center.x + h.0 * r,
                            y: center.y + h.1 * r
                        )
                }
            }
            // Clip to the moon disc so maria can't bleed past the limb.
            .mask(
                Circle()
                    .frame(width: r * 2, height: r * 2)
                    .position(center)
            )
        }
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
