import SwiftUI

/// SF Symbol name lookups for the various entities the brief renders.
/// Keep all the symbol picking here so the views stay declarative.
enum GalacticSymbols {

    // MARK: - Weather conditions

    /// Best SF Symbol name for a free-text NWS short-forecast string. Falls
    /// back through a list of keywords; isDaytime swaps day/night variants.
    static func weatherSymbol(for shortForecast: String, isDaytime: Bool) -> String {
        let text = shortForecast.lowercased()

        if text.contains("thunder") || text.contains("lightning") {
            return "cloud.bolt.rain.fill"
        }
        if text.contains("snow") {
            return "cloud.snow.fill"
        }
        if text.contains("sleet") || text.contains("freezing") || text.contains("ice") {
            return "cloud.sleet.fill"
        }
        if text.contains("rain") || text.contains("shower") || text.contains("drizzle") {
            return "cloud.rain.fill"
        }
        if text.contains("fog") || text.contains("mist") || text.contains("haze") {
            return "cloud.fog.fill"
        }
        if text.contains("wind") {
            return "wind"
        }
        if text.contains("partly") || text.contains("mostly cloudy") {
            return isDaytime ? "cloud.sun.fill" : "cloud.moon.fill"
        }
        if text.contains("cloud") || text.contains("overcast") {
            return "cloud.fill"
        }
        if text.contains("hot") {
            return "thermometer.sun.fill"
        }
        if text.contains("cold") || text.contains("frigid") {
            return "thermometer.snowflake"
        }
        if text.contains("clear") || text.contains("sunny") || text.contains("fair") {
            return isDaytime ? "sun.max.fill" : "moon.stars.fill"
        }
        return isDaytime ? "sun.max.fill" : "moon.fill"
    }

    // MARK: - Celestial bodies

    /// SF Symbol name for a brief.planets entry (best-effort; SF Symbols
    /// has no per-planet glyph, so we lean on themed icons).
    static func bodySymbol(for body: String) -> String {
        switch body.lowercased() {
        case "sun":      return "sun.max.fill"
        case "moon":     return "moon.fill"
        case "mercury":  return "circle.fill"
        case "venus":    return "sparkle"
        case "mars":     return "circle.fill"
        case "jupiter":  return "circle.hexagongrid.fill"
        case "saturn":   return "circle.dotted"
        case "uranus":   return "circle.dashed"
        case "neptune":  return "drop.fill"
        case "pluto":    return "circle"
        default:         return "sparkle"
        }
    }

    /// Themed tint color for a body, drawn from `GalacticPalette`.
    static func bodyColor(for body: String) -> Color {
        switch body.lowercased() {
        case "sun":     return GalacticPalette.sun
        case "moon":    return GalacticPalette.moon
        case "mercury": return GalacticPalette.peach
        case "venus":   return GalacticPalette.hotPink
        case "mars":    return GalacticPalette.mars
        case "jupiter": return GalacticPalette.jupiter
        case "saturn":  return GalacticPalette.saturn
        case "uranus":  return GalacticPalette.neonCyan
        case "neptune": return GalacticPalette.electricBlue
        case "pluto":   return GalacticPalette.neonPurple
        default:        return GalacticPalette.moon
        }
    }

    // MARK: - Moon phase

    /// Moon phase SF Symbol by phase name (matches the names emitted by
    /// `MoonPhase.compute`).
    static func moonPhaseSymbol(for name: String) -> String {
        switch name.lowercased() {
        case let s where s.contains("new"):               return "moonphase.new.moon"
        case let s where s.contains("waxing crescent"):   return "moonphase.waxing.crescent"
        case let s where s.contains("first quarter"):     return "moonphase.first.quarter"
        case let s where s.contains("waxing gibbous"):    return "moonphase.waxing.gibbous"
        case let s where s.contains("full"):              return "moonphase.full.moon"
        case let s where s.contains("waning gibbous"):    return "moonphase.waning.gibbous"
        case let s where s.contains("last quarter"):      return "moonphase.last.quarter"
        case let s where s.contains("waning crescent"):   return "moonphase.waning.crescent"
        default:                                          return "moon"
        }
    }

    // MARK: - Sun events

    static let sunrise: String = "sunrise.fill"
    static let sunset: String = "sunset.fill"
    static let goldenHour: String = "sun.haze.fill"
    static let civilTwilight: String = "sun.dust.fill"
    static let nauticalTwilight: String = "sun.min.fill"
    static let astronomicalDusk: String = "moon.stars.fill"

    // MARK: - Space weather

    static let aurora: String = "sparkles"
    static let solarFlux: String = "antenna.radiowaves.left.and.right"
    static let kpIndex: String = "waveform.path.ecg"
}
