import Foundation

@Observable
final class APRSMessageStore {
    static let defaultsKey = "io.river.statusgalactic.aprsMessages.v1"
    static let counterKey = "io.river.statusgalactic.aprsMsgCounter"
    static let limit = 200

    private(set) var messages: [APRSMessage]
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.defaultsKey),
           let saved = try? JSONDecoder().decode([APRSMessage].self, from: data) {
            self.messages = saved
        } else {
            self.messages = []
        }
    }

    /// Insert a message, deduplicate by id, keep newest at top, cap at `limit`.
    func upsert(_ msg: APRSMessage) {
        messages.removeAll { $0.id == msg.id }
        messages.insert(msg, at: 0)
        if messages.count > Self.limit {
            messages.removeLast(messages.count - Self.limit)
        }
        persist()
    }

    func upsert(many newOnes: [APRSMessage]) {
        for m in newOnes { upsert(m) }
    }

    func clear() {
        messages = []
        persist()
    }

    /// Monotonically-increasing message counter for outgoing packets.
    func nextOutgoingNumber() -> Int {
        let current = defaults.integer(forKey: Self.counterKey)
        let next = current + 1
        defaults.set(next, forKey: Self.counterKey)
        return next
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(messages) {
            defaults.set(data, forKey: Self.defaultsKey)
        }
    }
}
