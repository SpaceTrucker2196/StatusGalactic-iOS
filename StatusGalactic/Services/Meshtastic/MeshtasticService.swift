import Foundation
import SwiftProtobuf

/// Source of truth for the Meshtastic tab.
///
/// Owns the BLE transport, the protobuf codec, the SwiftData store, and the
/// in-memory ring buffer the TRAFFIC view reads from. View / ViewModel
/// observe `MeshtasticService` via `@Environment`; nothing else in the app
/// imports CoreBluetooth or SwiftProtobuf.
@Observable
@MainActor
final class MeshtasticService {

    // MARK: - View-facing types

    /// View-friendly mirror of `MeshtasticConnectionState`. Wraps the
    /// transport state with a `label` for the STATUS section.
    enum ConnectionStatus: Equatable {
        case idle
        case bluetoothOff
        case bluetoothUnauthorized
        case bluetoothUnsupported
        case scanning
        case connecting(String)
        case connected(String)
        case disconnecting
        case failed(String)

        init(_ state: MeshtasticConnectionState) {
            switch state {
            case .bluetoothOff:          self = .bluetoothOff
            case .bluetoothUnauthorized: self = .bluetoothUnauthorized
            case .bluetoothUnsupported:  self = .bluetoothUnsupported
            case .idle:                  self = .idle
            case .scanning:              self = .scanning
            case .connecting(let n):     self = .connecting(n)
            case .connected(let n):      self = .connected(n)
            case .disconnecting:         self = .disconnecting
            case .failed(let r):         self = .failed(r)
            }
        }

        var label: String {
            switch self {
            case .idle:                 return "Idle"
            case .bluetoothOff:         return "Bluetooth Off"
            case .bluetoothUnauthorized:return "Bluetooth Not Allowed"
            case .bluetoothUnsupported: return "Bluetooth Unsupported"
            case .scanning:             return "Scanning…"
            case .connecting(let n):    return "Connecting to \(n)…"
            case .connected(let n):     return "Connected · \(n)"
            case .disconnecting:        return "Disconnecting…"
            case .failed(let r):        return "Failed · \(r)"
            }
        }
    }

    struct DiscoveredNode: Identifiable, Hashable {
        let id: UUID
        let name: String
        let rssi: Int
    }

    struct TrafficEntry: Identifiable, Hashable {
        enum Direction: String { case rx, tx }
        let id: UUID
        let timestamp: Date
        let direction: Direction
        let portnum: Int?
        let summary: String
        let rawHex: String
        let fromNodeNum: Int?
    }

    struct ChatEntry: Identifiable, Hashable {
        let id: UUID
        let timestamp: Date
        let fromNodeNum: Int?
        let fromName: String
        let text: String
        let isOutbound: Bool
    }

    struct KnownNode: Identifiable, Hashable {
        let id: Int            // node num
        let shortName: String
        let longName: String
        var lastHeard: Date?
        var snr: Float?
        var rssi: Int?
        var batteryLevel: Int?
        var latitudeI: Int32?
        var longitudeI: Int32?
        /// Bounded history of `(timestamp, snr_dB)` samples — most recent
        /// last. Populated from `NodeInfo.snr` and from `MeshPacket.rxSnr`
        /// on every received packet. Detail view renders this as a bar
        /// graph; capped at ``MeshtasticService/snrHistoryDepth``.
        var snrHistory: [SNRSample] = []
    }

    /// One signal-quality sample for a known node.
    struct SNRSample: Hashable {
        let timestamp: Date
        let snr: Float
    }

    // MARK: - Observable state

    var status: ConnectionStatus = .idle
    var discoveredNodes: [DiscoveredNode] = []
    var traffic: [TrafficEntry] = []
    var chat: [ChatEntry] = []
    var knownNodes: [Int: KnownNode] = [:]
    /// Most recent device log records (raw `LogRecord` messages). Bounded
    /// like the traffic feed — see ``inMemoryRingSize``.
    var deviceLog: [String] = []

    var ownNodeNum: Int?

    // MARK: - Configuration

    /// In-memory cap for the live TRAFFIC + log streams. Disk store keeps
    /// more (see `MeshtasticStore.maxTrafficEntries`).
    nonisolated static let inMemoryRingSize = 500

    /// Per-node SNR history cap — enough to fill the bar graph at typical
    /// packet rates without unbounded growth. Surfaces in the node detail
    /// view's bar graph; samples are FIFO-evicted.
    nonisolated static let snrHistoryDepth = 30

    // MARK: - Private

