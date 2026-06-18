import XCTest
import SwiftProtobuf
@testable import StatusGalactic

/// End-to-end tests for `MeshtasticService` driven by `FakeMeshtasticTransport`.
/// No CoreBluetooth, no real BLE — every callback is synchronous on the
/// main actor so we can assert state immediately after the stimulus.
@MainActor
final class MeshtasticServiceTests: XCTestCase {

    // MARK: - Harness

    private func makeService() -> (MeshtasticService, FakeMeshtasticTransport) {
        let fake = FakeMeshtasticTransport()
        let svc = MeshtasticService(inMemoryStore: true, transport: fake)
        return (svc, fake)
    }

    // MARK: - Intent wiring

    func testAppearedPowersOnTheTransport() {
        let (svc, fake) = makeService()
        XCTAssertEqual(fake.powerOnCount, 0)
        svc.appeared()
        XCTAssertEqual(fake.powerOnCount, 1)
    }

    func testStartScanForwardsToTransport() {
        let (svc, fake) = makeService()
        svc.startScan()
        XCTAssertEqual(fake.startScanCount, 1)
    }

    func testConnectForwardsTheIDToTransport() {
        let (svc, fake) = makeService()
        let id = UUID()
        svc.connect(id)
        XCTAssertEqual(fake.connectCalls, [id])
    }

    // MARK: - Connection state mapping

    func testTransportStateMirrorsIntoStatus() {
        let (svc, fake) = makeService()
        XCTAssertEqual(svc.status, .idle)

        fake.simulateScanStarted()
        XCTAssertEqual(svc.status, .scanning)

        fake.simulateBluetoothOff()
        XCTAssertEqual(svc.status, .bluetoothOff)
    }

    func testDiscoveryUpdatesAreSurfaced() {
        let (svc, fake) = makeService()
        XCTAssertTrue(svc.discoveredNodes.isEmpty)

        fake.simulateDiscoverOne(name: "T-Beam 42", rssi: -60)
        XCTAssertEqual(svc.discoveredNodes.count, 1)
        XCTAssertEqual(svc.discoveredNodes.first?.name, "T-Beam 42")
        XCTAssertEqual(svc.discoveredNodes.first?.rssi, -60)
    }

    // MARK: - Handshake

    func testConnectFiresWantConfigHandshake() throws {
        let (svc, fake) = makeService()
        XCTAssertFalse(svc.handshakeComplete)
        XCTAssertTrue(fake.sentToRadio.isEmpty)

        fake.simulateConnect()

        // The service should immediately write a ToRadio { wantConfigID = N }.
        XCTAssertEqual(fake.sentToRadio.count, 1)
        let envelope = try Meshtastic_ToRadio(serializedBytes: fake.sentToRadio[0])
        guard case .wantConfigID(let id) = envelope.payloadVariant else {
            return XCTFail("Expected wantConfigID, got \(String(describing: envelope.payloadVariant))")
        }
        XCTAssertEqual(id, svc.pendingConfigID)
        XCTAssertNotEqual(id, 0)
    }

    func testConfigCompleteIDFlipsHandshakeFlag() {
        let (svc, fake) = makeService()
        fake.simulateConnect()
        XCTAssertFalse(svc.handshakeComplete)

        // Send back the matching configCompleteID and the service should
        // mark the handshake as done.
        fake.simulateFromRadio(.configCompleteID(svc.pendingConfigID))
        XCTAssertTrue(svc.handshakeComplete)
    }

    func testMismatchedConfigCompleteIDIsIgnored() {
        let (svc, fake) = makeService()
        fake.simulateConnect()
        fake.simulateFromRadio(.configCompleteID(svc.pendingConfigID &+ 1))
        XCTAssertFalse(svc.handshakeComplete)
    }

    // MARK: - Incoming text routing

    func testIncomingBroadcastTextLandsInChatAndTraffic() throws {
        let (svc, fake) = makeService()
        fake.simulateConnect()
        // Seed a nodeinfo so the chat row gets the friendly short name.
        fake.simulateFromRadio(.nodeInfo(nodeNum: 0xABCDEF01, shortName: "WX5", longName: "Wax Five"))

        fake.simulateFromRadio(.broadcastText(from: 0xABCDEF01, text: "hello mesh"))

        XCTAssertEqual(svc.chat.count, 1)
        let msg = try XCTUnwrap_(svc.chat.first, "expected one chat message")
        XCTAssertEqual(msg.text, "hello mesh")
        XCTAssertEqual(msg.fromName, "WX5")
        XCTAssertFalse(msg.isOutbound)

        // And the TRAFFIC log should carry an RX text row for it.
        XCTAssertTrue(
            svc.traffic.contains { $0.summary.contains("RX text") && $0.summary.contains("hello mesh") },
            "expected RX text entry in TRAFFIC, got: \(svc.traffic.map(\.summary))"
        )
    }

