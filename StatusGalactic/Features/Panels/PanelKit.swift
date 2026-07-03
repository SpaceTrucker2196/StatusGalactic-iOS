import SwiftUI
import WidgetKit

/// Every panel in Galactic — the *same unit* that renders as an iPad grid
/// tile and as a home-screen widget. Adding a new panel type = one case
/// here + a `PanelView` renderer that answers the four sizes.
///
/// Order here defines both the widget bundle's default order and the iPad
/// grid's initial layout.
public enum PanelKind: String, CaseIterable, Identifiable, Hashable, Codable {
    case brief
    case solarTerrestrial
    case tides
    // Placeholder cases for future factoring passes (Earth, Space, Sun, …).
    // Each becomes real when its `PanelView` renderer lands.

    public var id: String { rawValue }

    /// Human-readable label used in widget pickers and grid headers.
    public var displayName: String {
        switch self {
        case .brief:            return "Brief"
        case .solarTerrestrial: return "Solar-Terrestrial"
        case .tides:            return "Tides"
        }
    }
}

/// One of four fixed sizes. Mirrors WidgetKit's supported families 1:1 so
/// the same `PanelView` code can render into a widget or into an iPad grid
/// tile without a special case.
///
///   `.small` — 1×1  · systemSmall
///   `.wide`  — 2×1  · systemMedium
///   `.tall`  — 1×2  · (no direct widget family; iPad grid only for now)
///   `.large` — 2×2  · systemLarge
public enum PanelSize: String, CaseIterable, Identifiable, Hashable, Codable {
    case small
    case wide
    case tall
    case large

    public var id: String { rawValue }

    /// Column × row span in grid units. Used by `PanelGrid` for packing.
    public var span: (cols: Int, rows: Int) {
        switch self {
        case .small: return (1, 1)
        case .wide:  return (2, 1)
        case .tall:  return (1, 2)
        case .large: return (2, 2)
        }
    }
}

extension WidgetFamily {
    /// Map a WidgetKit family to the panel-size the shared renderer expects.
    /// `.systemExtraLarge` (iPad-only 4×2) collapses to `.large` for now —
    /// we'll teach panels an XL variant when the first one needs it.
    var panelSize: PanelSize {
        switch self {
        case .systemSmall:      return .small
        case .systemMedium:     return .wide
        case .systemLarge:      return .large
        case .systemExtraLarge: return .large
        default:                return .small
        }
    }
}
