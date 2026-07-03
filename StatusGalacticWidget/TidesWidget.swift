import SwiftUI
import WidgetKit

/// Tide table widget — a thin WidgetKit shell over the shared
/// `TidesPanel`. View code lives in
/// `StatusGalactic/Features/Panels/Tides/TidesPanel.swift` so this widget
/// and the iPad `PanelGrid` render the same pixels. Off-coast users see
/// a gentle empty state so the widget still installs from the gallery.
struct TidesWidget: Widget {
    let kind: String = "io.river.statusgalactic.tidesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BriefWidgetProvider()) { entry in
            TidesEntryView(entry: entry)
                .containerBackground(GalacticPalette.cosmicSky, for: .widget)
        }
        .configurationDisplayName("Tides")
        .description("Next high/low tide predictions from the nearest NOAA station.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private struct TidesEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: BriefWidgetEntry

    var body: some View {
        TidesPanel(
            size: family.panelSize,
            brief: entry.brief,
            referenceDate: entry.date
        )
    }
}
