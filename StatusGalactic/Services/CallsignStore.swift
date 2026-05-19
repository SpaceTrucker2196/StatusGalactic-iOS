import Foundation

struct Callsign: Codable, Identifiable, Hashable {
    var id: String { call }
    var call: String
    var label: String
    var notes: String
    var addedAt: Date
}

@Observable
final class CallsignStore {
    static let defaultsKey = "io.river.statusgalactic.callsigns.v1"

    private(set) var callsigns: [Callsign]
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.defaultsKey),
           let saved = try? JSONDecoder().decode([Callsign].self, from: data) {
            self.callsigns = saved
        } else {
            self.callsigns = []
        }
    }

    @discardableResult
    func add(_ call: String, label: String = "", notes: String = "") -> Callsign? {
        let normalized = Self.normalize(call)
        guard !normalized.isEmpty else { return nil }
        guard !callsigns.contains(where: { $0.call == normalized }) else { return nil }
        let entry = Callsign(
            call: normalized,
            label: label.trimmingCharacters(in: .whitespaces),
            notes: notes.trimmingCharacters(in: .whitespaces),
            addedAt: Date()
        )
        callsigns.append(entry)
        persist()
        return entry
    }

    func remove(at offsets: IndexSet) {
        callsigns.remove(atOffsets: offsets)
        persist()
    }

    func remove(call: String) {
        let normalized = Self.normalize(call)
        callsigns.removeAll { $0.call == normalized }
        persist()
    }

    func update(_ updated: Callsign) {
        guard let idx = callsigns.firstIndex(where: { $0.call == updated.call }) else { return }
        callsigns[idx] = updated
        persist()
    }

    static func normalize(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(callsigns) {
            defaults.set(data, forKey: Self.defaultsKey)
        }
    }
}
