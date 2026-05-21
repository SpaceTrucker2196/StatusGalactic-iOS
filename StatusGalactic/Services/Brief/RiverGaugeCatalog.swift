import Foundation

/// A NOAA NWPS river gauge identifier + coordinates. The 7-character `lid`
/// (NWS Location ID) is what `/v1/gauges/{lid}` accepts.
struct RiverGaugeStation: Hashable {
    let lid: String
    let name: String
    let lat: Double
    let lng: Double
}

/// Curated catalog of major US river gauges along the Mississippi, Missouri,
/// Ohio, Tennessee, and other heavily-populated waterways. Embedded so we
/// don't have to scan the 12,000-entry national listing on every brief.
/// The NWPS bbox endpoint silently returns empty results for any spatial
/// query I could find, so this lookup table is the reliable path.
enum RiverGaugeCatalog {
    static let all: [RiverGaugeStation] = [
        // Mississippi River, headwaters to mouth
        .init(lid: "STPM5", name: "Mississippi at St. Paul, MN",          lat: 44.945, lng: -93.087),
        .init(lid: "HSTM5", name: "Mississippi at Hastings, MN",          lat: 44.747, lng: -92.852),
        .init(lid: "REDM5", name: "Mississippi at Red Wing, MN",          lat: 44.566, lng: -92.534),
        .init(lid: "WBLM5", name: "Mississippi at Wabasha, MN",           lat: 44.380, lng: -92.038),
        .init(lid: "WNAM5", name: "Mississippi at Winona, MN",            lat: 44.057, lng: -91.642),
        .init(lid: "ALMW3", name: "Mississippi below L&D 4, Alma, WI",    lat: 44.324, lng: -91.919),
        .init(lid: "LCRM5", name: "Mississippi at La Crescent, MN",       lat: 43.823, lng: -91.298),
        .init(lid: "LANI4", name: "Mississippi at Lansing, IA",           lat: 43.367, lng: -91.215),
        .init(lid: "MCGI4", name: "Mississippi at McGregor, IA",          lat: 43.014, lng: -91.179),
        .init(lid: "PDCW3", name: "Mississippi at Prairie du Chien, WI",  lat: 43.052, lng: -91.142),
        .init(lid: "DBQI4", name: "Mississippi at Dubuque, IA",           lat: 42.499, lng: -90.659),
        .init(lid: "CLNI4", name: "Mississippi at Clinton, IA",           lat: 41.788, lng: -90.252),
        .init(lid: "LECI4", name: "Mississippi at LeClaire, IA",          lat: 41.595, lng: -90.348),
        .init(lid: "DAVI4", name: "Mississippi at Davenport, IA",         lat: 41.510, lng: -90.582),
        .init(lid: "MULI4", name: "Mississippi at Muscatine, IA",         lat: 41.418, lng: -91.038),
        .init(lid: "BRTI4", name: "Mississippi at Burlington, IA",        lat: 40.808, lng: -91.097),
        .init(lid: "KEOI4", name: "Mississippi at Keokuk, IA",            lat: 40.394, lng: -91.382),
        .init(lid: "HANM7", name: "Mississippi at Hannibal, MO",          lat: 39.706, lng: -91.358),
        .init(lid: "LOUM7", name: "Mississippi at Louisiana, MO",         lat: 39.448, lng: -91.058),
        .init(lid: "EADM7", name: "Mississippi at St. Louis, MO",         lat: 38.629, lng: -90.184),
        .init(lid: "CMGM7", name: "Mississippi at Cape Girardeau, MO",    lat: 37.305, lng: -89.518),
        .init(lid: "CIRI2", name: "Mississippi at Cairo, IL",             lat: 37.005, lng: -89.176),
        .init(lid: "MGTM5", name: "Mississippi at Memphis, TN",           lat: 35.149, lng: -90.063),
        .init(lid: "VKBM6", name: "Mississippi at Vicksburg, MS",         lat: 32.315, lng: -90.911),
        .init(lid: "NATM6", name: "Mississippi at Natchez, MS",           lat: 31.561, lng: -91.408),
        .init(lid: "BTRL1", name: "Mississippi at Baton Rouge, LA",       lat: 30.456, lng: -91.196),
        .init(lid: "NORL1", name: "Mississippi at New Orleans, LA",       lat: 29.948, lng: -90.063),

        // Missouri River
        .init(lid: "SUXI4", name: "Missouri at Sioux City, IA",           lat: 42.498, lng: -96.412),
        .init(lid: "OMHN1", name: "Missouri at Omaha, NE",                lat: 41.260, lng: -95.928),
        .init(lid: "STJM7", name: "Missouri at St. Joseph, MO",           lat: 39.768, lng: -94.852),
        .init(lid: "MKCM7", name: "Missouri at Kansas City, MO",          lat: 39.099, lng: -94.585),
        .init(lid: "JEFM7", name: "Missouri at Jefferson City, MO",       lat: 38.572, lng: -92.183),
        .init(lid: "HMNM7", name: "Missouri at Hermann, MO",              lat: 38.704, lng: -91.434),

        // Ohio River
        .init(lid: "PITM2", name: "Ohio at Pittsburgh, PA",               lat: 40.441, lng: -80.011),
        .init(lid: "CCNO1", name: "Ohio at Cincinnati, OH",               lat: 39.097, lng: -84.510),
        .init(lid: "LSVK2", name: "Ohio at Louisville, KY",               lat: 38.270, lng: -85.769),
        .init(lid: "PADK2", name: "Ohio at Paducah, KY",                  lat: 37.082, lng: -88.601),

        // Tennessee + others
        .init(lid: "CHAT1", name: "Tennessee at Chattanooga, TN",         lat: 35.046, lng: -85.310),
        .init(lid: "KNXT1", name: "Tennessee at Knoxville, TN",           lat: 35.961, lng: -83.921),
        .init(lid: "NSVT1", name: "Cumberland at Nashville, TN",          lat: 36.169, lng: -86.789),
        .init(lid: "MEMT1", name: "Wolf River at Memphis, TN",            lat: 35.149, lng: -90.060),

        // Pacific / Western
        .init(lid: "PRTO3", name: "Columbia at Portland, OR",             lat: 45.520, lng: -122.673),
        .init(lid: "SACC1", name: "Sacramento at Sacramento, CA",         lat: 38.581, lng: -121.494),
    ]

    /// Nearest gauge to a coordinate, plus distance in km.
    /// Returns nil if no gauge is within `maxDistanceKm`.
    static func nearest(
        toLat lat: Double,
        lng: Double,
        maxDistanceKm: Double = 200
    ) -> (RiverGaugeStation, Double)? {
        var best: (RiverGaugeStation, Double)?
        for s in all {
            let d = haversineKm(lat1: lat, lng1: lng, lat2: s.lat, lng2: s.lng)
            if d <= maxDistanceKm, d < (best?.1 ?? .infinity) {
                best = (s, d)
            }
        }
        return best
    }
}
