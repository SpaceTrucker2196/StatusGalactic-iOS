import Foundation

/// Extract real ham callsigns from an APRS path string. The path is the
/// comma-separated chain of digipeaters / igates the packet bounced
/// through before reaching aprs.fi, e.g.
///   "WIDE1-1,WIDE2-1,W9ABC*,WB1XYZ-2,qAR,K1ABC"
///
/// We strip:
///   • the trailing "*" markers that flag the last station to relay
///   • generic alias tokens (WIDE, TRACE, RELAY, ECHO, NOCALL, APRS*)
///   • igate flags (qAR, qAO, qAC, qAU, qAS, qAo, qAX, qAI)
/// What's left is the actual ham callsigns that touched the packet —
/// each one is a real station we can locate via aprs.fi and credit
/// against the user's DX stats.
enum APRSPathParser {
    static let genericExact: Set<String> = [
        "RELAY", "ECHO", "NOCALL",
        "TCPIP", "TCPXX",
        "APRS", "APRSIS", "APRSCE", "APRSGB", "APRX", "APRSCH",
    ]

    /// Returns the callsigns in `path` that look like real ham IDs.
    /// Order is preserved (path order, closest digi first).
    static func realCallsigns(in path: String) -> [String] {
        path
            .split(whereSeparator: { ",;|".contains($0) || $0.isWhitespace })
            .map { String($0).trimmingCharacters(in: CharacterSet(charactersIn: "*?")) }
            .filter(isHamCallsign)
    }

    /// Looser than the FCC-style strict regex because international
    /// callsigns have varied shapes; we just exclude obvious generics +
    /// require digits and letters to be present.
    static func isHamCallsign(_ token: String) -> Bool {
        let base = token.split(separator: "-").first.map(String.init) ?? token
        let upper = base.uppercased()
        if upper.isEmpty { return false }
        if genericExact.contains(upper) { return false }
        if upper.hasPrefix("WIDE") || upper.hasPrefix("TRACE") { return false }
        if upper.hasPrefix("Q") && upper.count <= 3 {
            // igate qA* flags
            return false
        }
        // Need at least one digit + one letter and 3..6 alphanumerics.
        let hasDigit = upper.contains { $0.isNumber }
        let hasLetter = upper.contains { $0.isLetter }
        guard hasDigit, hasLetter else { return false }
        guard upper.allSatisfy({ $0.isLetter || $0.isNumber }) else { return false }
        return (3...6).contains(upper.count)
    }
}
