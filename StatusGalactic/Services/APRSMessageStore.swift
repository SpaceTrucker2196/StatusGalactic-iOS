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

    // MARK: - DX distance enrichment

    /// Look up sender positions via aprs.fi for any incoming messages that
    /// don't yet have cached coordinates, then compute great-circle distance
    /// from the observer at (lat, lng). Persists the result back to disk.
    func enrichDistances(
        observerLat lat: Double,
        observerLng lng: Double,
        client: APRSClient
    ) async {
        let needsLookup = Set(
            messages
                .filter { $0.direction == .incoming && $0.senderLat == nil && !$0.isBulletin }
                .map(\.from)
        )

        if !needsLookup.isEmpty {
            let fixes = (try? await client.locate(callsigns: Array(needsLookup))) ?? []
            let byCall = Dictionary(
                uniqueKeysWithValues: fixes.map { ($0.call.uppercased(), $0) }
            )
            for idx in messages.indices {
                guard messages[idx].direction == .incoming, !messages[idx].isBulletin else { continue }
                if messages[idx].senderLat == nil,
                   let fix = byCall[messages[idx].from.uppercased()] {
                    messages[idx].senderLat = fix.lat
                    messages[idx].senderLng = fix.lng
                }
            }
        }

        // Always recompute distances against the current observer location.
        for idx in messages.indices {
            guard
                messages[idx].direction == .incoming,
                let sLat = messages[idx].senderLat,
                let sLng = messages[idx].senderLng
            else { continue }
            messages[idx].distanceKm = haversineKm(
                lat1: lat, lng1: lng, lat2: sLat, lng2: sLng
            )
        }

        persist()
    }

    /// DX records: longest received distance today, this month, this year.
    /// Computed from cached `distanceKm` on incoming messages; pass through
    /// `enrichDistances(...)` first to populate them.
    func dxStats(reference: Date = Date(), calendar: Calendar = .current) -> APRSDXStats {
        let cal = calendar
        let todayStart = cal.startOfDay(for: reference)

        var monthComponents = cal.dateComponents([.year, .month], from: reference)
        monthComponents.day = 1
        let monthStart = cal.date(from: monthComponents) ?? todayStart

        var yearComponents = cal.dateComponents([.year], from: reference)
        yearComponents.month = 1
        yearComponents.day = 1
        let yearStart = cal.date(from: yearComponents) ?? todayStart

        var maxToday: APRSDXEntry?
        var maxMonth: APRSDXEntry?
        var maxYear: APRSDXEntry?

        for msg in messages where msg.direction == .incoming && !msg.isBulletin {
            guard let km = msg.distanceKm, msg.sentAt <= reference else { continue }
            let entry = APRSDXEntry(
                callsign: msg.from.uppercased(),
                distanceKm: km,
                receivedAt: msg.sentAt
            )
            if msg.sentAt >= yearStart,
               (maxYear?.distanceKm ?? -.infinity) < km { maxYear = entry }
            if msg.sentAt >= monthStart,
               (maxMonth?.distanceKm ?? -.infinity) < km { maxMonth = entry }
            if msg.sentAt >= todayStart,
               (maxToday?.distanceKm ?? -.infinity) < km { maxToday = entry }
        }
        return APRSDXStats(today: maxToday, month: maxMonth, year: maxYear)
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
