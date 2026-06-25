import Foundation

/// Identifies a single Brief tab section. The raw value is the
/// persistence key — once a case is added, never rename its raw value
/// or stored orderings will lose track of it (a missing case in the
/// persisted list is treated as removed; a missing default case is
/// appended at the end so newly-shipped sections show up automatically
/// after an app update).
enum BriefSection: String, CaseIterable, Hashable, Codable, Identifiable {
    case weatherAlerts        = "weather_alerts"
    case animatedSun          = "animated_sun"
    case stormScale           = "storm_scale"
    case sun                  = "sun"
    case locationHeader       = "location_header"
    case earthWeather         = "earth_weather"
    case riverStage           = "river_stage"
    case marineWeather        = "marine_weather"
    case tides                = "tides"
    case spaceWeather         = "space_weather"
    case sunImagery           = "sun_imagery"
    case auroraForecast       = "aurora_forecast"
    case moon                 = "moon"
    case planets              = "planets"
    case crewedLaunches       = "crewed_launches"
    case launches             = "launches"
    case crewed               = "crewed"
    case constellations       = "constellations"
    case apod                 = "apod"
    case mars                 = "mars"
    case neos                 = "neos"
    case interstellar         = "interstellar"
    case solarSeismic         = "solar_seismic"
    case earthquakes          = "earthquakes"
    case siderealFooter       = "sidereal_footer"
    case errors               = "errors"

    var id: String { rawValue }

    /// Human-readable label used by the (future) settings reorder UI.
    /// Kept here so the catalog of cases stays in one place.
    var displayName: String {
        switch self {
        case .weatherAlerts:    return "Active Alerts"
        case .animatedSun:      return "Animated Sun"
        case .stormScale:       return "Storm Scale"
        case .sun:              return "Sun"
        case .locationHeader:   return "Location"
        case .earthWeather:     return "Earth Weather"
        case .riverStage:       return "River Stage"
        case .marineWeather:    return "Marine Weather"
        case .tides:            return "Tides"
        case .spaceWeather:     return "Space Weather"
        case .sunImagery:       return "Sun Imagery"
        case .auroraForecast:   return "Aurora Forecast"
        case .moon:             return "Moon"
        case .planets:          return "Planetary Positions"
        case .crewedLaunches:   return "Upcoming Crewed Launches"
        case .launches:         return "Upcoming Launches"
        case .crewed:           return "International Space Station"
        case .constellations:   return "Satellite Constellations"
        case .apod:             return "Astronomy Picture of the Day"
        case .mars:             return "Mars Weather"
        case .neos:             return "Near-Earth Objects"
        case .interstellar:     return "Interstellar Visitors"
        case .solarSeismic:     return "Solar ↔ Seismic"
        case .earthquakes:      return "Recent Earthquakes"
        case .siderealFooter:   return "Sidereal Footer"
        case .errors:           return "Source Errors"
        }
    }

    /// Default top-to-bottom order, matching what the brief used to
    /// render hard-coded. The persisted order falls back to this when
    /// nothing has been saved yet.
    static let defaultOrder: [BriefSection] = [
        .weatherAlerts,
        .animatedSun,
        .stormScale,
        .sun,
        .locationHeader,
        .earthWeather,
        .riverStage,
        .marineWeather,
        .tides,
        .spaceWeather,
        .sunImagery,
        .auroraForecast,
        .moon,
        .planets,
        .crewedLaunches,
        .launches,
        .crewed,
        .constellations,
        .apod,
        .mars,
        .neos,
        .interstellar,
        .solarSeismic,
        .earthquakes,
        .siderealFooter,
        .errors,
    ]

    /// Reconciles a persisted raw-value list with the current set of
    /// known cases: drops unknown / removed cases, then appends any new
    /// defaults at the end so future app versions never have to migrate.
    static func reconcile(persistedRawValues: [String]) -> [BriefSection] {
        let known = persistedRawValues.compactMap(BriefSection.init(rawValue:))
        let missing = defaultOrder.filter { !known.contains($0) }
        return known + missing
    }

    /// Translates a `.onMove` drag in a filtered "visible" subset back
    /// into a new full order. Invisible sections keep their relative
    /// positions; the moved section is placed so it sits "before" the
    /// same visible neighbour the user dragged it past (matching the
    /// semantics SwiftUI's `move(fromOffsets:toOffset:)` already uses
    /// for the non-filtered case). Returns `order` unchanged when the
    /// inputs are inconsistent — e.g. `source` is empty or points off
    /// the end of `visible`.
    static func moveInFullOrder(
        order: [BriefSection],
        visible: [BriefSection],
        from source: IndexSet,
        to destination: Int
    ) -> [BriefSection] {
        guard let visibleSource = source.first,
              visibleSource < visible.count else { return order }
        let moving = visible[visibleSource]

        var next = order
        guard let fullSourceIdx = next.firstIndex(of: moving) else { return order }

        let targetFullIdx: Int
        if destination >= visible.count {
            targetFullIdx = next.count
        } else {
            let anchor = visible[destination]
            targetFullIdx = next.firstIndex(of: anchor) ?? next.count
        }
        // Inline the SwiftUI `move(fromOffsets:toOffset:)` semantics so
        // this file stays Foundation-only (it's compiled into the
        // widget + watch targets too). `toOffset` is the index in the
        // *pre-move* array at which the element should be inserted.
        let item = next.remove(at: fullSourceIdx)
        let adjusted = targetFullIdx > fullSourceIdx
            ? targetFullIdx - 1
            : targetFullIdx
        next.insert(item, at: min(adjusted, next.count))
        return next
    }
}
