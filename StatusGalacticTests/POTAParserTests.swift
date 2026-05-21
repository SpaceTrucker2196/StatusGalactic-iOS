import XCTest
@testable import StatusGalactic

final class POTAParserTests: XCTestCase {

    func testParsesTypicalSpot() {
        let raw: [String: Any] = [
            "spotId": 1234567,
            "activator": "W9ABC",
            "reference": "K-0012",
            "name": "Kettle Moraine State Forest",
            "frequency": 14060.0,
            "mode": "CW",
            "spotTime": "2026-05-21T18:30:00",
            "latitude": 43.5,
            "longitude": -88.4,
            "locationDesc": "US-WI",
            "comments": "QRT in 15"
        ]
        let spot = try? XCTUnwrap(POTAClient.parse(raw))
        XCTAssertEqual(spot?.activator, "W9ABC")
        XCTAssertEqual(spot?.parkRef, "K-0012")
        XCTAssertEqual(spot?.parkName, "Kettle Moraine State Forest")
        XCTAssertEqual(spot?.frequencyKHz, 14060.0)
        XCTAssertEqual(spot?.mode, "CW")
        XCTAssertEqual(spot?.latitude, 43.5)
        XCTAssertEqual(spot?.longitude, -88.4)
        XCTAssertEqual(spot?.locationDesc, "US-WI")
    }

    func testAcceptsStringFrequency() {
        let raw: [String: Any] = [
            "spotId": 1,
            "activator": "W9ABC",
            "reference": "K-1",
            "name": "P",
            "frequency": "7185",
            "mode": "SSB",
            "spotTime": "2026-05-21T18:30:00Z",
        ]
        let spot = try? XCTUnwrap(POTAClient.parse(raw))
        XCTAssertEqual(spot?.frequencyKHz, 7185)
    }

    func testReturnsNilWithoutRequiredFields() {
        XCTAssertNil(POTAClient.parse(["frequency": 14000]))
    }
}
