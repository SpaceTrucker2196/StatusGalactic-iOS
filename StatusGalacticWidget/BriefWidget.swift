import SwiftUI
import WidgetKit

/// Galactic brief widget — a thin WidgetKit shell over the shared
/// `BriefPanel`. All view code lives in
/// `StatusGalactic/Features/Panels/Brief/BriefPanel.swift` so this widget
/// and the iPad `PanelGrid` render the same pixels.
struct BriefWidget: Widget {
    let kind: String = "io.river.statusgalactic.briefWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BriefWidgetProvider()) { entry in
            BriefEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Galactic Brief")
        .description("Current weather, sun events, and space weather at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

/// Environment-reading shim: WidgetKit exposes the family the system
/// chose via `@Environment(\.widgetFamily)`, which isn't accessible from
/// the outer `entry` closure. This view reads it and delegates to the
/// shared `BriefPanel`.
private struct BriefEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: BriefWidgetEntry

    var body: some View {
        BriefPanel(
            size: family.panelSize,
            brief: entry.brief,
            referenceDate: entry.date,
            errorMessage: entry.errorMessage
        )
    }
}
