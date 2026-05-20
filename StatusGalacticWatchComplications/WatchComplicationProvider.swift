import Foundation
import WidgetKit

struct WatchComplicationEntry: TimelineEntry {
    let date: Date
    let brief: Brief?
}

struct WatchComplicationProvider: TimelineProvider {

    func placeholder(in context: Context) -> WatchComplicationEntry {
        WatchComplicationEntry(date: Date(), brief: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (WatchComplicationEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }
        Task {
            let entry = await loadEntry(now: Date())
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchComplicationEntry>) -> Void) {
        Task {
            let now = Date()
            let entry = await loadEntry(now: now)
            // Watch complications refresh more often than phone widgets.
            let next = Calendar.current.date(byAdding: .minute, value: 20, to: now)
                ?? now.addingTimeInterval(1200)
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }

    private func loadEntry(now: Date) async -> WatchComplicationEntry {
        let config = ClientConfig()
        if let sharedUA = SharedDefaults.store.string(forKey: SharedDefaults.Keys.userAgent),
           !sharedUA.isEmpty {
            config.userAgent = sharedUA
        } else {
            config.userAgent = WatchComplicationConfig.userAgent
        }
        let coords = SharedDefaults.readLocation()
            ?? (lat: WatchComplicationConfig.defaultLatitude,
                lng: WatchComplicationConfig.defaultLongitude)

        let builder = BriefBuilder(config: config)
        let brief = await builder.build(
            lat: coords.lat,
            lng: coords.lng,
            marineZone: nil,
            timezone: TimeZone.current.identifier
        )
        return WatchComplicationEntry(date: now, brief: brief)
    }
}

enum WatchComplicationConfig {
    static let defaultLatitude: Double = 43.80
    static let defaultLongitude: Double = -91.20
    static let userAgent: String =
        "StatusGalactic-Watch/0.2 (+https://github.com/SpaceTrucker2196/StatusGalactic-iOS)"
}
