import Foundation
import SwiftProtobuf
@testable import StatusGalactic

/// In-memory `MeshtasticTransport` for tests. No CoreBluetooth, no async
/// dispatch — every callback fires synchronously on the main actor so tests
/// can assert state immediately after stimulus.
///
/// Use the `simulate*` helpers to drive the service through realistic
/// scenarios (peripheral discovered, connection established, FromRadio
/// envelopes arriving, LogRecord notifications, disconnect). All writes
/// the service issues are recorded in `sentToRadio` so tests can decode
/// them back into protobufs and assert the wire format.
@MainActor
final class FakeMeshtasticTransport: MeshtasticTransport {

    // MARK: - MeshtasticTransport surface

    weak var delegate: MeshtasticTransportDelegate?

    /// Every byte payload the service handed us via `send`, in order.
    /// Decode with `Meshtastic_ToRadio(serializedBytes:)` to assert.
    private(set) var sentToRadio: [Data] = []

    /// How many times `powerOn`, `startScan`, `stopScan`, and `disconnect`
    /// have been invoked. Useful for asserting view-layer intents wired
    /// through to the transport.
    private(set) var powerOnCount: Int = 0
    private(set) var startScanCount: Int = 0
    private(set) var stopScanCount: Int = 0
    private(set) var disconnectCount: Int = 0

    /// `connect(_:)` invocations, in order. The id is whatever the caller
    /// passed — the fake doesn't validate against discovered peers.
    private(set) var connectCalls: [UUID] = []

    func powerOn()  { powerOnCount  += 1 }
    func startScan(){ startScanCount += 1 }
    func stopScan() { stopScanCount  += 1 }
    func disconnect() {
        disconnectCount += 1
        delegate?.transportDidChangeState(.idle)
    }
    func connect(_ id: UUID) {
        connectCalls.append(id)
    }
    func send(_ data: Data) {
        sentToRadio.append(data)
    }

    // MARK: - Stimulus helpers

    /// Publish a list of discovered peers to the service.
    func simulateDiscovered(_ peers: [MeshtasticDiscoveredPeer]) {
        delegate?.transportDidUpdateDiscovered(peers)
    }

    /// Make up a discovered peer for convenience.
    @discardableResult
    func simulateDiscoverOne(
        name: String = "T-Beam 42",
        rssi: Int = -52,
        id: UUID = UUID()
    ) -> MeshtasticDiscoveredPeer {
        let peer = MeshtasticDiscoveredPeer(id: id, name: name, rssi: rssi)
        simulateDiscovered([peer])
        return peer
    }

    /// Push the connection state machine through the same transitions a
    /// real connect would: idle → connecting → connected. The service
    /// fires the want-config handshake on the connected transition.
    func simulateConnect(name: String = "T-Beam 42") {
        delegate?.transportDidChangeState(.connecting(peripheralName: name))
        delegate?.transportDidChangeState(.connected(peripheralName: name))
    }

    func simulateDisconnect() {
        delegate?.transportDidChangeState(.disconnecting)
        delegate?.transportDidChangeState(.idle)
    }

    func simulateBluetoothOff() {
        delegate?.transportDidChangeState(.bluetoothOff)
    }

    func simulateScanStarted() {
        delegate?.transportDidChangeState(.scanning)
    }

    /// Ship a `FromRadio` protobuf to the service as if the node had streamed it.
    func simulateFromRadio(_ msg: Meshtastic_FromRadio) {
        guard let bytes = try? msg.serializedBytes() as Data else {
            XCTFailFromActor("FromRadio failed to serialise — fixture is bad")
            return
        }
        delegate?.transportDidReceiveFromRadioBytes(bytes)
    }

    /// Ship a `LogRecord` protobuf as if it arrived on the LogRadio
    /// notify characteristic.
    func simulateLogRecord(_ msg: Meshtastic_LogRecord) {
        guard let bytes = try? msg.serializedBytes() as Data else {
            XCTFailFromActor("LogRecord failed to serialise — fixture is bad")
            return
        }
        delegate?.transportDidReceiveLogRadioBytes(bytes)
    }
}

// MARK: - Fixture builders

extension Meshtastic_FromRadio {
    /// `FromRadio { my_info { my_node_num = N } }`
    static func myInfo(nodeNum: UInt32) -> Self {
        var msg = Self()
        var info = Meshtastic_MyNodeInfo()
        info.myNodeNum = nodeNum
        msg.myInfo = info
        return msg
    }

    /// `FromRadio { node_info { num=N, user{ short, long }, snr, last_heard } }`
    static func nodeInfo(
        nodeNum: UInt32,
        shortName: String,
        longName: String,
        snr: Float = 0,
        lastHeard: UInt32 = 0,
        batteryLevel: UInt32 = 0
    ) -> Self {
        var msg = Self()
        var info = Meshtastic_NodeInfo()
        info.num = nodeNum
        var user = Meshtastic_User()
        user.id = String(format: "!%08x", nodeNum)
        user.shortName = shortName
        user.longName = longName
        info.user = user
        info.snr = snr
        info.lastHeard = lastHeard
        if batteryLevel > 0 {
            var metrics = Meshtastic_DeviceMetrics()
            metrics.batteryLevel = batteryLevel
            info.deviceMetrics = metrics
        }
        msg.nodeInfo = info
        return msg
    }

    /// `FromRadio { config_complete_id = id }`
    static func configCompleteID(_ id: UInt32) -> Self {
        var msg = Self()
        msg.configCompleteID = id
        return msg
    }

    /// `FromRadio { packet { from=N, decoded { portnum=TEXT_MESSAGE_APP, payload=utf8 } } }`
    static func broadcastText(
        from: UInt32,
        text: String,
        channel: UInt32 = 0,
        packetID: UInt32 = 1
    ) -> Self {
        var data = Meshtastic_Data()
        data.portnum = .textMessageApp
        data.payload = Data(text.utf8)
        var packet = Meshtastic_MeshPacket()
        packet.from = from
        packet.to = 0xFFFF_FFFF
        packet.channel = channel
        packet.id = packetID
        packet.decoded = data
        var msg = Self()
        msg.packet = packet
        return msg
    }
}

extension Meshtastic_LogRecord {
    static func info(_ text: String, source: String = "Router") -> Self {
        var rec = Self()
        rec.message = text
        rec.source = source
        rec.level = .info
        return rec
    }
}

// MARK: - XCTest bridge

import XCTest

/// `XCTFail` isn't `@MainActor`-isolated but we want to call it from one —
/// this trampoline keeps the fixture builders ergonomic.
@MainActor
private func XCTFailFromActor(_ message: String, file: StaticString = #filePath, line: UInt = #line) {
    XCTFail(message, file: file, line: line)
}
