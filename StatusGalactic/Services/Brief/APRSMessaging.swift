import Foundation

struct APRSMessage: Codable, Identifiable, Hashable {
    var id: String { messageID + sentAt.ISO8601Format() }
    let messageID: String
    let from: String
    let to: String
    let text: String
    let sentAt: Date
    let direction: Direction
    let acknowledged: Bool

    enum Direction: String, Codable, Hashable {
        case incoming
        case outgoing
    }

    /// True when the message was addressed to an APRS bulletin / broadcast
    /// destination (`BLN*`, `ARL*`, `NWS-*`, `ALL`) rather than a single
    /// callsign.
    var isBulletin: Bool {
        let upper = to.uppercased()
        return upper.hasPrefix("BLN")
            || upper.hasPrefix("ARL")
            || upper.hasPrefix("NWS-")
            || upper == "ALL"
    }
}

/// APRS-IS messaging:
///   - send via HTTP POST to srvr.aprs-is.net:8080 (plain HTTP, ATS exception)
///   - receive via aprs.fi `/api/get?what=msg&dst=CALLSIGN&apikey=...`
///
/// Send requires the sender's APRS-IS passcode, which is computed
/// deterministically from the base callsign. Use `APRSMessaging.passcode(for:)`.
struct APRSMessaging {

    static let sendURL = URL(string: "http://srvr.aprs-is.net:8080")!
    static let receiveURL = URL(string: "https://api.aprs.fi/api/get")!

    let session: URLSession
    let userAgent: String

    init(session: URLSession = .shared, userAgent: String) {
        self.session = session
        self.userAgent = userAgent
    }

    // MARK: - Passcode

    /// APRS-IS passcode for a callsign. Strips the SSID (`-N`), uppercases,
    /// and applies the standard XOR algorithm.
    static func passcode(for rawCallsign: String) -> Int {
        let base = rawCallsign.split(separator: "-").first.map(String.init) ?? rawCallsign
        let upper = base.uppercased()
        var h: Int = 0x73e2
        let chars = Array(upper.unicodeScalars)
        var i = 0
        while i < chars.count {
            h ^= Int(chars[i].value) << 8
            if i + 1 < chars.count {
                h ^= Int(chars[i + 1].value)
            }
            i += 2
        }
        return h & 0x7fff
    }

    // MARK: - Send

    /// Submit an APRS message via APRS-IS HTTP. Returns the message ID used.
    @discardableResult
    func send(
        from sender: String,
        to recipient: String,
        text: String,
        messageNumber: Int
    ) async throws -> String {
        let senderUpper = sender.trimmingCharacters(in: .whitespaces).uppercased()
        let recipientUpper = recipient.trimmingCharacters(in: .whitespaces).uppercased()
        guard !senderUpper.isEmpty, !recipientUpper.isEmpty else {
            throw HTTPError.invalidURL
        }
        let pass = Self.passcode(for: senderUpper)
        let idStr = String(format: "%03d", messageNumber % 1000)
        // Recipient padded to exactly 9 chars per APRS spec.
        let paddedTo = recipientUpper.padding(toLength: 9, withPad: " ", startingAt: 0)
        // Trim message to 67 chars per APRS spec (the packet has a 67-char limit).
        let truncatedText = text.count > 67 ? String(text.prefix(67)) : text

        let body =
            "user \(senderUpper) pass \(pass) vers StatusGalactic 0.2\r\n" +
            "\(senderUpper)>APRS,TCPIP*::\(paddedTo):\(truncatedText){\(idStr)"

        var request = URLRequest(url: Self.sendURL)
        request.httpMethod = "POST"
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.httpBody = body.data(using: .utf8)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw HTTPError.transport(error)
        }
        guard let http = response as? HTTPURLResponse else {
            throw HTTPError.badResponse(status: -1, body: nil)
        }
        // APRS-IS returns 204 No Content on success; 200 is also seen in the wild.
        guard (200..<300).contains(http.statusCode) else {
            throw HTTPError.badResponse(
                status: http.statusCode,
                body: String(data: data, encoding: .utf8)
            )
        }
        return idStr
    }

    // MARK: - Receive

    /// Common APRS bulletin destinations. BLN1-3 are catch-all bulletins,
    /// ARL001-005 are ARRL bulletins (numbers change weekly), NWS-XXX is
    /// the National Weather Service prefix.
    static let commonBulletinDestinations = [
        "BLN1", "BLN2", "BLN3",
        "ARL001", "ARL002", "ARL003",
    ]

    /// Fetch APRS bulletins from a set of common destinations. Each is a
    /// separate aprs.fi call; failures are swallowed and the function returns
    /// whatever did come back.
    func receiveBulletins(
        destinations: [String] = Self.commonBulletinDestinations,
        apiKey: String
    ) async throws -> [APRSMessage] {
        var collected: [APRSMessage] = []
        for dst in destinations {
            if let msgs = try? await receive(forCallsign: dst, apiKey: apiKey) {
                collected.append(contentsOf: msgs)
            }
        }
        return collected
    }

    /// Fetch messages addressed to `callsign` via the aprs.fi read API.
    func receive(forCallsign callsign: String, apiKey: String) async throws -> [APRSMessage] {
        guard !apiKey.isEmpty else {
            throw HTTPError.badResponse(status: 401, body: "Set your aprs.fi API key in Settings.")
        }
        var components = URLComponents(url: Self.receiveURL, resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "what", value: "msg"),
            URLQueryItem(name: "dst", value: callsign.uppercased()),
            URLQueryItem(name: "apikey", value: apiKey),
            URLQueryItem(name: "format", value: "json"),
        ]
        guard let url = components.url else { throw HTTPError.invalidURL }

        let data = try await session.getData(from: url, userAgent: userAgent)
        guard let payload = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw HTTPError.decoding(NSError(domain: "aprs.msg", code: -1))
        }
        guard (payload["result"] as? String) == "ok" else {
            let desc = (payload["description"] as? String) ?? "aprs.fi error"
            throw HTTPError.badResponse(status: 502, body: desc)
        }
        let entries = (payload["entries"] as? [[String: Any]]) ?? []
        return entries.compactMap(Self.parseEntry)
    }

    private static func parseEntry(_ entry: [String: Any]) -> APRSMessage? {
        guard
            let srccall = entry["srccall"] as? String,
            let dst = entry["dst"] as? String,
            let message = entry["message"] as? String
        else { return nil }

        let timeRaw = entry["time"] as? String
        let timeInt = (timeRaw.flatMap(Int.init)) ?? (entry["time"] as? Int)
        let sentAt = timeInt.map { Date(timeIntervalSince1970: TimeInterval($0)) } ?? Date()

        let messageID = (entry["messageid"] as? String) ?? "\(srccall)-\(sentAt.timeIntervalSince1970)"
        return APRSMessage(
            messageID: messageID,
            from: srccall.uppercased(),
            to: dst.uppercased(),
            text: message,
            sentAt: sentAt,
            direction: .incoming,
            acknowledged: false
        )
    }
}
