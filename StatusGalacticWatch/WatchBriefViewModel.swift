import Foundation
import CoreLocation

@Observable
final class WatchBriefViewModel {
    enum LoadState {
        case idle
        case loading
        case loaded(Brief, fetchedAt: Date)
        case error(String)
    }

    var state: LoadState = .idle

    func load(config: ClientConfig, location: CLLocation?) async {
        state = .loading
        guard let loc = location else {
            state = .error("No location.")
            return
        }
        let builder = BriefBuilder(config: config)
        let brief = await builder.build(
            lat: loc.coordinate.latitude,
            lng: loc.coordinate.longitude,
            marineZone: config.defaultMarineZone.isEmpty ? nil : config.defaultMarineZone,
            timezone: TimeZone.current.identifier
        )
        state = .loaded(brief, fetchedAt: Date())
    }
}
