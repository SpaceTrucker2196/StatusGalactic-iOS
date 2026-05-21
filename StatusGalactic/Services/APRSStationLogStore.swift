import Foundation

/// One historical snapshot of the user's own APRS station, captured each
/// time the APRS tab successfully resolves their callsign via aprs.fi.
struct APRSStationLogEntry: Codable, Identifiable, Hashable {
    var id: Date { observedAt }
    let observedAt: Date
    let lat: Double
    let lng: Double
    let comment: String?
    let courseDeg: Double?
    let speedKmh: Double?
    let altitudeM: Double?
    let statusMessage: String?
    let symbol: String?
}

/// Append-only log of the user's own station fixes, persisted to
/// UserDefaults. Deduplicates by observedAt and caps at 500 entries.
@Observable
final class APRSStationLogStore {
    static let defaultsKey = "io.river.statusgalactic.aprsStationLog.v1"
    static let limit = 500

    private(set) var entries: [APRSStationLogEntry]
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.defaultsKey),
           let saved = try? JSONDecoder().decode([APRSStationLogEntry].self, from: data) {
            self.entries = saved
        } else {
            self.entries = []
        }
    }

    /// Insert a fix snapshot. No-op if we already have one at the same time.
    func append(_ fix: APRSFix) {
        let observedAt = fix.lastTime ?? fix.firstTime ?? Date()
        if entries.contains(where: { $0.observedAt == observedAt }) { return }
        let entry = APRSStationLogEntry(
            observedAt: observedAt,
            lat: fix.lat,
            lng: fix.lng,
            comment: fix.comment,
            courseDeg: fix.courseDeg,
            speedKmh: fix.speedKmh,
            altitudeM: fix.altitudeM,
            statusMessage: fix.statusMessage,
            symbol: fix.symbol
        )
        entries.append(entry)
        entries.sort { $0.observedAt > $1.observedAt }
        if entries.count > Self.limit {
            entries.removeLast(entries.count - Self.limit)
        }
        persist()
    }

    func clear() {
        entries = []
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: Self.defaultsKey)
        }
    }
}