    func testIncomingNodeInfoPopulatesKnownNodes() throws {
        let (svc, fake) = makeService()
        XCTAssertTrue(svc.knownNodes.isEmpty)

        fake.simulateFromRadio(.nodeInfo(
            nodeNum: 0xDEADBEEF,
            shortName: "DB",
            longName: "Deadbeef Cafe",
            snr: 6.5,
            lastHeard: 1_700_000_000,
            batteryLevel: 78
        ))

        let node = try XCTUnwrap_(svc.knownNodes[Int(0xDEADBEEF)], "expected node entry")
        XCTAssertEqual(node.shortName, "DB")
        XCTAssertEqual(node.longName, "Deadbeef Cafe")
        XCTAssertEqual(node.snr, 6.5)
        XCTAssertEqual(node.batteryLevel, 78)
    }

    func testMyInfoCapturesOwnNodeNum() {
        let (svc, fake) = makeService()
        XCTAssertNil(svc.ownNodeNum)

        fake.simulateFromRadio(.myInfo(nodeNum: 0x12345678))
        XCTAssertEqual(svc.ownNodeNum, 0x12345678)
    }

    // MARK: - Outbound text

    func testSendBroadcastEncodesToRadioBytesAndMirrorsLocally() throws {
        let (svc, fake) = makeService()
        fake.simulateConnect()
        // Drop the handshake write so we can read the next one cleanly.
        let initialSentCount = fake.sentToRadio.count
        XCTAssertEqual(initialSentCount, 1, "expected handshake write")

        svc.sendBroadcast("hi there")

        XCTAssertEqual(fake.sentToRadio.count, initialSentCount + 1)
        let envelope = try Meshtastic_ToRadio(serializedBytes: fake.sentToRadio.last!)
        guard case .packet(let packet) = envelope.payloadVariant else {
            return XCTFail("Expected packet variant, got \(String(describing: envelope.payloadVariant))")
        }
        XCTAssertEqual(packet.to, 0xFFFF_FFFF, "broadcast address")
        XCTAssertEqual(packet.channel, 0, "primary channel")
        XCTAssertEqual(packet.decoded.portnum, .textMessageApp)
        XCTAssertEqual(String(data: packet.decoded.payload, encoding: .utf8), "hi there")

        // And the local mirror should also fire.
        XCTAssertEqual(svc.chat.last?.text, "hi there")
        XCTAssertEqual(svc.chat.last?.isOutbound, true)
        XCTAssertTrue(svc.traffic.contains { $0.direction == .tx && $0.summary.contains("hi there") })
    }

    func testSendBroadcastIsNoOpWhenNotConnected() {
        let (svc, fake) = makeService()
        XCTAssertEqual(svc.status, .idle)

        svc.sendBroadcast("nope")

        XCTAssertTrue(fake.sentToRadio.isEmpty)
        XCTAssertTrue(svc.chat.isEmpty)
    }

    func testSendBroadcastIgnoresBlankInput() {
        let (svc, fake) = makeService()
        fake.simulateConnect()
        let sentBeforeBlank = fake.sentToRadio.count

        svc.sendBroadcast("   \n  ")

        XCTAssertEqual(fake.sentToRadio.count, sentBeforeBlank, "blank input shouldn't transmit")
        XCTAssertTrue(svc.chat.isEmpty)
    }

    // MARK: - Device log

    func testLogRecordAppendsToDeviceLogWithLevelTag() {
        let (svc, fake) = makeService()
        XCTAssertTrue(svc.deviceLog.isEmpty)

        fake.simulateLogRecord(.info("Boot complete", source: "Router"))

        XCTAssertEqual(svc.deviceLog.count, 1)
        let line = svc.deviceLog[0]
        XCTAssertTrue(line.contains("INFO"), "expected INFO tag, got: \(line)")
        XCTAssertTrue(line.contains("Router"))
        XCTAssertTrue(line.contains("Boot complete"))
    }

    // MARK: - Clear history

    func testClearHistoryEmptiesEverything() {
        let (svc, fake) = makeService()
        fake.simulateConnect()
        fake.simulateFromRadio(.broadcastText(from: 1, text: "first"))
        fake.simulateLogRecord(.info("hi", source: "Test"))
        XCTAssertFalse(svc.traffic.isEmpty)
        XCTAssertFalse(svc.chat.isEmpty)
        XCTAssertFalse(svc.deviceLog.isEmpty)

        svc.clearHistory()

        XCTAssertTrue(svc.traffic.isEmpty)
        XCTAssertTrue(svc.chat.isEmpty)
        XCTAssertTrue(svc.deviceLog.isEmpty)
    }

    // MARK: - Disconnect

    func testDisconnectIntentReachesTransport() {
        let (svc, fake) = makeService()
        svc.disconnect()
        XCTAssertEqual(fake.disconnectCount, 1)
    }
}

// MARK: - Tiny XCTUnwrap shim

/// `XCTUnwrap` is `throws`; some of our test bodies are not `throws`. This
/// shim asserts + force-returns so a single test failure doesn't cascade
/// into "Optional unwrap of nil" crashes on the test runner.
@MainActor
private func XCTUnwrap_<T>(
    _ value: T?,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) throws -> T {
    guard let unwrapped = value else {
        XCTFail("XCTUnwrap_ failed: \(message())", file: file, line: line)
        throw NSError(domain: "XCTUnwrap_", code: 0)
    }
    return unwrapped
}
