import Foundation
import SwiftProtobuf

/// Stateless protobuf helpers — turn `Data` into typed Meshtastic events,
/// and build `ToRadio` payloads for outbound writes.
///
/// All wire-format knowledge lives here. `MeshtasticService` calls into this
/// type; the BLE transport is byte-only.
enum MeshtasticPacketCodec {

    /// One decoded `FromRadio` envelope, narrowed to the variants we route on.
    /// `unhandled` carries through everything we don't have explicit handling
    /// for so the TRAFFIC log can still show it.
    enum DecodedFromRadio {
        case meshPacket(Meshtastic_MeshPacket)
        case myInfo(Meshtastic_MyNodeInfo)
        case nodeInfo(Meshtastic_NodeInfo)
        case logRecord(Meshtastic_LogRecord)
        case configCompleteID(UInt32)
        case channel(Meshtastic_Channel)
        case unhandled(Meshtastic_FromRadio)
    }

    /// Payload classification for a `MeshPacket`'s `Data` block. Drives
    /// the TRAFFIC routing in the service.
    enum AppPayload {
        case text(String)
        case nodeInfo(Meshtastic_User)
        case position(Meshtastic_Position)
        case telemetry(Meshtastic_Telemetry)
        case routing(Meshtastic_Routing)
        case encrypted
        case other(portnum: Meshtastic_PortNum)
    }

    // MARK: - Decode

    static func decodeFromRadio(_ data: Data) -> Result<DecodedFromRadio, Error> {
        do {
            let env = try Meshtastic_FromRadio(serializedBytes: data)
            switch env.payloadVariant {
            case .packet(let p):           return .success(.meshPacket(p))
            case .myInfo(let info):        return .success(.myInfo(info))
            case .nodeInfo(let info):      return .success(.nodeInfo(info))
            case .logRecord(let r):        return .success(.logRecord(r))
            case .configCompleteID(let i): return .success(.configCompleteID(i))
            case .channel(let c):          return .success(.channel(c))
            default:                       return .success(.unhandled(env))
            }
        } catch {
            return .failure(error)
        }
    }

    static func decodeLogRecord(_ data: Data) -> Meshtastic_LogRecord? {
        try? Meshtastic_LogRecord(serializedBytes: data)
    }

    /// Decode the `Data` payload of a `MeshPacket` into an app-level value
    /// by routing on its portnum. Returns `.encrypted` if the packet was an
    /// encrypted variant we don't have keys for.
    static func classify(_ packet: Meshtastic_MeshPacket) -> AppPayload {
        let data: Meshtastic_Data
        switch packet.payloadVariant {
        case .encrypted:
            return .encrypted
        case .decoded(let d):
            data = d
        case .none:
            // No payload variant set — treat as unknown port.
            return .other(portnum: .unknownApp)
        }
        switch data.portnum {
        case .textMessageApp:
            let text = String(data: data.payload, encoding: .utf8) ?? ""
            return .text(text)
        case .nodeinfoApp:
            if let u = try? Meshtastic_User(serializedBytes: data.payload) {
                return .nodeInfo(u)
            }
            return .other(portnum: .nodeinfoApp)
        case .positionApp:
            if let p = try? Meshtastic_Position(serializedBytes: data.payload) {
                return .position(p)
            }
            return .other(portnum: .positionApp)
        case .telemetryApp:
            if let t = try? Meshtastic_Telemetry(serializedBytes: data.payload) {
                return .telemetry(t)
            }
            return .other(portnum: .telemetryApp)
        case .routingApp:
            if let r = try? Meshtastic_Routing(serializedBytes: data.payload) {
                return .routing(r)
            }
            return .other(portnum: .routingApp)
        default:
            return .other(portnum: data.portnum)
        }
    }

    // MARK: - Encode

    /// Build the handshake `ToRadio` envelope. The phone sends this once on
    /// connect; the node streams its full DB back and terminates with a
    /// matching `configCompleteID` in `FromRadio`.
    static func wantConfig(id: UInt32) throws -> Data {
        var msg = Meshtastic_ToRadio()
        msg.wantConfigID = id
        return try msg.serializedBytes()
    }

    /// Build a broadcast text-message `ToRadio` envelope on the given
    /// channel index (0 = primary). Set `wantAck` if you want the node to
    /// surface delivery state back through TRAFFIC.
    static func broadcastText(
        _ text: String,
        channelIndex: UInt32 = 0,
        wantAck: Bool = false,
        packetID: UInt32 = UInt32.random(in: 1...UInt32.max)
    ) throws -> Data {
        var data = Meshtastic_Data()
        data.portnum = .textMessageApp
        data.payload = Data(text.utf8)

        var packet = Meshtastic_MeshPacket()
        // 0xFFFFFFFF = broadcast — see mesh.proto MeshPacket.to.
        packet.to = 0xFFFF_FFFF
        packet.channel = channelIndex
        packet.id = packetID
        packet.wantAck = wantAck
        packet.decoded = data

        var msg = Meshtastic_ToRadio()
        msg.packet = packet
        return try msg.serializedBytes()
    }

    /// Disconnect notice — optional courtesy write before BLE shutdown.
    static func disconnect() throws -> Data {
        var msg = Meshtastic_ToRadio()
        msg.disconnect = true
        return try msg.serializedBytes()
    }
}
