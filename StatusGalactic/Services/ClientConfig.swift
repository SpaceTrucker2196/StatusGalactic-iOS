import Foundation

/// User-configurable client settings, persisted to `UserDefaults`.
///
/// Spacetrucker Galactic now runs all API calls locally. The only configuration that
/// matters is the aprs.fi read API key (required for callsign lookups) and a
/// default marine zone for coastal users.
@Observable
final class ClientConfig {
    static let aprsKeyKey = "io.river.statusgalactic.aprsAPIKey"
    static let nasaKeyKey = "io.river.statusgalactic.nasaAPIKey"
    static let repeaterBookTokenKey = "io.river.statusgalactic.repeaterBookToken"
    static let n2yoKeyKey = "io.river.statusgalactic.n2yoAPIKey"
    static let myCallsignKey = "io.river.statusgalactic.myCallsign"
    static let marineZoneKey = "io.river.statusgalactic.defaultMarineZone"
    static let userAgentKey = "io.river.statusgalactic.userAgent"
    static let apodBackgroundKey = "io.river.statusgalactic.useAPODBackground"
    static let briefSectionOrderKey = "io.river.statusgalactic.briefSectionOrder"
    static let hiddenBriefSectionsKey = "io.river.statusgalactic.hiddenBriefSections"

    static let defaultUserAgent =
        "StatusGalactic-iOS/0.2 (+https://github.com/SpaceTrucker2196/StatusGalactic-iOS)"

    var aprsAPIKey: String {
        didSet { UserDefaults.standard.set(aprsAPIKey, forKey: Self.aprsKeyKey) }
    }

    var nasaAPIKey: String {
        didSet { UserDefaults.standard.set(nasaAPIKey, forKey: Self.nasaKeyKey) }
    }

    /// RepeaterBook per-user app-bound token (`rbuapp_...`), sent as the
    /// `X-RB-App-Token` header. RepeaterBook's export API requires it as of
    /// 2026-03; each user mints their own for the approved app.
    var repeaterBookToken: String {
        didSet { UserDefaults.standard.set(repeaterBookToken, forKey: Self.repeaterBookTokenKey) }
    }

    var n2yoAPIKey: String {
        didSet { UserDefaults.standard.set(n2yoAPIKey, forKey: Self.n2yoKeyKey) }
    }

    var myCallsign: String {
        didSet { UserDefaults.standard.set(myCallsign, forKey: Self.myCallsignKey) }
    }

    var defaultMarineZone: String {
        didSet { UserDefaults.standard.set(defaultMarineZone, forKey: Self.marineZoneKey) }
    }

    var userAgent: String {
        didSet {
            UserDefaults.standard.set(userAgent, forKey: Self.userAgentKey)
            SharedDefaults.store.set(userAgent, forKey: SharedDefaults.Keys.userAgent)
        }
    }

    /// When true, the brief uses the Astronomy Picture of the Day as a faint
    /// background image behind the cosmic-sky gradient.
    var useAPODBackground: Bool {
        didSet { UserDefaults.standard.set(useAPODBackground, forKey: Self.apodBackgroundKey) }
    }

    /// User-chosen order of sections on the Brief tab. Persisted as the
    /// raw-value list so new releases can add cases without invalidating
    /// the saved order (see `BriefSection.reconcile`).
    var briefSectionOrder: [BriefSection] {
        didSet {
            UserDefaults.standard.set(briefSectionOrder.map(\.rawValue),
                                      forKey: Self.briefSectionOrderKey)
        }
    }

    /// Sections the user has explicitly hidden from the Brief tab via
    /// the section-management list. Persisted as a raw-value array
    /// since `Set` isn't natively storable in UserDefaults; unknown
    /// raw values are silently dropped on load.
    var hiddenBriefSections: Set<BriefSection> {
        didSet {
            UserDefaults.standard.set(hiddenBriefSections.map(\.rawValue),
                                      forKey: Self.hiddenBriefSectionsKey)
        }
    }

    init() {
        let defaults = UserDefaults.standard
        self.aprsAPIKey = defaults.string(forKey: Self.aprsKeyKey) ?? ""
        self.nasaAPIKey = defaults.string(forKey: Self.nasaKeyKey) ?? ""
        self.repeaterBookToken = defaults.string(forKey: Self.repeaterBookTokenKey) ?? ""
        self.n2yoAPIKey = defaults.string(forKey: Self.n2yoKeyKey) ?? ""
        self.myCallsign = defaults.string(forKey: Self.myCallsignKey) ?? ""
        self.defaultMarineZone = defaults.string(forKey: Self.marineZoneKey) ?? ""
        self.userAgent = defaults.string(forKey: Self.userAgentKey) ?? Self.defaultUserAgent
        self.useAPODBackground = defaults.object(forKey: Self.apodBackgroundKey) as? Bool ?? true
        let persistedOrder = defaults.stringArray(forKey: Self.briefSectionOrderKey) ?? []
        self.briefSectionOrder = BriefSection.reconcile(persistedRawValues: persistedOrder)
        let persistedHidden = defaults.stringArray(forKey: Self.hiddenBriefSectionsKey) ?? []
        self.hiddenBriefSections = Set(persistedHidden.compactMap(BriefSection.init(rawValue:)))

        // Mirror to the shared app-group suite so the widget and watch
        // complications can read the latest User-Agent without their own
        // copy of ClientConfig logic.
        SharedDefaults.store.set(userAgent, forKey: SharedDefaults.Keys.userAgent)
        SharedDefaults.store.set(defaultMarineZone, forKey: SharedDefaults.Keys.marineZone)
    }
}
