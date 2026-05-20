import Foundation

/// A single NWS marine forecast zone. `code` matches the bulletin file name
/// stem at `tgftp.nws.noaa.gov` (e.g. `GMZ033`).
struct MarineZone: Identifiable, Hashable {
    var id: String { code }
    let code: String
    let name: String
    let region: String
}

/// Curated catalog of frequently-referenced NWS marine zones. The full NWS
/// list runs into the hundreds; this set covers major US coastal areas where
/// the app's users are most likely to need a forecast. Users who know an
/// obscure zone can enter the code directly via the "Custom" row.
enum MarineZoneCatalog {

    static let all: [MarineZone] = [
        // MARK: Florida (Gulf side + Bay + Keys)
        .init(code: "GMZ031", name: "Tampa Bay waters",                              region: "Florida – Gulf"),
        .init(code: "GMZ033", name: "Bahia Honda Channel to East Cape Sable",         region: "Florida – Gulf"),
        .init(code: "GMZ035", name: "Florida Keys Marathon coast",                    region: "Florida – Gulf"),
        .init(code: "GMZ072", name: "Florida Bay",                                    region: "Florida – Gulf"),
        .init(code: "GMZ075", name: "Bonita Beach to Englewood out 20 NM",            region: "Florida – Gulf"),
        .init(code: "GMZ876", name: "Tortugas East offshore",                         region: "Florida – Gulf"),

        // MARK: Florida (Atlantic side)
        .init(code: "AMZ410", name: "Card Sound to Ocean Reef",                       region: "Florida – Atlantic"),
        .init(code: "AMZ430", name: "Hallandale Beach to Ocean Reef out 20 NM",       region: "Florida – Atlantic"),
        .init(code: "AMZ450", name: "Sebastian Inlet to Jupiter Inlet",               region: "Florida – Atlantic"),
        .init(code: "AMZ470", name: "Flagler Beach to Volusia / Brevard line",        region: "Florida – Atlantic"),
        .init(code: "AMZ555", name: "Coastal waters near Jacksonville",               region: "Florida – Atlantic"),

        // MARK: Carolinas / Georgia
        .init(code: "AMZ158", name: "Edisto Beach SC to Savannah GA",                 region: "Southeast Atlantic"),
        .init(code: "AMZ250", name: "Cape Fear to Surf City NC out 20 NM",            region: "Southeast Atlantic"),
        .init(code: "AMZ254", name: "Surf City to Cape Lookout NC",                   region: "Southeast Atlantic"),

        // MARK: Mid-Atlantic
        .init(code: "AMZ150", name: "Cape Charles Light VA to Currituck Beach",       region: "Mid-Atlantic"),
        .init(code: "AMZ650", name: "Sandy Hook NJ to Manasquan Inlet",               region: "Mid-Atlantic"),
        .init(code: "ANZ250", name: "Hudson Canyon to Atlantic City offshore",        region: "Mid-Atlantic"),
        .init(code: "ANZ350", name: "South of Block Island offshore",                 region: "Mid-Atlantic"),

        // MARK: New England
        .init(code: "ANZ230", name: "Coastal waters from Stonington ME to Merrimack", region: "New England"),
        .init(code: "ANZ234", name: "Massachusetts Bay & Stellwagen Bank",            region: "New England"),
        .init(code: "ANZ235", name: "Cape Cod Bay",                                   region: "New England"),

        // MARK: Texas
        .init(code: "GMZ150", name: "Brazos Santiago Pass to Port Mansfield",         region: "Texas Gulf"),
        .init(code: "GMZ230", name: "Port O'Connor to Mouth of the Rio Grande",       region: "Texas Gulf"),
        .init(code: "GMZ250", name: "Matagorda Bay",                                  region: "Texas Gulf"),
        .init(code: "GMZ255", name: "Port O'Connor to Matagorda Ship Channel",        region: "Texas Gulf"),
        .init(code: "GMZ335", name: "Galveston Bay",                                  region: "Texas Gulf"),

        // MARK: Louisiana / Mississippi / Alabama
        .init(code: "GMZ530", name: "Lake Pontchartrain & Maurepas",                  region: "Louisiana / Mississippi"),
        .init(code: "GMZ550", name: "Coastal waters out of Slidell",                  region: "Louisiana / Mississippi"),
        .init(code: "GMZ555", name: "New Orleans coastal waters",                     region: "Louisiana / Mississippi"),
        .init(code: "GMZ650", name: "Coastal Alabama – Mobile Bay",                   region: "Louisiana / Mississippi"),

        // MARK: California
        .init(code: "PZZ535", name: "Pt St George CA to Cape Blanco OR",              region: "California / Pacific NW"),
        .init(code: "PZZ540", name: "Cape Mendocino to Pt St George out 10 NM",       region: "California / Pacific NW"),
        .init(code: "PZZ750", name: "Pt Pinos to Pt Piedras Blancas",                 region: "California / Pacific NW"),
        .init(code: "PZZ775", name: "San Francisco Bay",                              region: "California / Pacific NW"),

        // MARK: Pacific Northwest
        .init(code: "PZZ153", name: "Cape Flattery to James Island WA",               region: "California / Pacific NW"),
        .init(code: "PZZ156", name: "James Island to Pt Grenville WA out 10 NM",      region: "California / Pacific NW"),

        // MARK: Great Lakes – Michigan / Erie / Superior / Ontario / Huron
        .init(code: "LMZ643", name: "Sturgeon Bay to South Haven MI",                 region: "Great Lakes"),
        .init(code: "LMZ646", name: "South Haven to Michigan City IN",                region: "Great Lakes"),
        .init(code: "LMZ673", name: "Northern Lake Michigan – Whitefish Bay",         region: "Great Lakes"),
        .init(code: "LHZ361", name: "Lake Huron from Port Huron to Saginaw Bay",      region: "Great Lakes"),
        .init(code: "LEZ142", name: "Lake Erie open lake – mid",                      region: "Great Lakes"),
        .init(code: "LOZ045", name: "Lake Ontario open lake",                         region: "Great Lakes"),
        .init(code: "LSZ162", name: "Lake Superior near Marquette",                   region: "Great Lakes"),

        // MARK: Hawaii
        .init(code: "PHZ110", name: "Coastal waters around Oahu",                     region: "Hawaii"),
        .init(code: "PHZ111", name: "Kaiwi Channel",                                  region: "Hawaii"),
        .init(code: "PHZ112", name: "Maui County windward waters",                    region: "Hawaii"),

        // MARK: Alaska
        .init(code: "PKZ170", name: "Cook Inlet North",                               region: "Alaska"),
        .init(code: "PKZ172", name: "Cook Inlet South",                               region: "Alaska"),
        .init(code: "PKZ214", name: "Resurrection Bay",                               region: "Alaska"),
        .init(code: "PKZ225", name: "Prince William Sound",                           region: "Alaska"),
    ]

    /// Region names in display order. We want a deterministic, geography-
    /// sensible ordering (south to north, east to west-ish), not alphabetical.
    static let orderedRegions: [String] = [
        "Florida – Gulf",
        "Florida – Atlantic",
        "Southeast Atlantic",
        "Mid-Atlantic",
        "New England",
        "Texas Gulf",
        "Louisiana / Mississippi",
        "California / Pacific NW",
        "Great Lakes",
        "Hawaii",
        "Alaska",
    ]

    static func zones(in region: String) -> [MarineZone] {
        all.filter { $0.region == region }
    }

    /// Look up the friendly name for a zone code, if known.
    static func name(forCode code: String) -> String? {
        let upper = code.uppercased()
        return all.first { $0.code == upper }?.name
    }
}
