import Foundation
import CoreLocation

@Observable
final class BriefViewModel {
    enum LoadState {
        case idle
        case loading
        case loaded(Brief, fetchedAt: Date)
        case error(String)
    }

    var state: LoadState = .idle
    /// True while a refresh is in flight. The previous `.loaded` brief is
    /// kept rendered while this is true so the UI doesn't blank out for
    /// 10+ seconds on a slow network.
    var isRefreshing: Bool = false
    var marineZone: String = ""
    var selectedCallsign: String?

    func load(
        config: ClientConfig,
        location: CLLocation?,
        tz: String,
        notifications: NotificationManager? = nil
    ) async {
        if case .loaded = state {
            // Keep the existing brief visible while we refresh.
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
        state = .loaded(brief, fetchedAt: Date())
        if let notifications {
            await notifications.evaluateSpaceWeather(brief: brief)
        }
    }
}