    private let transport: any MeshtasticTransport
    private let store: MeshtasticStore

    /// One handshake id per connect. We compare against
    /// `FromRadio.configCompleteID` to know when initial config dump finishes.
    /// `internal` (default) so tests can assert the value the service sent.
    private(set) var pendingConfigID: UInt32 = 0
    private(set) var handshakeComplete: Bool = false

    // MARK: - Init

    /// - Parameters:
    ///   - inMemoryStore: when true the SwiftData container is RAM-only.
    ///     Use for previews and tests so we don't poison the user's history.
    ///   - transport: defaults to a real CoreBluetooth-backed
    ///     `MeshtasticBLETransport`. Tests pass `FakeMeshtasticTransport`
    ///     so the service can be driven without BLE hardware.
    init(
        inMemoryStore: Bool = false,
        transport: (any MeshtasticTransport)? = nil
    ) {
        self.store = MeshtasticStore(inMemory: inMemoryStore)
        // Default to a real BLE transport. Constructing it here (rather than
        // as a default argument) keeps the MainActor-isolated init off the
        // caller's default-argument evaluation site.
        self.transport = transport ?? MeshtasticBLETransport()
        self.transport.delegate = self
        // Surface persisted history immediately. The user expects yesterday's
        // messages to still be there when they reopen the tab.
        self.traffic = store.loadRecentTraffic(limit: Self.inMemoryRingSize).map { e in
            TrafficEntry(
                id: e.id,
                timestamp: e.timestamp,
                direction: TrafficEntry.Direction(rawValue: e.directionRaw) ?? .rx,
                portnum: e.portnum,
                summary: e.summary,
                rawHex: e.rawHex,
                fromNodeNum: e.fromNodeNum
            )
        }
        self.chat = store.loadRecentChat(limit: 500).map { m in
            ChatEntry(
                id: m.id,
                timestamp: m.timestamp,
                fromNodeNum: m.fromNodeNum,
                fromName: m.fromName,
                text: m.text,
                isOutbound: m.isOutbound
            )
        }
    }

    // MARK: - View intents

    func appeared() {
        transport.powerOn()
    }

    func startScan() {
        transport.startScan()
    }

    func stopScan() {
        transport.stopScan()
    }

    func connect(_ id: UUID) {
        transport.connect(id)
    }

    func disconnect() {
        transport.disconnect()
    }

    /// Send a broadcast text message on the primary channel. No-op if not
    /// connected or text is empty after trimming.
    func sendBroadcast(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard case .connected = status else { return }
        do {
            let bytes = try MeshtasticPacketCodec.broadcastText(trimmed)
            transport.send(bytes)
            // Mirror into traffic + chat immediately — the node won't loop
            // our own broadcast back, so this is the only place it shows up.
            let now = Date()
            let entry = TrafficEntry(
                id: UUID(),
                timestamp: now,
                direction: .tx,
                portnum: Int(Meshtastic_PortNum.textMessageApp.rawValue),
                summary: "TX text · \(trimmed)",
                rawHex: bytes.shortHex(),
                fromNodeNum: ownNodeNum
            )
            appendTraffic(entry)
            let chatEntry = ChatEntry(
                id: UUID(),
                timestamp: now,
                fromNodeNum: ownNodeNum,
                fromName: "Me",
                text: trimmed,
                isOutbound: true
            )
            appendChat(chatEntry)
        } catch {
            appendTraffic(.init(
                id: UUID(), timestamp: Date(), direction: .tx,
                portnum: nil, summary: "TX failed: \(error.localizedDescription)",
                rawHex: "", fromNodeNum: nil
            ))
        }
    }

    func clearHistory() {
        traffic.removeAll()
        chat.removeAll()
        deviceLog.removeAll()
        store.clearAll()
    }

    // MARK: - Internal append helpers

    private func appendTraffic(_ entry: TrafficEntry) {
        traffic.append(entry)
        if traffic.count > Self.inMemoryRingSize {
            traffic.removeFirst(traffic.count - Self.inMemoryRingSize)
        }
        store.appendTraffic(PersistedTrafficEntry(
            id: entry.id,
            timestamp: entry.timestamp,
            directionRaw: entry.direction.rawValue,
            portnum: entry.portnum,
            summary: entry.summary,
            rawHex: entry.rawHex,
            fromNodeNum: entry.fromNodeNum
        ))
    }

