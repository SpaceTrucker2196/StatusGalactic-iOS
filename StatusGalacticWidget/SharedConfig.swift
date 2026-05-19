import Foundation

/// Hard-coded fallbacks for the widget extension.
///
/// Widget and app run in separate sandboxes; without an App Group entitlement
/// the widget cannot read `UserDefaults.standard` written by the main app.
///
/// To wire them together once a DEVELOPMENT_TEAM is configured:
///   1. Create App Group `group.io.river.statusgalactic` in Apple Developer.
///   2. Add the entitlement to both targets in `project.yml`.
///   3. Replace these defaults with `UserDefaults(suiteName: ...)` reads.
///
/// Until then, edit these constants or recompile with your real values.
enum WidgetConfig {
    static let defaultServerURL = URL(string: "http://localhost:8000")!

    // Default location used until App Groups land. La Crosse, WI.
    static let defaultLatitude: Double = 43.80
    static let defaultLongitude: Double = -91.20
}
