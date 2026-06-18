import Foundation
import CoreBluetooth

/// CoreBluetooth wrapper for the Meshtastic GATT profile.
///
/// The Meshtastic node exposes a single service with four characteristics:
///   - `FromRadio` (read)   — phone reads one `FromRadio` protobuf per read
///   - `ToRadio`   (write)  — phone writes one `ToRadio`   protobuf per write
///   - `FromNum`   (notify) — pending-packet counter; on notify, drain `FromRadio`
///                            with repeated reads until a read returns empty bytes
///   - `LogRadio`  (notify) — device log stream as `LogRecord` protobufs
///
/// This type owns no protobuf knowledge — it ships raw `Data` to its delegate.
/// `MeshtasticService` decodes and routes those bytes.
@MainActor
final class MeshtasticBLETransport: NSObject, MeshtasticTransport {

    // MARK: - GATT UUIDs

    /// Meshtastic primary service. Sourced from the upstream
    /// `meshtastic/firmware` device client API doc.
    nonisolated static let serviceUUID    = CBUUID(string: "6BA1B218-15A8-461F-9FA8-5DCAE273EAFD")
    nonisolated static let fromRadioChar  = CBUUID(string: "2C55E69E-4993-11ED-B878-0242AC120002")
    nonisolated static let toRadioChar    = CBUUID(string: "F75C76D2-129E-4DAD-A1DD-7866124401E7")
    nonisolated static let fromNumChar    = CBUUID(string: "ED9DA18C-A800-4F66-A670-AA7547E34453")
    nonisolated static let logRadioChar   = CBUUID(string: "5A3D6E49-06E6-4423-9944-E9DE8CDF9547")

    // MARK: - Delegate

    weak var delegate: MeshtasticTransportDelegate?

    // MARK: - Public state (mirrored to delegate)

    private(set) var state: MeshtasticConnectionState = .idle {
        didSet { if state != oldValue { delegate?.transportDidChangeState(state) } }
    }

    private(set) var discovered: [MeshtasticDiscoveredPeer] = [] {
        didSet { delegate?.transportDidUpdateDiscovered(discovered) }
    }

    // MARK: - Private

    private var central: CBCentralManager?
    private var peripheral: CBPeripheral?
    private var fromRadioChar: CBCharacteristic?
    private var toRadioChar:   CBCharacteristic?
    private var fromNumChar:   CBCharacteristic?
    private var logRadioChar:  CBCharacteristic?

    /// Set true when we've issued a read on `FromRadio` but haven't seen the
    /// completion yet. Used to serialise the drain loop — we only kick off
    /// another read after the previous one returns.
    private var drainInFlight = false
    /// We keep draining after a successful (non-empty) read. The loop exits
    /// the first time a read returns an empty payload.
    private var keepDraining = false

    /// Pending bytes to write once we've discovered the ToRadio char. Sends
    /// issued before connection finalises get buffered here.
    private var pendingWrites: [Data] = []

    // MARK: - Lifecycle

    /// Construct lazily — instantiating `CBCentralManager` in `init` triggers
    /// the BT permission prompt the first time the app launches. We want
    /// that to happen only when the user opens the Mesh tab.
    func powerOn() {
        guard central == nil else { return }
        central = CBCentralManager(delegate: self, queue: .main, options: [
            CBCentralManagerOptionShowPowerAlertKey: true
        ])
    }

    // MARK: - Public API