    private func appendChat(_ entry: ChatEntry) {
        chat.append(entry)
        if chat.count > Self.inMemoryRingSize {
            chat.removeFirst(chat.count - Self.inMemoryRingSize)
        }
        store.appendChat(PersistedChatMessage(
            id: entry.id,
            timestamp: entry.timestamp,
            fromNodeNum: entry.fromNodeNum,
            fromName: entry.fromName,
            text: entry.text,
            isOutbound: entry.isOutbound
        ))
    }

    private func appendDeviceLog(_ line: String) {
        deviceLog.append(line)
        if deviceLog.count > Self.inMemoryRingSize {
            deviceLog.removeFirst(deviceLog.count - Self.inMemoryRingSize)
        }
    }

    // MARK: - Handshake

    private func performHandshake() {
        pendingConfigID = UInt32.random(in: 1...UInt32.max)
        handshakeComplete = false
        do {
            let bytes = try MeshtasticPacketCodec.wantConfig(id: pendingConfigID)
            transport.send(bytes)
            appendTraffic(.init(
                id: UUID(), timestamp: Date(), direction: .tx,
                portnum: nil, summary: "TX wantConfig id=\(pendingConfigID)",
                rawHex: bytes.shortHex(), fromNodeNum: nil
            ))
        } catch {
            appendTraffic(.init(
                id: UUID(), timestamp: Date(), direction: .tx,
                portnum: nil, summary: "wantConfig encode failed: \(error.localizedDescription)",
                rawHex: "", fromNodeNum: nil
            ))
        }
    }

    private func displayName(forNodeNum num: UInt32) -> String {
        if let known = knownNodes[Int(num)] {
            return known.shortName.isEmpty ? known.longName : known.shortName
        }
        return String(format: "!%08x", num)
    }

    // MARK: - Signal-history helpers

    /// Update a node's running SNR / RSSI snapshot and append a sample to
    /// its bar-graph history. Creates the node entry if we hadn't heard
    /// from it before (some MeshPackets arrive before the matching
    /// NodeInfo lands).
    private func recordSignal(forNodeNum nodeNum: UInt32, snr: Float, rssi: Int32, at when: Date) {
        let key = Int(nodeNum)
        var node = knownNodes[key] ?? KnownNode(
            id: key,
            shortName: "",
            longName: ""
        )
        if snr != 0 { node.snr = snr }
        if rssi != 0 { node.rssi = Int(rssi) }
        node.lastHeard = when
        if snr != 0 {
            appendSNRSample(&node, snr: snr, at: when)
        }
        knownNodes[key] = node
    }

    /// Push a `(timestamp, snr)` sample onto a node, trimming to the
    /// `snrHistoryDepth` cap. Inlined so callers can mutate a local
    /// `KnownNode` before reassigning into the dictionary.
    private func appendSNRSample(_ node: inout KnownNode, snr: Float, at when: Date) {
        node.snrHistory.append(SNRSample(timestamp: when, snr: snr))
        if node.snrHistory.count > Self.snrHistoryDepth {
            node.snrHistory.removeFirst(node.snrHistory.count - Self.snrHistoryDepth)
        }
    }
}

// MARK: - MeshtasticTransportDelegate

extension MeshtasticService: MeshtasticTransportDelegate {

    func transportDidChangeState(_ newState: MeshtasticConnectionState) {
        let mapped = ConnectionStatus(newState)
        status = mapped
        if case .connected = mapped {
            performHandshake()
        }
    }

    func transportDidUpdateDiscovered(_ peers: [MeshtasticDiscoveredPeer]) {
        discoveredNodes = peers.map { DiscoveredNode(id: $0.id, name: $0.name, rssi: $0.rssi) }
    }

    func transportDidReceiveFromRadioBytes(_ data: Data) {
        switch MeshtasticPacketCodec.decodeFromRadio(data) {
        case .failure(let error):
            appendTraffic(.init(
                id: UUID(), timestamp: Date(), direction: .rx,
                portnum: nil,
                summary: "RX decode failed: \(error.localizedDescription)",
                rawHex: data.shortHex(), fromNodeNum: nil
            ))
        case .success(let decoded):
            handle(decoded, raw: data)
        }
    }

    func transportDidReceiveLogRadioBytes(_ data: Data) {
        guard let rec = MeshtasticPacketCodec.decodeLogRecord(data) else { return }
        let levelTag: String = {
            switch rec.level {
            case .critical: return "CRIT"
            case .error:    return "ERR "
            case .warning:  return "WARN"
            case .info:     return "INFO"
            case .debug:    return "DBG "
            case .trace:    return "TRC "
            default:        return "    "
            }
        }()
        appendDeviceLog("[\(levelTag)] \(rec.source.isEmpty ? "" : "[\(rec.source)] ")\(rec.message)")
    }

