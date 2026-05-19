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
            // Refresh every 30 minutes. WidgetKit treats this as a hint; the OS
            // throttles. Brief data is mostly hourly-stable so 30 min is fine.
            let next = Calendar.current.date(byAdding: .minute, value: 30, to: now) ?? now.addingTimeInterval(1800)
            let timeline = Timeline(entries: [entry], policy: .after(next))
            completion(timeline)
        }
    }

    private func loadEntry(now: Date) async -> BriefWidgetEntry {
        let client = BriefAPIClient(baseURL: WidgetConfig.defaultServerURL)
        do {
            let brief = try await client.fetchBrief(
                lat: WidgetConfig.defaultLatitude,
                lng: WidgetConfig.defaultLongitude,
                tz: TimeZone.current.identifier
            )
            return BriefWidgetEntry(date: now, brief: brief, errorMessage: nil)
        } catch let api as BriefAPIError {
            return BriefWidgetEntry(date: now, brief: nil, errorMessage: api.errorDescription)
        } catch {
            return BriefWidgetEntry(date: now, brief: nil, errorMessage: error.localizedDescription)
        }
    }
}
