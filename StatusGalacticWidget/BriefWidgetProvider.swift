import Foundation
import WidgetKit

struct BriefWidgetEntry: TimelineEntry {
    let date: Date
    let brief: Brief?
    let errorMessage: String?
}

struct BriefWidgetProvider: TimelineProvider {

    func placeholder(in context: Context) -> BriefWidgetEntry {
        BriefWidgetEntry(date: Date(), brief: nil, errorMessage: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (BriefWidgetEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }
        Task {
            let entry = await loadEntry(now: Date())
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BriefWidgetEntry>) -> Void) {
        Task {
            let now = Date()
            let entry = await loadEntry(now: now)
            let next = Calendar.current.date(byAdding: .minute, value: 30, to: now) ?? now.addingTimeInterval(1800)
            let timeline = Timeline(entries: [entry], policy: .after(next))
            completion(timeline)
        }
    }

    private func loadEntry(now: Date) async -> BriefWidgetEntry {
        let config = ClientConfig()
        // Pull a real User-Agent from the shared store if the App Group is
        // entitled and the main app has saved one; otherwise stay on the
        // widget's hardcoded default.
        if let sharedUA = SharedDefaults.store.string(forKey: SharedDefaults.Keys.userAgent),
           !sharedUA.isEmpty {
            config.userAgent = sharedUA
        } else {
            config.userAgent = WidgetConfig.userAgent
        }
        // Last known location from the most recent main-app brief, if any.
        let coords = SharedDefaults.readLocation()
            ?? (lat: WidgetConfig.defaultLatitude, lng: WidgetConfig.defaultLongitude)

        let builder = BriefBuilder(config: config)
        let brief = await builder.build(
            lat: coords.lat,
            lng: coords.lng,
            marineZone: nil,
            timezone: TimeZone.current.identifier
        )
        return BriefWidgetEntry(date: now, brief: brief, errorMessage: nil)
    }
}
