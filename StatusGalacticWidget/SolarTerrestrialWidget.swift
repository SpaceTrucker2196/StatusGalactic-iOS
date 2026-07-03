import SwiftUI
import WidgetKit

/// Vaporwave reinterpretation of the classic hamqsl.com solar-terrestrial
/// propagation widget. Same shape (compact monospace data table + small
/// sun + status pills), rendered on the Spacetrucker cosmic-sky gradient
/// with neon-glow chrome and phosphor-green headers.
///
/// This is now a thin WidgetKit shell over `SolarPanel`. The actual view
/// code lives in `StatusGalactic/Features/Panels/Solar/SolarPanel.swift`
/// and is shared with the iPad `PanelGrid`. Reuses `BriefWidgetProvider`
/// so a single brief fetch feeds this widget and the others in the bundle.
struct SolarTerrestrialWidget: Widget {
    let kind: String = "io.river.statusgalactic.solarTerrestrialWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BriefWidgetProvider()) { entry in
            SolarTerrestrialEntryView(entry: entry)
                .containerBackground(GalacticPalette.cosmicSky, for: .widget)
        }
        .configurationDisplayName("Solar-Terrestrial")
        .description("HF propagation snapshot — SFI, Kp, X-ray, aurora, geomag.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

/// Environment-reading shim: WidgetKit exposes the size the system chose
/// via `@Environment(\.widgetFamily)`, which is not accessible from the
/// outer `entry` closure. This view reads it and delegates to the shared
/// `SolarPanel`.
private struct SolarTerrestrialEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: BriefWidgetEntry

    var body: some View {
        SolarPanel(
            size: family.panelSize,
            brief: entry.brief,
            referenceDate: entry.date
        )
    }
}
