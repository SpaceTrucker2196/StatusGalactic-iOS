import Foundation

/// Defensive fallback for the widget extension.
///
/// The widget normally reads the user's last known coordinates + User-Agent
/// from the `group.com.spacetrucker.statusgalactic` App Group suite, which
/// the main app populates on every successful brief load (see
/// `Services/Brief/SharedDefaults.swift`). When the suite isn't resolvable
/// — e.g. a fresh install before the first brief lands, or an unusual
/// entitlement-provisioning quirk — `BriefWidgetProvider` falls back to
/// these constants so the widget still renders meaningful content.
enum WidgetConfig {
    static let defaultLatitude: Double = 43.80
    static let defaultLongitude: Double = -91.20
    static let userAgent: String =
        "StatusGalactic-iOS-Widget/0.2 (+https://github.com/SpaceTrucker2196/StatusGalactic-iOS)"
}
