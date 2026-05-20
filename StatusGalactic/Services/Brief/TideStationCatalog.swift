import Foundation

/// A NOAA CO-OPS tide station. `id` is the 7-character station code used in
/// requests to api.tidesandcurrents.noaa.gov.
struct TideStation: Hashable {
    let id: String
    let name: String
    let lat: Double
    let lng: Double
}

/// Curated catalog of major US coastal tide stations. Embedded so we don't
/// hit the metadata API on every brief; major stations change rarely. Add
/// new entries by looking up the 7-digit station ID at tidesandcurrents.noaa.gov.
enum TideStationCatalog {
    static let all: [TideStation] = [
        // East Coast
        .init(id: "8410140", name: "Eastport, ME",            lat: 44.9043, lng: -66.9853),
        .init(id: "8418150", name: "Portland, ME",            lat: 43.6567, lng: -70.2467),
        .init(id: "8423898", name: "Fort Point, NH",          lat: 43.0717, lng: -70.7100),
        .init(id: "8443970", name: "Boston, MA",              lat: 42.3539, lng: -71.0503),
        .init(id: "8447930", name: "Woods Hole, MA",          lat: 41.5236, lng: -70.6711),
        .init(id: "8454000", name: "Providence, RI",          lat: 41.8067, lng: -71.4006),
        .init(id: "8461490", name: "New London, CT",          lat: 41.3550, lng: -72.0875),
        .init(id: "8516945", name: "Kings Point, NY",         lat: 40.8104, lng: -73.7649),
        .init(id: "8518750", name: "The Battery, NY",         lat: 40.7006, lng: -74.0142),
        .init(id: "8531680", name: "Sandy Hook, NJ",          lat: 40.4669, lng: -74.0094),
        .init(id: "8534720", name: "Atlantic City, NJ",       lat: 39.3550, lng: -74.4180),
        .init(id: "8557380", name: "Lewes, DE",               lat: 38.7822, lng: -75.1190),
        .init(id: "8574680", name: "Baltimore, MD",           lat: 39.2667, lng: -76.5783),
        .init(id: "8638610", name: "Sewells Point, VA",       lat: 36.9467, lng: -76.3300),
        .init(id: "8651370", name: "Duck, NC",                lat: 36.1833, lng: -75.7467),
        .init(id: "8658120", name: "Wilmington, NC",          lat: 34.2275, lng: -77.9536),
        .init(id: "8665530", name: "Charleston, SC",          lat: 32.7811, lng: -79.9250),
        .init(id: "8670870", name: "Fort Pulaski, GA",        lat: 32.0345, lng: -80.9020),
        .init(id: "8720218", name: "Mayport, FL",             lat: 30.3967, lng: -81.4283),
        .init(id: "8721604", name: "Port Canaveral, FL",      lat: 28.4150, lng: -80.5933),
        .init(id: "8722670", name: "Lake Worth Pier, FL",     lat: 26.6128, lng: -80.0344),
        .init(id: "8723214", name: "Virginia Key, FL",        lat: 25.7314, lng: -80.1620),
        .init(id: "8724580", name: "Key West, FL",            lat: 24.5550, lng: -81.8083),
        .init(id: "8725110", name: "Naples, FL",              lat: 26.1317, lng: -81.8075),

        // Gulf
        .init(id: "8726520", name: "St. Petersburg, FL",      lat: 27.7611, lng: -82.6267),
        .init(id: "8729108", name: "Panama City, FL",         lat: 30.1521, lng: -85.6669),
        .init(id: "8729840", name: "Pensacola, FL",           lat: 30.4044, lng: -87.2113),
        .init(id: "8735180", name: "Dauphin Island, AL",      lat: 30.2502, lng: -88.0750),
        .init(id: "8747437", name: "Bay Waveland Yacht Club, MS", lat: 30.3258, lng: -89.3258),
        .init(id: "8761724", name: "Grand Isle, LA",          lat: 29.2633, lng: -89.9567),
        .init(id: "8770570", name: "Sabine Pass North, TX",   lat: 29.7283, lng: -93.8700),
        .init(id: "8771450", name: "Galveston Pier 21, TX",   lat: 29.3100, lng: -94.7933),
        .init(id: "8775870", name: "Corpus Christi, TX",      lat: 27.5800, lng: -97.2167),
        .init(id: "8779770", name: "Port Isabel, TX",         lat: 26.0617, lng: -97.2153),

        // West Coast
        .init(id: "9410170", name: "San Diego, CA",           lat: 32.7142, lng: -117.1736),
        .init(id: "9410660", name: "Los Angeles, CA",         lat: 33.7200, lng: -118.2700),
        .init(id: "9414290", name: "San Francisco, CA",       lat: 37.8067, lng: -122.4650),
        .init(id: "9418767", name: "Crescent City, CA",       lat: 41.7456, lng: -124.1844),
        .init(id: "9431647", name: "Port Orford, OR",         lat: 42.7383, lng: -124.4983),
        .init(id: "9432780", name: "Charleston, OR",          lat: 43.3450, lng: -124.3219),
        .init(id: "9435380", name: "South Beach, OR",         lat: 44.6253, lng: -124.0436),
        .init(id: "9447130", name: "Seattle, WA",             lat: 47.6022, lng: -122.3393),

        // Alaska
        .init(id: "9452210", name: "Juneau, AK",              lat: 58.2986, lng: -134.4123),
        .init(id: "9455090", name: "Seward, AK",              lat: 60.1203, lng: -149.4267),
        .init(id: "9455760", name: "Nikiski, AK",             lat: 60.6833, lng: -151.4000),
        .init(id: "9457804", name: "Anchorage, AK",           lat: 61.2386, lng: -149.8900),

        // Hawaii
        .init(id: "1612340", name: "Honolulu, HI",            lat: 21.3067, lng: -157.8670),
        .init(id: "1617760", name: "Hilo, HI",                lat: 19.7300, lng: -155.0600),
        .init(id: "1611400", name: "Nawiliwili, Kauai, HI",   lat: 21.9544, lng: -159.3561),

        // Great Lakes (water-level stations, treated like tide stations
        // for the purposes of "is the water rising or falling now?")
        .init(id: "9087031", name: "Holland, MI – L. Michigan", lat: 42.7733, lng: -86.2100),
        .init(id: "9087044", name: "Calumet Harbor, IL",      lat: 41.7300, lng: -87.5383),
        .init(id: "9075014", name: "Sebewaing, MI – Saginaw Bay", lat: 43.7167, lng: -83.4500),
    ]

    /// Nearest station to a coordinate, plus the great-circle distance in km.
    /// Returns nil if the catalog is empty or no station lies within
    /// `maxDistanceKm`.
    static func nearest(
        toLat lat: Double,
        lng: Double,
        maxDistanceKm: Double = 300
    ) -> (TideStation, Double)? {
        var best: (TideStation, Double)?
        for station in all {
            let d = haversineKm(lat1: lat, lng1: lng, lat2: station.lat, lng2: station.lng)
            if d <= maxDistanceKm, d < (best?.1 ?? .infinity) {
                best = (station, d)
            }
        }
        return best
    }
}
