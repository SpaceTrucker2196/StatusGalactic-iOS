import Foundation

@Observable
final class APRSMessageStore {
    static let defaultsKey = "io.river.statusgalactic.aprsMessages.v1"
    static let counterKey = "io.river.statusgalactic.aprsMsgCounter"
    static let limit = 200

    private(set) var messages: [APRSMessage]
    /// Path-derived sightings: for each digi/igate in the user's own
    /// station path, look up its location via aprs.fi and record a
    /// distance. These contribute to DX stats alongside conversation
    /// partners.
    private(set) var pathDX: [APRSDXEntry] = []
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
        myCallsign: String,
        client: APRSClient
    ) async {
        let me = myCallsign.uppercased()
        // Need a lookup for any message (incoming OR outgoing) whose "other
        // party" position isn't cached yet. Skip bulletins.
        let needsLookup = Set(
            messages
                .filter { !$0.isBulletin && $0.partyLat == nil }
                .map { Self.otherParty(in: $0, me: me) }
        )

        if !needsLookup.isEmpty {
            let fixes = (try? await client.locate(callsigns: Array(needsLookup))) ?? []
            let byCall = Dictionary(
                uniqueKeysWithValues: fixes.map { ($0.call.uppercased(), $0) }
            )
            for idx in messages.indices {
                guard !messages[idx].isBulletin else { continue }
                if messages[idx].partyLat == nil {
                    let other = Self.otherParty(in: messages[idx], me: me)
                    if let fix = byCall[other] {
                        messages[idx].partyLat = fix.lat
                        messages[idx].partyLng = fix.lng
                    }
                }
            }
        }

        // Always recompute distances against the current observer location.
        for idx in messages.indices {
            guard
                !messages[idx].isBulletin,
                let pLat = messages[idx].partyLat,
                let pLng = messages[idx].partyLng
            else { continue }
            messages[idx].distanceKm = haversineKm(
                lat1: lat, lng1: lng, lat2: pLat, lng2: pLng
            )
        }

        persist()
    }

    /// The non-self callsign in a message. For outgoing this is `to`, for
    /// incoming it's `from`. (Outgoing messages whose sender isn't `me`
    /// shouldn't exist in practice, but we still handle it sanely.)
    private static func otherParty(in msg: APRSMessage, me: String) -> String {
        if msg.from.uppercased() == me {
            return msg.to.uppercased()
        }
        return msg.from.uppercased()
    }

    /// Resolve every ham callsign in `path` via aprs.fi, compute its
    /// great-circle distance from `observer`, and record the sighting
    /// in `pathDX` so dxStats picks it up. Generic digi aliases
    /// (WIDE, TRACE, qAR, etc.) are filtered out by APRSPathParser.
    func enrichPathDX(
        path: String?,
        observedAt: Date,
        observerLat: Double,
        observerLng: Double,
        client: APRSClient
    ) async {
        guard let path else { return }
        let calls = APRSPathParser.realCallsigns(in: path)
        guard !calls.isEmpty else { return }
        // Skip ones we've already credited recently.
        let existing = Set(pathDX.map { $0.callsign.uppercased() })
        let needed = calls.filter { !existing.contains($0.uppercased()) }
        guard !needed.isEmpty else { return }
        let fixes = (try? await client.locate(callsigns: needed)) ?? []
        for fix in fixes {
            let km = haversineKm(
                lat1: observerLat, lng1: observerLng,
                lat2: fix.lat, lng2: fix.lng
            )
            pathDX.append(APRSDXEntry(
                callsign: fix.call.uppercased(),
                distanceKm: km,
                receivedAt: observedAt
            ))
        }
        // Cap the pathDX history at 200 to keep dxStats fast.
        if pathDX.count > 200 {
            pathDX.removeFirst(pathDX.count - 200)
        }
    }

    /// DX records: longest distance to the other party (in or out) today,
    /// this month, this year. Computed from cached `distanceKm`; pass
    /// through `enrichDistances(...)` first to populate them.
    func dxStats(
        myCallsign: String,
        reference: Date = Date(),
        calendar: Calendar = .current
    ) -> APRSDXStats {
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

        let me = myCallsign.uppercased()
        func consider(_ entry: APRSDXEntry, at time: Date) {
            if time >= yearStart,
               (maxYear?.distanceKm ?? -.infinity) < entry.distanceKm { maxYear = entry }
            if time >= monthStart,
               (maxMonth?.distanceKm ?? -.infinity) < entry.distanceKm { maxMonth = entry }
            if time >= todayStart,
               (maxToday?.distanceKm ?? -.infinity) < entry.distanceKm { maxToday = entry }
        }

        for msg in messages where !msg.isBulletin {
            guard let km = msg.distanceKm, msg.sentAt <= reference else { continue }
            let other = Self.otherParty(in: msg, me: me)
            consider(
                APRSDXEntry(callsign: other, distanceKm: km, receivedAt: msg.sentAt),
                at: msg.sentAt
            )
        }
        // Path-derived sightings (digi + igate stations from the user's
        // own packet path) contribute the same way.
        for entry in pathDX where entry.receivedAt <= reference {
            consider(entry, at: entry.receivedAt)
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
