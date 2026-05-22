import Foundation

/// Persists the last-successful brief snapshot to UserDefaults so the next
/// launch (or the next refresh on a flaky network) can show *something*
/// instead of a blank screen. Cache hits are tagged "stale" — the UI shows
/// them in gray until a fresh fetch lands.
///
/// We use UserDefaults rather than the Caches directory because Brief
/// payloads are small (<200 KB) and we want them present even after a
/// disk-clean restart of the simulator.
enum BriefCache {
    static let defaultsKey = "io.river.statusgalactic.cachedBrief"
    static let maxAgeForDisplay: TimeInterval = 7 * 24 * 60 * 60   // 7 days

    struct Snapshot: Codable {
        let brief: Brief
        let fetchedAt: Date
    }

    static func save(brief: Brief, fetchedAt: Date) {
        let snap = Snapshot(brief: brief, fetchedAt: fetchedAt)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(snap) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }

    /// Returns the cached snapshot when it's present and not absurdly old.
    static func load(now: Date = Date()) -> Snapshot? {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let snap = try? decoder.decode(Snapshot.self, from: data) else {
            // Decoding failure usually means the Brief schema rolled
            // forward and the cached blob is stale-shaped. Clear it.
            UserDefaults.standard.removeObject(forKey: defaultsKey)
            return nil
        }
        guard now.timeIntervalSince(snap.fetchedAt) < maxAgeForDisplay else { return nil }
        return snap
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: defaultsKey)
    }
}
