import Foundation
import CoreLocation
import MapKit

/// Thin wrapper around MKMapItem to deep-link into Apple Maps for navigation
/// or pin display. iOS-only (MapKit's launch APIs are not available on watchOS).
enum MapsLauncher {

    /// Open Apple Maps with driving directions from the user's current location
    /// to the given coordinate.
    static func openDirections(
        to coordinate: CLLocationCoordinate2D,
        name: String? = nil
    ) {
        let item = mapItem(at: coordinate, name: name)
        item.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }

    /// Open Apple Maps with a pin dropped at the given coordinate (no
    /// directions). Useful for "show me where this callsign last beaconed."
    static func show(
        at coordinate: CLLocationCoordinate2D,
        name: String? = nil
    ) {
        let item = mapItem(at: coordinate, name: name)
        item.openInMaps(launchOptions: nil)
    }

    private static func mapItem(
        at coordinate: CLLocationCoordinate2D,
        name: String?
    ) -> MKMapItem {
        let placemark = MKPlacemark(coordinate: coordinate)
        let item = MKMapItem(placemark: placemark)
        if let name { item.name = name }
        return item
    }
}
