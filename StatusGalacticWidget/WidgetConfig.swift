import Foundation

/// Hard-coded fallbacks for the widget extension.
///
/// Without an App Group entitlement, the widget cannot read the main app's
/// `UserDefaults.standard`. Until DEVELOPMENT_TEAM is configured and App
/// Groups are wired up, edit these defaults to match your home location.
enum WidgetConfig {
    static let defaultLatitude: Double = 43.80
    static let defaultLongitude: Double = -91.20
    static let userAgent: String =
        "StatusGalactic-iOS-Widget/0.2 (+https://github.com/SpaceTrucker2196/StatusGalactic-iOS)"
}