    // MARK: - Internal routing

    private func handle(_ decoded: MeshtasticPacketCodec.DecodedFromRadio, raw: Data) {
        let now = Date()
        switch decoded {
        case .myInfo(let info):
            ownNodeNum = Int(info.myNodeNum)
            appendTraffic(.init(
                id: UUID(), timestamp: now, direction: .rx,
                portnum: nil,
                summary: "RX MyNodeInfo · num=\(info.myNodeNum)",
                rawHex: raw.shortHex(), fromNodeNum: nil
            ))

        case .nodeInfo(let info):
            let num = Int(info.num)
            let user = info.user
            let previous = knownNodes[num]
            let lastHeard: Date? = info.lastHeard > 0
                ? Date(timeIntervalSince1970: TimeInterval(info.lastHeard))
                : (previous?.lastHeard ?? nil)
            var updated = KnownNode(
                id: num,
                shortName: user.shortName,
                longName: user.longName,
                lastHeard: lastHeard,
                snr: info.snr != 0 ? info.snr : previous?.snr,
                rssi: previous?.rssi,
                batteryLevel: info.deviceMetrics.batteryLevel != 0
                    ? Int(info.deviceMetrics.batteryLevel)
                    : previous?.batteryLevel,
                latitudeI: info.position.latitudeI != 0
                    ? info.position.latitudeI
                    : previous?.latitudeI,
                longitudeI: info.position.longitudeI != 0
                    ? info.position.longitudeI
                    : previous?.longitudeI,
                snrHistory: previous?.snrHistory ?? []
            )
            // NodeInfo arrives with a single SNR reading; thread it into
            // history so the bar graph builds up even when no MeshPackets
            // are flowing.
            if info.snr != 0 {
                appendSNRSample(&updated, snr: info.snr, at: lastHeard ?? now)
            }
            knownNodes[num] = updated
            appendTraffic(.init(
                id: UUID(), timestamp: now, direction: .rx,
                portnum: nil,
                summary: "RX NodeInfo · \(displayName(forNodeNum: info.num)) (#\(info.num))",
                rawHex: raw.shortHex(), fromNodeNum: Int(info.num)
            ))

        case .meshPacket(let packet):
            handleMeshPacket(packet, raw: raw, now: now)

        case .logRecord(let rec):
            appendDeviceLog("[envelope] \(rec.message)")

        case .configCompleteID(let id):
            if id == pendingConfigID {
                handshakeComplete = true
                appendTraffic(.init(
                    id: UUID(), timestamp: now, direction: .rx,
                    portnum: nil,
                    summary: "RX configComplete · handshake done",
                    rawHex: raw.shortHex(), fromNodeNum: nil
                ))
            }

        case .channel(let ch):
            appendTraffic(.init(
                id: UUID(), timestamp: now, direction: .rx,
                portnum: nil,
                summary: "RX Channel · idx=\(ch.index) role=\(ch.role)",
                rawHex: raw.shortHex(), fromNodeNum: nil
            ))

        case .unhandled(let env):
            appendTraffic(.init(
                id: UUID(), timestamp: now, direction: .rx,
                portnum: nil,
                summary: "RX \(envelopeKindLabel(env))",
                rawHex: raw.shortHex(), fromNodeNum: nil
            ))
        }
    }

