import Foundation
import CoreLocation

@Observable
final class BriefViewModel {
    enum LoadState {
        case idle
        case loading
        /// `isStale` is true when the rendered data is a cached snapshot
        /// from a previous run / refresh and a fresh fetch hasn't yet
        /// landed. The UI renders stale data in muted gray.
        case loaded(Brief, fetchedAt: Date, isStale: Bool)
        case error(String)
    }

    var state: LoadState = .idle
    /// True while a refresh is in flight. The previous `.loaded` brief is
    /// kept rendered while this is true so the UI doesn't blank out for
    /// 10+ seconds on a slow network.
    var isRefreshing: Bool = false
    var marineZone: String = ""
    var selectedCallsign: String?

    init() {
        // Surface the most recent cached brief immediately as stale. If
        // there is none, stay in .idle until first load completes.
        if let cached = BriefCache.load() {
            state = .loaded(cached.brief, fetchedAt: cached.fetchedAt, isStale: true)
        }
    }

    func load(
        config: ClientConfig,
        location: CLLocation?,
        tz: String,
        notifications: NotificationManager? = nil
    ) async {
        if case .loaded = state {
            // Keep the brief visible at its current freshness while we
            // refresh. The gray "stale" treatment only ever fires from
            // BriefViewModel.init when the cache is being shown before
            // the very first fetch lands — refreshes after that don't
            // gray the screen.
            isRefreshing = true
        } else {
            state = .loading
        }
        defer { isRefreshing = false }

        let lat: Double
        let lng: Double

        if let call = selectedCallsign, !call.isEmpty {
            // Resolve callsign to coordinates via aprs.fi.
            if config.aprsAPIKey.isEmpty {
                state = .error("Set your aprs.fi API key in Settings to look up callsigns.")
                return
            }
            let aprs = APRSClient(userAgent: config.userAgent, apiKey: config.aprsAPIKey)
            do {
                let fix = try await aprs.locate(call)
                lat = fix.lat
                lng = fix.lng
            } catch {
                state = .error("APRS lookup for \(call) failed: \(error.localizedDescription)")
                return
            }
        } else if let loc = location {
            lat = loc.coordinate.latitude
            lng = loc.coordinate.longitude
        } else {
            state = .error(
                "No location available. Allow Location Services in Settings, or pick a callsign."
            )
            return
        }

        let builder = BriefBuilder(config: config)
        let brief = await builder.build(
            lat: lat,
            lng: lng,
            marineZone: marineZone.isEmpty ? nil : marineZone,
            timezone: tz
        )
        let now = Date()
        state = .loaded(brief, fetchedAt: now, isStale: false)
        BriefCache.save(brief: brief, fetchedAt: now)

        // Mirror to App Group + reschedule golden/astro reminders against
        // the freshest known coordinates. Both used to live in BriefView's
        // refresh() — pulled in here so ContentView's scene-phase trigger
        // gets the same effect without re-implementing.
        SharedDefaults.writeLocation(lat: brief.lat, lng: brief.lng)
        if let notifications {
            await notifications.reschedule(latitude: brief.lat, longitude: brief.lng)
            await notifications.evaluateSpaceWeather(brief: brief)
        }
    }
}