    func startScan() {
        guard let central, central.state == .poweredOn else {
            powerOn()
            return
        }
        discovered = []
        central.scanForPeripherals(
            withServices: [Self.serviceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
        state = .scanning
    }

    func stopScan() {
        central?.stopScan()
        if case .scanning = state { state = .idle }
    }

    func connect(_ id: UUID) {
        guard let central else { return }
        guard let target = central.retrievePeripherals(withIdentifiers: [id]).first
            ?? discovered.first(where: { $0.id == id }).flatMap({ _ in peripheral })
        else { return }
        stopScan()
        peripheral = target
        target.delegate = self
        state = .connecting(peripheralName: target.name ?? "Meshtastic")
        central.connect(target, options: nil)
    }

    func disconnect() {
        guard let central, let peripheral else { return }
        state = .disconnecting
        central.cancelPeripheralConnection(peripheral)
    }

    /// Write a serialised `ToRadio` protobuf to the node. Buffers if the
    /// connection isn't fully wired up yet.
    func send(_ data: Data) {
        guard let peripheral, let char = toRadioChar else {
            pendingWrites.append(data)
            return
        }
        peripheral.writeValue(data, for: char, type: .withResponse)
    }

    // MARK: - Internal helpers

    private func resetCharacteristics() {
        fromRadioChar = nil
        toRadioChar = nil
        fromNumChar = nil
        logRadioChar = nil
        drainInFlight = false
        keepDraining = false
    }

    /// Kick off (or continue) the FromRadio drain loop. Idempotent — if a
    /// read is already in flight we just remember to keep going.
    fileprivate func requestDrain() {
        guard let peripheral, let char = fromRadioChar else { return }
        if drainInFlight {
            keepDraining = true
            return
        }
        drainInFlight = true
        peripheral.readValue(for: char)
    }
}

// MARK: - CBCentralManagerDelegate

extension MeshtasticBLETransport: CBCentralManagerDelegate {

    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let newState = central.state
        Task { @MainActor in
            switch newState {
            case .poweredOn:
                if case .bluetoothOff = state { state = .idle }
                if case .bluetoothUnauthorized = state { state = .idle }
            case .poweredOff:
                state = .bluetoothOff
            case .unauthorized:
                state = .bluetoothUnauthorized
            case .unsupported:
                state = .bluetoothUnsupported
            default:
                state = .idle
            }
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let name = peripheral.name
            ?? (advertisementData[CBAdvertisementDataLocalNameKey] as? String)
            ?? "Meshtastic"
        let id = peripheral.identifier
        let rssi = RSSI.intValue
        Task { @MainActor in
            // Hold the discovered CBPeripheral so we can connect by id.
            // We stash it in `self.peripheral` only on the connect call,
            // but we also need it alive — CoreBluetooth retains advertising
            // peripherals while scanning is active.
            if let existing = self.discovered.firstIndex(where: { $0.id == id }) {
                self.discovered[existing] = .init(id: id, name: name, rssi: rssi)
            } else {
                self.discovered.append(.init(id: id, name: name, rssi: rssi))
            }
            // Keep the CBPeripheral instance alive past the scan callback.
            self.peripheral = peripheral
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Task { @MainActor in
            peripheral.discoverServices([Self.serviceUUID])
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        let msg = error?.localizedDescription ?? "failed to connect"
        Task { @MainActor in
            self.state = .failed(msg)
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        Task { @MainActor in
            self.resetCharacteristics()
            if let error { self.state = .failed(error.localizedDescription) }
            else { self.state = .idle }
        }
    }
}

// MARK: - CBPeripheralDelegate

extension MeshtasticBLETransport: CBPeripheralDelegate {

    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        let chars: [CBUUID] = [
            Self.fromRadioChar, Self.toRadioChar, Self.fromNumChar, Self.logRadioChar
        ]
        for service in services where service.uuid == Self.serviceUUID {
            peripheral.discoverCharacteristics(chars, for: service)
        }
    }

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        guard let chars = service.characteristics else { return }
        Task { @MainActor in
            for c in chars {
                switch c.uuid {
                case Self.fromRadioChar: self.fromRadioChar = c
                case Self.toRadioChar:   self.toRadioChar   = c
                case Self.fromNumChar:
                    self.fromNumChar = c
                    peripheral.setNotifyValue(true, for: c)
                case Self.logRadioChar:
                    self.logRadioChar = c
                    peripheral.setNotifyValue(true, for: c)
                default:
                    break
                }
            }
            self.state = .connected(peripheralName: peripheral.name ?? "Meshtastic")
            // Flush any writes queued before we had the char handle.
            if let to = self.toRadioChar {
                for data in self.pendingWrites {
                    peripheral.writeValue(data, for: to, type: .withResponse)
                }
                self.pendingWrites.removeAll()
            }
            // Kick the initial drain so we see streamed config / node info.
            self.requestDrain()
        }
    }

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        let value = characteristic.value ?? Data()
        let uuid = characteristic.uuid
        Task { @MainActor in
            switch uuid {
            case Self.fromRadioChar:
                self.drainInFlight = false
                if value.isEmpty {
                    // Drain complete. Stay quiet until next FromNum notify.
                    if self.keepDraining {
                        self.keepDraining = false
                        self.requestDrain()
                    }
                } else {
                    self.delegate?.transportDidReceiveFromRadioBytes(value)
                    // Keep draining until we hit an empty read.
                    self.requestDrain()
                }
            case Self.fromNumChar:
                // Notification counter ticked — node has packets for us.
                self.requestDrain()
            case Self.logRadioChar:
                if !value.isEmpty {
                    self.delegate?.transportDidReceiveLogRadioBytes(value)
                }
            default:
                break
            }
        }
    }

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didWriteValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        // Nothing to do — writes are fire-and-forget at this layer. Errors
        // surface as disconnects via the central delegate.
    }
}
