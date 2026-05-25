import SwiftUI

/// Spacetrucker Galactic vaporwave palette.
///
/// The design language: a neon artifact from a future world. Deep cosmic
/// blacks and Prussian blues form the base. Magenta, hot pink, cyan, and
/// electric blue carry the data. Status, temperature, and Kp all use the
/// same set of named tokens so a redesign is one file and the Android
/// port mirrors it verbatim.
///
/// Token names like `deepPurple`/`twilightPurple` are retained for backward
/// compatibility; their color values map to deep Prussian blue shades.
enum GalacticPalette {

    // MARK: - Core neon

    static let neonMagenta  = Color(red: 1.00, green: 0.16, blue: 0.78)
    static let hotPink      = Color(red: 1.00, green: 0.40, blue: 0.80)
    static let neonCyan     = Color(red: 0.00, green: 0.94, blue: 1.00)
    static let electricBlue = Color(red: 0.30, green: 0.36, blue: 1.00)
    /// Blue-green CRT phosphor (P2-ish) used for section headers. Reads
    /// as a glowing oscilloscope trace.
    static let phosphorGreen = Color(red: 0.25, green: 1.00, blue: 0.78)
    /// Bright Prussian-blue accent. Name kept as `neonPurple` for legacy
    /// callsites; the actual color is now a saturated cobalt/Prussian.
    static let neonPurple   = Color(red: 0.18, green: 0.42, blue: 0.78)
    static let sunsetOrange = Color(red: 1.00, green: 0.42, blue: 0.21)
    static let peach        = Color(red: 1.00, green: 0.73, blue: 0.59)
    static let mint         = Color(red: 0.60, green: 0.97, blue: 0.78)

    // MARK: - Cosmic ground

    static let cosmicBlack  = Color(red: 0.01, green: 0.02, blue: 0.06)
    /// Deep Prussian blue (#001833). Name retained for backward compatibility.
    static let deepPurple   = Color(red: 0.00, green: 0.10, blue: 0.20)
    /// Mid Prussian blue (#0A3052). Name retained for backward compatibility.
    static let twilightPurple = Color(red: 0.04, green: 0.19, blue: 0.32)
    /// Dusty steel-blue (replaces the old dusty rose). Name retained.
    static let dustyRose    = Color(red: 0.20, green: 0.40, blue: 0.55)

    // MARK: - Status / activity scale

    static let calm   = neonCyan
    static let mild   = mint
    static let active = peach
    static let storm  = hotPink
    static let severe = neonMagenta

    // MARK: - Twilight bands (SunStrip)

    static let astronomicalDark     = cosmicBlack
    static let astronomicalTwilight = deepPurple
    static let nauticalTwilight     = twilightPurple
    static let civilTwilight        = dustyRose
    static let daylight             = peach

    // MARK: - Celestial bodies

    static let sun  = sunsetOrange
    static let moon = Color(red: 0.92, green: 0.85, blue: 1.00)
    static let mars = Color(red: 1.00, green: 0.36, blue: 0.30)
    static let jupiter = Color(red: 1.00, green: 0.80, blue: 0.55)
    static let saturn  = Color(red: 0.95, green: 0.72, blue: 0.45)

    // MARK: - Background gradients

    static let cosmicSky = LinearGradient(
        colors: [cosmicBlack, deepPurple, twilightPurple],
        startPoint: .top,
        endPoint: .bottom
    )

    static let neonHorizon = LinearGradient(
        colors: [neonMagenta, sunsetOrange, peach],
        startPoint: .leading,
        endPoint: .trailing
    )

    // MARK: - Mappers

    /// Kp activity color (0..9).
    static func kp(_ value: Double) -> Color {
        switch value {
        case ..<3:  return calm
        case ..<4:  return mild
        case ..<5:  return active
        case ..<6:  return storm
        default:    return severe
        }
    }

    /// Temperature color (°F). Cold cyan → hot magenta.
    static func temperature(_ f: Int) -> Color {
        switch f {
        case ..<10:  return electricBlue
        case ..<32:  return neonCyan
        case ..<50:  return mint
        case ..<70:  return peach
        case ..<85:  return sunsetOrange
        case ..<100: return hotPink
        default:     return neonMagenta
        }
    }

    /// Solar flux (10.7 cm). Higher = better HF.
    static func solarFlux(_ value: Double) -> Color {
        switch value {
        case 150...:    return mild
        case 100..<150: return active
        case 80..<100:  return storm
        default:        return severe
        }
    }

    /// Moon illumination as a glow color (warmer at full, cooler at new).
    static func moonIllumination(_ pct: Double) -> Color {
        let clamped = max(0, min(1, pct / 100))
        return moon.opacity(0.4 + 0.6 * clamped)
    }
}

// MARK: - Neon glow modifier

struct NeonGlow: ViewModifier {
    let color: Color
    let intensity: CGFloat

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.85), radius: intensity * 0.6)
            .shadow(color: color.opacity(0.45), radius: intensity * 1.8)
    }
}

extension View {
    /// Apply a soft neon glow in the given color.
    func neonGlow(_ color: Color = GalacticPalette.neonCyan, intensity: CGFloat = 6) -> some View {
        modifier(NeonGlow(color: color, intensity: intensity))
    }
}

// MARK: - Phosphor header

extension Text {
    /// Section-header styling — uppercased, slightly tracked, phosphor-green
    /// with a neon-glow blur to match the rest of the title chrome.
    func phosphorHeader() -> some View {
        self
            .font(.firaCode(.subheadline, weight: .bold))
            .textCase(.uppercase)
            .tracking(1.5)
            .foregroundStyle(GalacticPalette.phosphorGreen)
            .neonGlow(GalacticPalette.phosphorGreen, intensity: 5)
    }
}

/// Drop-in replacement for `Section(_ title:) { … }` that styles the
/// header with the phosphor-green glow used elsewhere in the brief
/// chrome. The result is a real `Section` so List / Form keep their
/// grouping semantics — wrapping in `some View` was tempting but loses
/// section grouping inside generated `_VariadicView_Children`.
struct PhosphorSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content

    init(_ title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    var body: some View {
        Section {
            content()
        } header: {
            Text(title).phosphorHeader()
        }
    }
}
