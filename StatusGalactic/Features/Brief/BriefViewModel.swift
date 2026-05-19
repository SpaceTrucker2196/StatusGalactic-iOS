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
    var marineZone: String = ""
    var selectedCallsign: String?

    func load(client: BriefAPIClient, location: CLLocation?, tz: String) async {
        state = .loading
        do {
            let brief: Brief
            if let call = selectedCallsign, !call.isEmpty {
                brief = try await client.fetchBrief(
                    call: call,
                    zone: marineZone.isEmpty ? nil : marineZone,
                    tz: tz
                )
            } else if let loc = location {
                brief = try await client.fetchBrief(
                    lat: loc.coordinate.latitude,
                    lng: loc.coordinate.longitude,
                    zone: marineZone.isEmpty ? nil : marineZone,
                    tz: tz
                )
            } else {
                state = .error(
                    "No location available. Allow Location Services in Settings, or pick a callsign."
                )
                return
            }
            state = .loaded(brief, fetchedAt: Date())
        } catch let api as BriefAPIError {
            state = .error(api.errorDescription ?? "Unknown error")
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
