import Foundation

/// Map an APRS symbol code (two-char: symbol table + identifier) to a
/// usable SF Symbol name. Falls back to a generic antenna glyph when
/// the symbol is unrecognized or absent.
///
/// References: APRS specification 1.0.1 §16. Primary table (`/`) is the
/// canonical set; the alternate table (`\`) and per-overlay variants
/// share the same identifier semantics for our purposes, so we look up
/// only by the identifier character.
enum APRSSymbolIcon {
    static let defaultGlyph = "antenna.radiowaves.left.and.right"

    /// Returns an SF Symbol name for the given APRS symbol code (e.g.
    /// "/k" → "truck.box.fill"). Pass nil / empty → generic antenna.
    static func sfSymbol(for aprsCode: String?) -> String {
        guard let code = aprsCode else { return defaultGlyph }
        let trimmed = code.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 2 else { return defaultGlyph }
        let identifier = trimmed[trimmed.index(after: trimmed.startIndex)]
        return mapping[identifier] ?? defaultGlyph
    }

    /// Human-readable name for the same identifier — useful next to the
    /// glyph in the My Station panel.
    static func label(for aprsCode: String?) -> String? {
        guard let code = aprsCode, code.count >= 2 else { return nil }
        let identifier = code[code.index(after: code.startIndex)]
        return descriptions[identifier]
    }

    /// SF-Symbols-safe entries only. Keep this list aligned with iOS 17+
    /// — anything that doesn't render is silently displayed as the
    /// fallback antenna glyph by the system.
    private static let mapping: [Character: String] = [
        "!": "shield.fill",                  // police / sheriff
        "#": "dot.radiowaves.up.forward",    // digi
        "$": "phone.fill",
        "&": "antenna.radiowaves.left.and.right",  // HF gateway
        "'": "airplane",                     // small aircraft
        "(": "satellite.fill",               // mobile satellite station
        ")": "figure.roll",                  // wheelchair
        "*": "snowflake",                    // snowmobile
        "+": "cross.case.fill",              // red cross
        ",": "tent.fill",                    // boy scouts (camp)
        "-": "house.fill",                   // house
        "<": "bicycle",                      // motorcycle
        "=": "tram.fill",                    // railroad engine
        ">": "car.fill",                     // car
        "?": "server.rack",                  // server
        "@": "tornado",                      // hurricane / tropical
        "A": "cross.fill",                   // aid station
        "B": "doc.text.fill",                // BBS
        "C": "sailboat.fill",                // canoe
        "E": "eye.fill",                     // eyeball
        "F": "tractor.fill",                 // farm vehicle
        "H": "bed.double.fill",              // hotel
        "I": "network",                      // TCP/IP
        "J": "airplane",                     // jet
        "K": "graduationcap.fill",           // school
        "L": "desktopcomputer",              // PC user
        "M": "applelogo",                    // Mac apple
        "N": "envelope.fill",                // NTS
        "O": "balloon.fill",                 // balloon
        "P": "shield.fill",                  // police
        "R": "tent.2.fill",                  // recreational vehicle
        "S": "airplane",                     // shuttle
        "T": "tv.fill",                      // SSTV
        "U": "bus.fill",                     // bus
        "V": "tv.fill",                      // ATV
        "W": "cloud.bolt.fill",              // weather service
        "X": "airplane",                     // helicopter
        "Y": "sailboat.fill",                // yacht
        "Z": "envelope.arrow.triangle.branch.fill",  // WinLink user
        "[": "figure.run",                   // jogger
        "]": "envelope.fill",                // mail / post office
        "^": "airplane",                     // large aircraft
        "_": "cloud.sun.fill",               // weather station
        "`": "antenna.radiowaves.left.and.right.circle.fill", // dish
        "a": "cross.case.fill",              // ambulance
        "b": "bicycle",
        "c": "shield.lefthalf.filled",       // incident command post
        "d": "flame.fill",                   // fire dept
        "e": "hare.fill",                    // horse
        "f": "flame.fill",                   // fire truck
        "g": "airplane",                     // glider
        "h": "cross.fill",                   // hospital
        "i": "globe.americas.fill",          // IOTA
        "j": "car.fill",                     // jeep
        "k": "truck.box.fill",               // truck
        "l": "laptopcomputer",
        "n": "network",                      // node
        "o": "shield.checkered",             // EOC
        "p": "pawprint.fill",                // rover (dog)
        "r": "antenna.radiowaves.left.and.right",  // antenna
        "s": "ferry.fill",                   // ship
        "u": "truck.box.fill",               // truck 18-wheel
        "v": "car.2.fill",                   // van
        "w": "drop.fill",                    // water station
        "x": "globe",                        // xAPRS
        "y": "antenna.radiowaves.left.and.right",  // Yagi
        "z": "house.lodge.fill",             // shelter
    ]

    private static let descriptions: [Character: String] = [
        "!": "Police", "#": "Digipeater", "$": "Phone",
        "&": "HF Gateway", "'": "Small aircraft",
        "(": "Mobile satellite",
        ")": "Wheelchair", "*": "Snowmobile", "+": "Red Cross",
        ",": "Scouts (camp)", "-": "House", "<": "Motorcycle",
        "=": "Railroad", ">": "Car", "?": "Server",
        "@": "Tropical / hurricane", "A": "Aid station",
        "B": "BBS", "C": "Canoe", "E": "Eyeball", "F": "Farm vehicle",
        "H": "Hotel", "I": "TCP/IP", "J": "Jet", "K": "School",
        "L": "PC user", "M": "Mac", "N": "NTS station",
        "O": "Balloon", "P": "Police", "R": "RV", "S": "Shuttle",
        "T": "SSTV", "U": "Bus", "V": "ATV", "W": "Weather service",
        "X": "Helicopter", "Y": "Yacht", "Z": "WinLink user",
        "[": "Runner", "]": "Mail / PO",
        "^": "Aircraft", "_": "Weather station", "`": "Dish antenna",
        "a": "Ambulance", "b": "Bicycle", "c": "Incident CP",
        "d": "Fire dept", "e": "Horse", "f": "Fire truck",
        "g": "Glider", "h": "Hospital", "i": "IOTA",
        "j": "Jeep", "k": "Truck", "l": "Laptop", "n": "Node",
        "o": "EOC", "p": "Rover", "r": "Antenna", "s": "Ship",
        "u": "Truck (semi)", "v": "Van", "w": "Water station",
        "x": "xAPRS", "y": "Yagi", "z": "Shelter",
    ]
}
