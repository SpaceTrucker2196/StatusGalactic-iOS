import SwiftUI
import WidgetKit

struct BriefWidget: Widget {
    let kind: String = "io.river.statusgalactic.briefWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BriefWidgetProvider()) { entry in
            BriefWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Galactic Brief")
        .description("Current weather, sun events, and space weather at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
