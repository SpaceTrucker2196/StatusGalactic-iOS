import Foundation

/// Transport-agnostic state model for the Meshtastic connection.
///
/// `MeshtasticBLETransport` produces these; `MeshtasticService` consumes them.
/// A fake/in-memory transport (used by the test target) is the second
/// implementation — the protocol exists so the service has no compile-time
/// dependency on CoreBluetooth.
enum MeshtasticConnectionState: Equatable {
    case bluetoothOff
    case bluetoothUnauthorized
    case bluetoothUnsupported
    case idle
    case scanning
    case connecting(peripheralName: String)
    case connected(peripheralName: String)
    case disconnecting
    case failed(String)
}

struct MeshtasticDiscoveredPeer: Identifiable, Hashable {
    let id: UUID
    let name: String
    let rssi: Int
}

/// Callbacks fired by the transport on the main actor. The service adopts
/// this; tests can also adopt it to observe a fake transport directly.
@MainActor
protocol MeshtasticTransportDelegate: AnyObject {
    func transportDidChangeState(_ state: MeshtasticConnectionState)
    func transportDidUpdateDiscovered(_ peers: [MeshtasticDiscoveredPeer])
    func transportDidReceiveFromRadioBytes(_ data: Data)
    func transportDidReceiveLogRadioBytes(_ data: Data)
}

/// The contract the service uses to drive a Meshtastic node.
/// Real implementation: `MeshtasticBLETransport` (CoreBluetooth).
/// Test implementation: `FakeMeshtasticTransport` in the test target.
@MainActor
protocol MeshtasticTransport: AnyObject {
    var delegate: MeshtasticTransportDelegate? { get set }

    /// Construct any backing OS objects (e.g. `CBCentralManager`) lazily.
    /// Triggers the BT permission prompt the first time the user opens the
    /// Mesh tab — see `MeshtasticService.appeared()`.
    func powerOn()

    func startScan()
    func stopScan()
    func connect(_ id: UUID)
    func disconnect()

    /// Write a serialised `ToRadio` protobuf to the node.
    func send(_ data: Data)
}
