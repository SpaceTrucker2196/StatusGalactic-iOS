import Foundation

/// Persists the user's iPad `PanelsScreen` tile layout across launches.
///
/// Backing store is `SharedDefaults` so a future widget-configuration
/// intent (which panels/sizes the user pinned) can read the same source
/// of truth. On decode failure or empty store, `load(fallback:)` returns
/// the caller-supplied default layout — never crashes, never silently
/// drops the user's config.
enum PanelLayoutStore {
    static let key = "shared.panelsLayout"

    /// Return the persisted layout if any, or `fallback` if none exists
    /// or the persisted bytes fail to decode.
    static func load(fallback: [PanelTile]) -> [PanelTile] {
        guard let data = SharedDefaults.store.data(forKey: key) else {
            return fallback
        }
        do {
            return try JSONDecoder().decode([PanelTile].self, from: data)
        } catch {
            // A future PanelKind case not present in this build would
            // land here on downgrade. Fall back rather than crash.
            return fallback
        }
    }

    /// Overwrite the persisted layout. Called by the editor on every
    /// tile mutation so a crash mid-edit still keeps the last known
    /// good state.
    static func save(_ tiles: [PanelTile]) {
        do {
            let data = try JSONEncoder().encode(tiles)
            SharedDefaults.store.set(data, forKey: key)
        } catch {
            // Encoding a value-type array of Codable primitives never
            // throws in practice; swallow to keep the save call site
            // fire-and-forget.
        }
    }

    /// Wipe the persisted layout — used by "Reset to default" in the
    /// editor and by tests.
    static func clear() {
        SharedDefaults.store.removeObject(forKey: key)
    }
}
