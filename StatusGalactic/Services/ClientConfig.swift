import Foundation

/// User-configurable client settings, persisted to `UserDefaults`.
///
/// Status Galactic now runs all API calls locally. The only configuration that
/// matters is the aprs.fi read API key (required for callsign lookups) and a
/// default marine zone for coastal users.
@Observable
final class ClientConfig {
    static let aprsKeyKey = "io.river.statusgalactic.aprsAPIKey"
    static let nasaKeyKey = "io.river.statusgalactic.nasaAPIKey"
    static let myCallsignKey = "io.river.statusgalactic.myCallsign"
    static let marineZoneKey = "io.river.statusgalactic.defaultMarineZone"
    static let userAgentKey = "io.river.statusgalactic.userAgent"

    static let defaultUserAgent =
        "StatusGalactic-iOS/0.2 (+https://github.com/SpaceTrucker2196/StatusGalactic-iOS)"

    var aprsAPIKey: String {
        didSet { UserDefaults.standard.set(aprsAPIKey, forKey: Self.aprsKeyKey) }
    }

    var nasaAPIKey: String {
        didSet { UserDefaults.standard.set(nasaAPIKey, forKey: Self.nasaKeyKey) }
    }

    var myCallsign: String {
        didSet { UserDefaults.standard.set(myCallsign, forKey: Self.myCallsignKey) }
    }

    var defaultMarineZone: String {
        didSet { UserDefaults.standard.set(defaultMarineZone, forKey: Self.marineZoneKey) }
    }

    var userAgent: String {
        didSet { UserDefaults.standard.set(userAgent, forKey: Self.userAgentKey) }
    }

    init() {
        let defaults = UserDefaults.standard
        self.aprsAPIKey = defaults.string(forKey: Self.aprsKeyKey) ?? ""
        self.nasaAPIKey = defaults.string(forKey: Self.nasaKeyKey) ?? ""
        self.myCallsign = defaults.string(forKey: Self.myCallsignKey) ?? ""
        self.defaultMarineZone = defaults.string(forKey: Self.marineZoneKey) ?? ""
        self.userAgent = defaults.string(forKey: Self.userAgentKey) ?? Self.defaultUserAgent
    }
}
