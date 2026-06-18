import Foundation
import SwiftData

/// SwiftData persistence for the Meshtastic tab. Stores the traffic feed and
/// chat history under Application Support so they survive app relaunches.
/// Capped — see ``MeshtasticStore/maxTrafficEntries`` and ``maxChatMessages``.
///
/// The store is intentionally separate from `MeshtasticService` so the view
/// can preview / unit-test against an in-memory container without spinning
/// up CoreBluetooth.

@Model
final class PersistedTrafficEntry {
    /// Stable id so ScrollView can diff rows.
    @Attribute(.unique) var id: UUID
    /// When the entry was logged on this device (RX time at the phone, or
    /// the TX issue time outbound).
    var timestamp: Date
    /// "rx" or "tx" — stored as a raw string so we don't tie persistence to
    /// the in-memory `Direction` enum's case ordering.
    var directionRaw: String
    /// Meshtastic `PortNum` raw int. `nil` for entries that don't carry an
    /// app payload (handshake envelopes, log records).
    var portnum: Int?
    /// Human-readable summary — `SwiftProtobuf.Message.textFormatString()`
    /// for envelopes, raw text for chat messages, etc.
    var summary: String
    /// Hex dump of the raw wire bytes, for the dev/debug view.
    var rawHex: String
    /// Sender node num for RX packets, nil for TX.
    var fromNodeNum: Int?

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        directionRaw: String,
        portnum: Int?,
        summary: String,
        rawHex: String,
        fromNodeNum: Int? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.directionRaw = directionRaw
        self.portnum = portnum
        self.summary = summary
        self.rawHex = rawHex
        self.fromNodeNum = fromNodeNum
    }
}

@Model
final class PersistedChatMessage {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    /// Sender node num — `nil` for messages we sent.
    var fromNodeNum: Int?
    /// Display name for the sender at the time of receipt. May be a node
    /// short-name or the node-num formatted as `!XXXXXXXX`.
    var fromName: String
    var text: String
    /// True when we sent the message ourselves.
    var isOutbound: Bool
    /// Primary channel idx (currently always 0; surfaced for future use).
    var channel: Int

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        fromNodeNum: Int?,
        fromName: String,
        text: String,
        isOutbound: Bool,
        channel: Int = 0
    ) {
        self.id = id
        self.timestamp = timestamp
        self.fromNodeNum = fromNodeNum
        self.fromName = fromName
        self.text = text
        self.isOutbound = isOutbound
        self.channel = channel
    }
}

/// Thin facade over `ModelContainer` + `ModelContext` that hides SwiftData
/// boilerplate from the service. Construction is cheap; everything important
/// happens on `MainActor`.
@MainActor
final class MeshtasticStore {

    /// FIFO eviction caps. Sized to keep storage modest on iPhone — even
    /// 5,000 traffic rows with ~300-byte hex dumps is under ~2 MB.
    nonisolated static let maxTrafficEntries = 5_000
    nonisolated static let maxChatMessages   = 2_000

    let container: ModelContainer
    var context: ModelContext { container.mainContext }

    init(inMemory: Bool = false) {
        do {
            let schema = Schema([
                PersistedTrafficEntry.self,
                PersistedChatMessage.self,
            ])
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: inMemory
            )
            self.container = try ModelContainer(for: schema, configurations: config)
        } catch {
            // SwiftData container creation failing on a fresh install is a
            // setup bug worth crashing for — there's no useful fallback at
            // runtime and the user won't see Mesh history until it's fixed.
            fatalError("MeshtasticStore failed to initialise: \(error)")
        }
    }

    // MARK: - Inserts (with FIFO eviction)

    func appendTraffic(_ entry: PersistedTrafficEntry) {
        context.insert(entry)
        evictTrafficIfNeeded()
        try? context.save()
    }

    func appendChat(_ msg: PersistedChatMessage) {
        context.insert(msg)
        evictChatIfNeeded()
        try? context.save()
    }

    // MARK: - Reads

    func loadRecentTraffic(limit: Int) -> [PersistedTrafficEntry] {
        var descriptor = FetchDescriptor<PersistedTrafficEntry>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        let recent = (try? context.fetch(descriptor)) ?? []
        // Caller wants chronological (oldest → newest) for append-to-bottom
        // log views, so reverse the reverse.
        return recent.reversed()
    }

    func loadRecentChat(limit: Int) -> [PersistedChatMessage] {
        var descriptor = FetchDescriptor<PersistedChatMessage>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        let recent = (try? context.fetch(descriptor)) ?? []
        return recent.reversed()
    }

    // MARK: - Clear

    func clearAll() {
        try? context.delete(model: PersistedTrafficEntry.self)
        try? context.delete(model: PersistedChatMessage.self)
        try? context.save()
    }

    // MARK: - Private

    private func evictTrafficIfNeeded() {
        let count = (try? context.fetchCount(FetchDescriptor<PersistedTrafficEntry>())) ?? 0
        guard count > Self.maxTrafficEntries else { return }
        let overflow = count - Self.maxTrafficEntries
        var descriptor = FetchDescriptor<PersistedTrafficEntry>(
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        descriptor.fetchLimit = overflow
        guard let oldest = try? context.fetch(descriptor) else { return }
        for row in oldest { context.delete(row) }
    }

    private func evictChatIfNeeded() {
        let count = (try? context.fetchCount(FetchDescriptor<PersistedChatMessage>())) ?? 0
        guard count > Self.maxChatMessages else { return }
        let overflow = count - Self.maxChatMessages
        var descriptor = FetchDescriptor<PersistedChatMessage>(
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        descriptor.fetchLimit = overflow
        guard let oldest = try? context.fetch(descriptor) else { return }
        for row in oldest { context.delete(row) }
    }
}
