import XCTest
@testable import StatusGalactic

final class TideStationCatalogTests: XCTestCase {

    /// Key West (24.55N, -81.78W) should match the Key West tide station to
    /// within a few km.
    func testKeyWestMatchesItself() throws {
        let result = TideStationCatalog.nearest(toLat: 24.55, lng: -81.78)
        let pair = try XCTUnwrap(result)
        XCTAssertEqual(pair.0.id, "8724580")
        XCTAssertLessThan(pair.1, 10) // within 10 km of itself
    }

    /// La Crosse, WI is inland; no tide station should be within 300 km.
    func testInlandPointReturnsNil() {
        XCTAssertNil(TideStationCatalog.nearest(toLat: 43.80, lng: -91.20))
    }

    /// Around San Francisco the nearest station should be SF (9414290),
    /// closer than Crescent City or San Diego.
    func testSanFranciscoMatchesSFStation() throws {
        let result = TideStationCatalog.nearest(toLat: 37.77, lng: -122.42)
        let pair = try XCTUnwrap(result)
        XCTAssertEqual(pair.0.id, "9414290")
    }
}