    private func handleMeshPacket(_ packet: Meshtastic_MeshPacket, raw: Data, now: Date) {
        let fromNum = packet.from
        // Every MeshPacket carries rxSnr / rxRssi at the link layer. Sample
        // those into the from-node's running history before we dispatch on
        // the payload so the bar graph fills in even for packet types we
        // don't otherwise mutate the directory on (encrypted, routing,
        // unknown portnums).
        if fromNum != 0 {
            recordSignal(
                forNodeNum: fromNum,
                snr: packet.rxSnr,
                rssi: packet.rxRssi,
                at: now
            )
        }
        let app = MeshtasticPacketCodec.classify(packet)

        switch app {
        case .text(let text):
            let name = displayName(forNodeNum: fromNum)
            appendChat(.init(
                id: UUID(), timestamp: now, fromNodeNum: Int(fromNum),
                fromName: name, text: text, isOutbound: false
            ))
            appendTraffic(.init(
                id: UUID(), timestamp: now, direction: .rx,
                portnum: Int(Meshtastic_PortNum.textMessageApp.rawValue),
                summary: "RX text · \(name): \(text)",
                rawHex: raw.shortHex(), fromNodeNum: Int(fromNum)
            ))

        case .nodeInfo(let user):
            let num = Int(fromNum)
            let existing = knownNodes[num]
            knownNodes[num] = KnownNode(
                id: num,
                shortName: user.shortName,
                longName: user.longName,
                lastHeard: now,
                snr: existing?.snr,
                rssi: existing?.rssi,
                batteryLevel: existing?.batteryLevel,
                latitudeI: existing?.latitudeI,
                longitudeI: existing?.longitudeI,
                snrHistory: existing?.snrHistory ?? []
            )
            appendTraffic(.init(
                id: UUID(), timestamp: now, direction: .rx,
                portnum: Int(Meshtastic_PortNum.nodeinfoApp.rawValue),
                summary: "RX nodeinfo · \(user.shortName) (\(user.longName))",
                rawHex: raw.shortHex(), fromNodeNum: Int(fromNum)
            ))

        case .position(let pos):
            let num = Int(fromNum)
            if var existing = knownNodes[num] {
                if pos.latitudeI != 0 { existing.latitudeI = pos.latitudeI }
                if pos.longitudeI != 0 { existing.longitudeI = pos.longitudeI }
                existing.lastHeard = now
                knownNodes[num] = existing
            }
            appendTraffic(.init(
                id: UUID(), timestamp: now, direction: .rx,
                portnum: Int(Meshtastic_PortNum.positionApp.rawValue),
                summary: "RX position · \(displayName(forNodeNum: fromNum))",
                rawHex: raw.shortHex(), fromNodeNum: Int(fromNum)
            ))

        case .telemetry(let tele):
            let num = Int(fromNum)
            if var existing = knownNodes[num] {
                let bl = Int(tele.deviceMetrics.batteryLevel)
                if bl != 0 { existing.batteryLevel = bl }
                existing.lastHeard = now
                knownNodes[num] = existing
            }
            appendTraffic(.init(
                id: UUID(), timestamp: now, direction: .rx,
                portnum: Int(Meshtastic_PortNum.telemetryApp.rawValue),
                summary: "RX telemetry · \(displayName(forNodeNum: fromNum))",
                rawHex: raw.shortHex(), fromNodeNum: Int(fromNum)
            ))

        case .routing:
            appendTraffic(.init(
                id: UUID(), timestamp: now, direction: .rx,
                portnum: Int(Meshtastic_PortNum.routingApp.rawValue),
                summary: "RX routing",
                rawHex: raw.shortHex(), fromNodeNum: Int(fromNum)
            ))

        case .encrypted:
            appendTraffic(.init(
                id: UUID(), timestamp: now, direction: .rx,
                portnum: nil,
                summary: "RX encrypted · from=\(displayName(forNodeNum: fromNum))",
                rawHex: raw.shortHex(), fromNodeNum: Int(fromNum)
            ))

        case .other(let portnum):
            appendTraffic(.init(
                id: UUID(), timestamp: now, direction: .rx,
                portnum: Int(portnum.rawValue),
                summary: "RX \(portnum) · from=\(displayName(forNodeNum: fromNum))",
                rawHex: raw.shortHex(), fromNodeNum: Int(fromNum)
            ))
        }
    }

    private func envelopeKindLabel(_ env: Meshtastic_FromRadio) -> String {
        switch env.payloadVariant {
        case .config:                 return "config"
        case .moduleConfig:           return "moduleConfig"
        case .queueStatus:            return "queueStatus"
        case .metadata:               return "metadata"
        case .fileInfo:               return "fileInfo"
        case .clientNotification:     return "clientNotification"
        case .deviceuiConfig:         return "deviceuiConfig"
        case .mqttClientProxyMessage: return "mqttClientProxyMessage"
        case .xmodemPacket:           return "xmodemPacket"
        case .rebooted:               return "rebooted"
        default:                      return "unknown envelope"
        }
    }
}

// MARK: - Data hex helpers

extension Data {
    /// Hex dump, capped at 64 bytes (128 chars + ellipsis) so very long
    /// envelopes don't blow up the TRAFFIC log layout. The full payload is
    /// still in the protobuf message; this is for the human-readable row.
    func shortHex(maxBytes: Int = 64) -> String {
        let prefix = self.prefix(maxBytes)
        let hex = prefix.map { String(format: "%02x", $0) }.joined()
        return self.count > maxBytes ? hex + "…" : hex
    }
}
