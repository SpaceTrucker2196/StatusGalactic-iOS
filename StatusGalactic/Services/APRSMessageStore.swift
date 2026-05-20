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

    /// Group messages by conversation partner, excluding bulletin broadcasts.
    /// Threads are sorted newest-activity first.
    func threads(myCallsign: String) -> [APRSThread] {
        let me = myCallsign.uppercased()
        let direct = messages.filter { !$0.isBulletin }
        let grouped = Dictionary(grouping: direct) { msg -> String in
            msg.from.uppercased() == me ? msg.to.uppercased() : msg.from.uppercased()
        }
        return grouped.map { partner, msgs in
            APRSThread(partner: partner, messages: msgs.sorted { $0.sentAt > $1.sentAt })
        }
        .sorted { ($0.lastMessageAt ?? .distantPast) > ($1.lastMessageAt ?? .distantPast) }
    }

    /// All bulletin messages, newest first.
    var bulletins: [APRSMessage] {
        messages.filter { $0.isBulletin }.sorted { $0.sentAt > $1.sentAt }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(messages) {
            defaults.set(data, forKey: Self.defaultsKey)
        }
    }
}

/// A conversation between `myCallsign` and one partner.
struct APRSThread: Identifiable, Hashable {
    var id: String { partner }
    let partner: String
    let messages: [APRSMessage]

    var lastMessage: APRSMessage? { messages.first }
    var lastMessageAt: Date? { lastMessage?.sentAt }
}
