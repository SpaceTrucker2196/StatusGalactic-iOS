import Foundation

@Observable
final class ServerConfig {
    static let urlKey = "io.river.statusgalactic.serverURL"
    static let marineZoneKey = "io.river.statusgalactic.defaultMarineZone"
    static let defaultURLString = "http://localhost:8000"

    var serverURLString: String {
        didSet { UserDefaults.standard.set(serverURLString, forKey: Self.urlKey) }
    }

    var defaultMarineZone: String {
        didSet { UserDefaults.standard.set(defaultMarineZone, forKey: Self.marineZoneKey) }
    }

    var serverURL: URL {
        URL(string: serverURLString) ?? URL(string: Self.defaultURLString)!
    }

    init() {
        let defaults = UserDefaults.standard
        self.serverURLString = defaults.string(forKey: Self.urlKey) ?? Self.defaultURLString
        self.defaultMarineZone = defaults.string(forKey: Self.marineZoneKey) ?? ""
    }
}
